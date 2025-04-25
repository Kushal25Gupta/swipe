import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../../../core/theme/app_colors.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String filePath;
  final bool isMe;
  final String durationText;
  final Duration duration;
  
  const VoiceMessagePlayer({
    Key? key,
    required this.filePath,
    required this.isMe,
    required this.durationText,
    required this.duration,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> with SingleTickerProviderStateMixin {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isPlayerReady = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _initPlayer();
    
    // Initialize animation controller for waveform with faster animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Faster animation
    );
    
    // Set initial duration from props
    _duration = widget.duration;
  }
  
  Future<void> _initPlayer() async {
    await _player.openPlayer();
    setState(() {
      _isPlayerReady = true;
    });
    
    // Use the duration from widget props
    _duration = widget.duration;
    
    // Listen for playback progress with more frequent updates
    _player.setSubscriptionDuration(const Duration(milliseconds: 100)); // More frequent updates
    _player.onProgress?.listen((event) {
      if (mounted) {
        setState(() {
          _position = event.position;
          // Only update duration from player if it's valid and different from what we have
          if (event.duration.inMilliseconds > 0) {
            _duration = event.duration;
          }
        });
        
        // When playback finishes
        if (event.position >= event.duration) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
          _animationController.reset();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _stopPlayer();
    _player.closePlayer();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _playPause() async {
    if (!_isPlayerReady) return;
    
    try {
      if (_isPlaying) {
        await _stopPlayer();
        _animationController.stop();
      } else {
        await _player.startPlayer(
          fromURI: widget.filePath,
          whenFinished: () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _position = Duration.zero;
              });
              _animationController.reset();
            }
          }
        );
        setState(() {
          _isPlaying = true;
        });
        // Start continuous animation
        _animationController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing voice message: $e')),
        );
      }
      setState(() {
        _isPlaying = false;
      });
      _animationController.stop();
    }
  }
  
  Future<void> _stopPlayer() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage for the waveform
    final progress = _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;
    
    return Container(
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 250,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: widget.isMe ? Colors.white : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice Message',
                  style: TextStyle(
                    color: widget.isMe ? Colors.white : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _playPause,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isPlaying 
                      ? Colors.red.withOpacity(0.2) 
                      : Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: _isPlaying ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Waveform visualization with progress
          SizedBox(
            height: 40, // Taller for better visualization
            child: Row(
              children: [
                // Time indicator (current position)
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.white70,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                // Waveform animation with progress
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Background waveform
                          _buildWaveformVisualizer(
                            constraints.maxWidth,
                            isBackground: true,
                          ),
                          
                          // Progress overlay
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: _buildWaveformVisualizer(
                                constraints.maxWidth,
                                isBackground: false,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Duration indicator (total duration)
                Text(
                  // Use the original duration from metadata
                  widget.durationText,
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWaveformVisualizer(double totalWidth, {required bool isBackground}) {
    // Generate a more natural looking waveform
    const int barCount = 27; // Odd number for better centering
    
    // Create dynamic heights for a more natural waveform
    // Center bars are taller than edges
    List<double> heights = List.generate(barCount, (index) {
      // Calculate position from center (0.0 to 1.0)
      final distanceFromCenter = (index - (barCount ~/ 2)).abs() / (barCount ~/ 2);
      
      // Height decreases from center to edges, minimum 0.2
      return 0.2 + (1.0 - distanceFromCenter) * 0.8;
    });
    
    return SizedBox(
      width: totalWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          barCount,
          (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // Only animate active bars when playing
                double animationFactor = 1.0;
                if (_isPlaying && !isBackground) {
                  // Vary animation based on position and animation value
                  final baseVariation = _animationController.value * 0.3;
                  final positionVariation = (index % 4) * 0.05;
                  animationFactor = 0.7 + baseVariation + positionVariation;
                }
                
                return _buildWaveformBar(
                  baseHeight: heights[index] * 30, // Scale to desired max height
                  animationFactor: animationFactor,
                  isActive: !isBackground,
                  barWidth: totalWidth / (barCount * 2), // Account for spacing
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildWaveformBar({
    required double baseHeight, 
    required double animationFactor,
    required bool isActive,
    required double barWidth,
  }) {
    final double height = baseHeight * animationFactor;
    
    return Container(
      width: barWidth,
      height: height,
      decoration: BoxDecoration(
        color: isActive 
          ? (widget.isMe ? Colors.white : Colors.white) 
          : (widget.isMe ? Colors.white38 : Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String? type;
  final Map<String, dynamic>? metadata;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.type,
    this.metadata,
  });

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final messageType = type ?? 'text';
    
    return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 80 : 16,
          right: isMe ? 16 : 80,
          bottom: 8,
        ),
        padding: _getPadding(messageType),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content based on type
            _buildMessageContent(context, messageType),
            
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  EdgeInsets _getPadding(String messageType) {
    if (messageType == 'text') {
      return const EdgeInsets.fromLTRB(12, 8, 12, 6);
    } else if (messageType == 'image') {
      return const EdgeInsets.all(8);
    } else {
      return const EdgeInsets.all(10);
    }
  }

  Widget _buildMessageContent(BuildContext context, String messageType) {
    switch (messageType) {
      case 'image':
        return _buildImageContent(context);
      case 'audio':
        return _buildAudioContent(context);
      case 'voice':
        return _buildVoiceContent(context);
      case 'location':
        return _buildLocationContent(context);
      case 'contact':
        return _buildContactContent(context);
      case 'document':
        return _buildDocumentContent(context);
      case 'text':
      default:
        return _buildTextContent(context);
    }
  }

  Widget _buildTextContent(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Text(
        message,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    String? imagePath;
    try {
      // Safely access the path from metadata
      imagePath = metadata?['path']?.toString();
    } catch (e) {
      print('Error getting image path from metadata: $e');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // Show full image only if path exists
            if (imagePath != null && imagePath.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      _getImageWidget(imagePath, boxFit: BoxFit.contain),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 200,
              height: 200,
              child: _getImageWidget(imagePath),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (message != 'Photo' && message != 'Image')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _getImageWidget(String? imagePath, {BoxFit boxFit = BoxFit.cover}) {
    if (imagePath == null) {
      return const Icon(Icons.image_not_supported, color: Colors.white54);
    }
    
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: boxFit,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.broken_image_rounded,
          color: Colors.white54,
          size: 50,
        ),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: boxFit,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image_rounded,
          color: Colors.white54,
          size: 50,
        ),
      );
    }
  }

  Widget _buildAudioContent(BuildContext context) {
    return _buildMediaContent(
      context,
      Icons.headphones,
      metadata?['name'] ?? 'Audio',
      'audio file',
    );
  }

  Widget _buildVoiceContent(BuildContext context) {
    // Get duration from metadata with zero as fallback
    final duration = metadata?['duration'] ?? 0;
    
    // Convert milliseconds to proper minutes:seconds format
    // Make sure to handle very short durations correctly
    final seconds = duration ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final durationText = '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    
    // Debug print to check what's being passed
    print('Voice message duration: $duration ms, formatted as: $durationText');
    
    final filePath = metadata?['path'];
    
    if (filePath == null) {
      return Container(
        constraints: const BoxConstraints(
          minWidth: 150,
          maxWidth: 200,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_off,
              color: isMe ? Colors.white : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Message',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'File unavailable',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return VoiceMessagePlayer(
      filePath: filePath,
      isMe: isMe,
      durationText: durationText,
      duration: Duration(milliseconds: duration),
    );
  }

  Widget _buildLocationContent(BuildContext context) {
    final latitude = metadata?['latitude'];
    final longitude = metadata?['longitude'];
    
    return GestureDetector(
      onTap: () async {
        if (latitude != null && longitude != null) {
          // Try to open Google Maps app first
          final googleMapsUrl = Platform.isIOS
              ? 'comgooglemaps://?q=$latitude,$longitude&zoom=16'
              : 'geo:$latitude,$longitude?q=$latitude,$longitude&z=16';
              
          if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
            await launchUrl(Uri.parse(googleMapsUrl));
          } else {
            // Fallback to web URL if app isn't installed
            final webUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
            await launchUrl(
              Uri.parse(webUrl),
              mode: LaunchMode.externalApplication,
            );
          }
        } else {
          // Show error if coordinates are missing
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location coordinates not available'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.map,
                  color: Colors.white30,
                  size: 60,
                ),
                const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Open in Maps',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (latitude != null && longitude != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                message != 'Location' && message.isNotEmpty ? message : 'Shared Location',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactContent(BuildContext context) {
    final name = metadata?['name'] ?? 'Unknown Contact';
    final phoneNumber = metadata?['phoneNumber'];
    final email = metadata?['email'];
    
    return GestureDetector(
      onTap: () async {
        if (phoneNumber != null) {
          final url = 'tel:$phoneNumber';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        }
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 180,
          maxWidth: 220,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phoneNumber != null)
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (email != null)
                    Text(
                      email,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContent(BuildContext context) {
    final documentName = metadata?['name'] ?? 'Document';
    final documentSize = metadata?['size'] ?? 0;
    final extension = metadata?['extension'] ?? '';
    
    String sizeText = 'Unknown size';
    if (documentSize is int && documentSize > 0) {
      if (documentSize < 1024 * 1024) {
        sizeText = '${(documentSize / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeText = '${(documentSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }
    
    return _buildMediaContent(
      context,
      _getDocumentIcon(extension),
      documentName,
      sizeText,
    );
  }
  
  Widget _buildMediaContent(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return GestureDetector(
      onTap: () async {
        final path = metadata?['path'];
        if (path != null) {
          try {
            final result = await OpenFilex.open(path);
            if (result.type != ResultType.done) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open file: ${result.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error opening file: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () async {
                  Navigator.pop(context);
                  final path = metadata?['path'];
                  if (path != null) {
                    await Share.shareXFiles([XFile(path)]);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Save to Downloads'),
                onTap: () async {
                  Navigator.pop(context);
                  final path = metadata?['path'];
                  if (path != null) {
                    final downloadsDir = await getExternalStorageDirectory();
                    if (downloadsDir != null) {
                      final fileName = path.split('/').last;
                      final destFile = File('${downloadsDir.path}/$fileName');
                      await File(path).copy(destFile.path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved to Downloads: ${destFile.path}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 180,
          maxWidth: 220,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getColorForIcon(icon).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: _getColorForIcon(icon),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getDocumentIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  Color _getColorForIcon(IconData icon) {
    if (icon == Icons.picture_as_pdf) {
      return Colors.red;
    } else if (icon == Icons.description) {
      return Colors.blue;
    } else if (icon == Icons.table_chart) {
      return Colors.green;
    } else if (icon == Icons.slideshow) {
      return Colors.orange;
    } else if (icon == Icons.headphones) {
      return Colors.purple;
    } else if (icon == Icons.mic) {
      return Colors.red;
    } else {
      return Colors.indigo;
    }
  }
} 