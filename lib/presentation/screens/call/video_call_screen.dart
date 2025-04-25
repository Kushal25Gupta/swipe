import 'package:flutter/material.dart';
import 'dart:async';

class VideoCallScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final bool isIncoming;

  const VideoCallScreen({
    Key? key,
    this.user,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;
  bool _isConnected = false;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Simulate call connection
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isConnected = true);
      }
    });

    // Simulate call duration
    const oneSec = Duration(seconds: 1);
    Timer.periodic(oneSec, (Timer timer) {
      if (mounted) {
        setState(() {
          _callDuration += oneSec;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getUserPhoto() {
    if (widget.user == null) return '';
    
    try {
      if (widget.user!['photoUrls'] is List) {
        final photoUrls = widget.user!['photoUrls'] as List;
        if (photoUrls.isNotEmpty && photoUrls.first is String) {
          return photoUrls.first as String;
        }
      }
      if (widget.user!['profilePicture'] is String) {
        return widget.user!['profilePicture'] as String;
      }
    } catch (e) {
      print('Error getting user photo: $e');
    }
    return '';
  }

  String _getUserName() {
    if (widget.user == null) return 'Unknown User';
    
    try {
      if (widget.user!['name'] is String) {
        return widget.user!['name'] as String;
      }
      if (widget.user!['username'] is String) {
        return widget.user!['username'] as String;
      }
    } catch (e) {
      print('Error getting user name: $e');
    }
    return 'Unknown User';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    final userPhoto = _getUserPhoto();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                    Colors.black,
                  ],
                ),
              ),
            ),
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top bar with user info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: userPhoto.isNotEmpty 
                                ? NetworkImage(userPhoto) 
                                : null,
                            child: userPhoto.isEmpty 
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isConnected ? 'Connected' : 'Connecting...',
                                style: TextStyle(
                                  color: _isConnected ? Colors.green : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Call duration
                      if (_isConnected)
                        Text(
                          _formatDuration(_callDuration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                // Video placeholder
                Expanded(
                  child: Center(
                    child: _isVideoOff
                        ? Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[800],
                            ),
                            child: Icon(
                              Icons.videocam_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                userPhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 300,
                                    height: 400,
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.person,
                                      size: 100,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ),
                // Control buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        onPressed: () {
                          setState(() => _isMuted = !_isMuted);
                        },
                        backgroundColor: _isMuted ? Colors.red : Colors.white24,
                      ),
                      _buildControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        onPressed: () {
                          setState(() => _isVideoOff = !_isVideoOff);
                        },
                        backgroundColor: _isVideoOff ? Colors.red : Colors.white24,
                      ),
                      _buildControlButton(
                        icon: Icons.call_end,
                        backgroundColor: Colors.red,
                        onPressed: () => Navigator.pop(context),
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        onPressed: () {
                          setState(() => _isSpeakerOn = !_isSpeakerOn);
                        },
                        backgroundColor: _isSpeakerOn ? Colors.blue : Colors.white24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white24,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        iconSize: 30,
        onPressed: onPressed,
      ),
    );
  }
} 