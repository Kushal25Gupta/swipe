import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

class VideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const VideoCallScreen({
    super.key,
    required this.user,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;

  @override
  Widget build(BuildContext context) {
    // Get image URL with fallbacks
    final String imageUrl = widget.user['photoUrls'] != null && 
                          widget.user['photoUrls'] is List && 
                          (widget.user['photoUrls'] as List).isNotEmpty
                        ? widget.user['photoUrls'][0]
                        : widget.user['profilePicture'] ?? '';
    
    // Get name with fallbacks
    final String userName = widget.user['name'] ?? 
                           widget.user['username'] ?? 
                           'Unknown User';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Remote video (currently showing user image as placeholder)
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.white30,
                  ),
                ),
              ),
            )
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.white30,
                ),
              ),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // UI Elements
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            userName,
                            style: TextStyles.headline6Dark.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '12:34',
                            style: TextStyles.captionDark.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.switch_camera_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // TODO: Implement camera switch
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Local video preview
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _isCameraOff
                          ? const Center(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white54,
                                size: 32,
                              ),
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Text(
                                  'Camera Preview',
                                  style: TextStyle(color: Colors.white54),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onPressed: () {
                          setState(() => _isMuted = !_isMuted);
                        },
                      ),
                      _buildControlButton(
                        icon: _isCameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        label: _isCameraOff ? 'Start Video' : 'Stop Video',
                        onPressed: () {
                          setState(() => _isCameraOff = !_isCameraOff);
                        },
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                        onPressed: () {
                          setState(() => _isSpeakerOn = !_isSpeakerOn);
                        },
                      ),
                      _buildControlButton(
                        icon: Icons.call_end_rounded,
                        backgroundColor: Colors.red,
                        label: 'End',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white24,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            iconSize: 28,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyles.captionDark.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
} 