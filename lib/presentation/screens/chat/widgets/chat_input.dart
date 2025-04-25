import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ChatInput extends StatefulWidget {
  final Function(String, {String? type, Map<String, dynamic>? metadata}) onSendMessage;
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.focusNode,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final _audioRecorder = FlutterSoundRecorder();
  String? _recordingPath;
  bool _isRecording = false;
  late FocusNode _focusNode;
  bool _isDisposed = false;
  bool _isRecorderInitialized = false;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      _isRecorderInitialized = true;
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null && !_isDisposed) {
      _focusNode.dispose();
    }
    _stopRecording();
    if (_isRecorderInitialized) {
      _audioRecorder.closeRecorder();
    }
    _isDisposed = true;
    super.dispose();
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // Special handling for contacts permission which sometimes needs both approaches
    if (permission == Permission.contacts) {
      // Check if we can request through flutter_contacts first
      final contactsPermissionGranted = await FlutterContacts.requestPermission();
      if (contactsPermissionGranted) {
        return true;
      }
    }
    
    final result = await permission.request();
    
    if (result.isPermanentlyDenied) {
      // Show dialog to open app settings
      if (mounted) {
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Permission Required'),
            content: Text('${permission.toString()} permission is required for this feature. Please enable it in app settings.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ?? false;
        
        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }
    
    return result.isGranted;
  }
  
  Future<Map<Permission, PermissionStatus>> _requestMultiplePermissions(List<Permission> permissions) async {
    final statuses = await permissions.request();
    
    // Check if any permissions were denied and show a message
    final denied = statuses.values.where((status) => !status.isGranted).toList();
    if (denied.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Some permissions were denied. Feature may not work correctly.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    return statuses;
  }
  
  String _getPermissionFriendlyName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.storage:
        return 'Storage';
      case Permission.photos:
        return 'Photos';
      case Permission.contacts:
        return 'Contacts';
      case Permission.location:
        return 'Location';
      case Permission.mediaLibrary:
        return 'Media Library';
      case Permission.manageExternalStorage:
        return 'Manage Files';
      default:
        return permission.toString().split('.').last;
    }
  }

  void _handleSendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message, type: 'text');
      _controller.clear();
      if (!_isDisposed) {
        setState(() {});
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      await _requestPermission(Permission.camera);
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null && !_isDisposed && mounted) {
        final metadata = {
          'path': photo.path,
          'name': photo.name,
          'size': await File(photo.path).length(),
          'mimeType': 'image/${photo.path.split('.').last}',
        };
        
        widget.onSendMessage(
          'Photo',
          type: 'image',
          metadata: metadata,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // On Android 13+, we need to request more specific permissions
      if (Platform.isAndroid) {
        // Request photos permission
        await _requestPermission(Permission.photos);
        // Also request media storage permission
        await _requestPermission(Permission.mediaLibrary);
      } else {
        // On other platforms, just request storage
        await _requestPermission(Permission.storage);
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null && !_isDisposed && mounted) {
        final metadata = {
          'path': image.path,
          'name': image.name,
          'size': await File(image.path).length(),
          'mimeType': 'image/${image.path.split('.').last}',
        };
        
        widget.onSendMessage(
          'Image',
          type: 'image',
          metadata: metadata,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAudio() async {
    try {
      await _requestPermission(Permission.storage);
      
      const XTypeGroup audioGroup = XTypeGroup(
        label: 'Audio',
        extensions: ['mp3', 'wav', 'aac', 'm4a'],
      );
      
      final XFile? file = await openFile(
        acceptedTypeGroups: [audioGroup],
      );
      
      if (file != null && !_isDisposed && mounted) {
        final path = file.path;
        final fileStat = await File(path).stat();
        
        final metadata = {
          'path': path,
          'name': file.name,
          'size': fileStat.size,
          'mimeType': 'audio/${path.split('.').last}',
        };
        
        widget.onSendMessage(
          'Audio',
          type: 'audio',
          metadata: metadata,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareLocation() async {
    try {
      await _requestPermission(Permission.location);
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (!_isDisposed && mounted) {
        final metadata = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'altitude': position.altitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp?.millisecondsSinceEpoch,
        };
        
        widget.onSendMessage(
          'Location',
          type: 'location',
          metadata: metadata,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location shared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickContact() async {
    // First check permission using permission_handler
    final permissionStatus = await Permission.contacts.status;
    
    if (!permissionStatus.isGranted) {
      // Attempt to request permission through both methods
      final granted = await _requestPermission(Permission.contacts);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact permission denied.')),
          );
        }
        return;
      }
    }
    
    try {
      // Use the correct method for flutter_contacts 1.1.7+1
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        // If contact has phones, use the first one
        if (contact.phones.isNotEmpty) {
          final phone = contact.phones.first.number;
          _controller.text = phone;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selected contact has no phone number')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing contacts: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      // Check if we're on Android 13+ which requires specific permissions
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use null-safe access for SDK version
        final sdkVersion = androidInfo.version.sdkInt ?? 0;
        
        // Android 13 is SDK 33+
        if (sdkVersion >= 33) {
          // For Android 13+, we need to request specific media permissions
          final permissions = <Permission>[
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ];
          
          final statuses = await _requestMultiplePermissions(permissions);
          final allGranted = statuses.values.every((status) => status.isGranted);
          
          if (!allGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Media permissions required to attach files')),
              );
            }
            return;
          }
        } else {
          // For older Android versions, storage permission is still needed
          final granted = await _requestPermission(Permission.storage);
          if (!granted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission denied')),
              );
            }
            return;
          }
        }
      }
      
      // Now that permissions are handled, let's pick the document
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'documents',
        extensions: <String>['jpg', 'pdf', 'doc', 'docx'],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      
      if (file != null) {
        final metadata = {
          'path': file.path,
          'name': file.name,
          'size': await File(file.path).length(),
          'extension': file.path.split('.').last,
          'mimeType': 'application/${file.path.split('.').last}',
        };
        
        widget.onSendMessage(
          'Document: ${file.name}',
          type: 'document',
          metadata: metadata,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking document: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      await _requestPermission(Permission.microphone);
      
      if (!_isRecorderInitialized) {
        await _initRecorder();
      }
      
      final directory = await getTemporaryDirectory();
      final uuid = const Uuid().v4();
      _recordingPath = '${directory.path}/$uuid.aac';
      
      await _audioRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
      
      if (!_isDisposed) {
        setState(() {
          _isRecording = true;
        });
      }
      
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started...'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording && _isRecorderInitialized) {
        // Track recording duration before stopping
        int durationMs = 0;
        
        // Stop the recorder and get the file path
        final recordingFile = await _audioRecorder.stopRecorder();
        
        if (!_isDisposed) {
          setState(() {
            _isRecording = false;
          });
        }
        
        if (recordingFile != null && !_isDisposed && mounted) {
          final file = File(recordingFile);
          if (await file.exists()) {
            // Get the actual recording duration from the file size
            try {
              // Calculate based on file size - AAC typically uses ~16KB per second of audio
              final fileSize = await file.length();
              durationMs = (fileSize ~/ 16000) * 1000; // Convert KB to ms at 16KB/sec rate
              
              // Ensure we have a reasonable value (at least 1 second, at most 5 minutes)
              durationMs = durationMs.clamp(1000, 300000);
            } catch (e) {
              // Fallback to a 3-second clip if we can't determine length
              durationMs = 3000;
              print('Error determining voice message duration: $e');
            }
            
            print('Voice recording actual duration: $durationMs ms');
            
            final metadata = {
              'path': recordingFile,
              'name': 'Voice Recording',
              'size': await file.length(),
              'duration': durationMs,
              'mimeType': 'audio/aac',
            };
            
            widget.onSendMessage(
              'Voice Message',
              type: 'voice',
              metadata: metadata,
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice message sent'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.headphones_rounded,
                    label: 'Audio',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAudio();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _shareLocation();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.person_rounded,
                    label: 'Contact',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickContact();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white70,
                  size: 24,
                ),
                onPressed: _showAttachmentOptions,
                padding: EdgeInsets.zero,
                splashRadius: 24,
              ),
            ),

            Expanded(
              child: Container(
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      if (!_isDisposed) {
                        setState(() {});
                      }
                    },
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        widget.onSendMessage(text, type: 'text');
                        _controller.clear();
                      }
                    },
                  ),
                ),
              ),
            ),

            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: Icon(
                  _isRecording
                    ? Icons.stop_rounded
                    : (_controller.text.isEmpty ? Icons.mic : Icons.send_rounded),
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _isRecording
                    ? _stopRecording
                    : (_controller.text.isEmpty ? _startRecording : _handleSendMessage),
                padding: EdgeInsets.zero,
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 