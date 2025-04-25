import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

class AudioCallScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AudioCallScreen({
    super.key,
    required this.user,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  bool _isMuted = false;
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
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with minimize button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Profile image and info
            Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white54,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white54,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  userName,
                  style: TextStyles.headline5Dark.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voice calling...',
                  style: TextStyles.bodyText2Dark.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '00:00',
                  style: TextStyles.headline6Dark.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Call controls
            Padding(
              padding: const EdgeInsets.all(32),
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
                    icon: Icons.call_end_rounded,
                    backgroundColor: Colors.red,
                    size: 72,
                    iconSize: 32,
                    onPressed: () => Navigator.pop(context),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    double size = 56,
    double iconSize = 28,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white24,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            iconSize: iconSize,
            onPressed: onPressed,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyles.captionDark.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }
} 