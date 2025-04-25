import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';
import 'screens/video_call_screen.dart';
import 'screens/audio_call_screen.dart';
import '../../screens/profile/view_profile_screen.dart';
import '../../../data/services/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _firebaseService = FirebaseService();
  final _scrollController = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  Map<String, dynamic>? _otherUserData;
  bool _isLoading = true;
  bool _isKeyboardVisible = false;
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOtherUserData();
    _loadMessages();
    
    // Add listener for keyboard visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        if (_scrollController.position.atEdge) {
          if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
            // At bottom, do nothing
          } else {
            // At top, could implement load more messages here
          }
        }
      });

      // Request focus after build
      if (!_isDisposed && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_isDisposed && _focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!_isDisposed && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    if (!_isDisposed) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    _messagesSubscription?.cancel();
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = bottomInset > 0;
    });
    
    if (_isKeyboardVisible && _messages.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _loadOtherUserData() async {
    try {
      final userData = await _firebaseService.getUserData(widget.otherUserId);
      if (mounted) {
        setState(() {
          _otherUserData = userData;
          if (!_messages.isEmpty) _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading other user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load user data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _firebaseService.getMessages(widget.matchId).listen((messages) {
      if (!mounted) return;
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages.map((data) {
          print('Received message: ${data['text']} from ${data['senderId']}, type: ${data['type']}');
          return {
            'id': data['id'],
            'text': data['text'],
            'isMe': data['senderId'] == _firebaseService.currentUser?.uid,
            'timestamp': DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
            'type': data['type'] ?? 'text',
            'metadata': data['metadata'] ?? {},
          };
        }));
        _isLoading = false;
      });

      // Scroll to bottom with a slight delay to ensure the list is built
      if (_messages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }, onError: (error) {
      print('Error loading messages: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _handleSendMessage(
    String message, {
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    if (message.trim().isEmpty && type == null) return;
    if (type == 'text' && message.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message is too long (max 1000 characters)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Sending message: $message, type: ${type ?? 'text'}, metadata: $metadata');
      
      // For text messages, use the existing sendMessage method
      if (type == null || type == 'text') {
        await _firebaseService.sendMessage(
          widget.matchId,
          message,
          _firebaseService.currentUser!.uid,
        );
        return;
      }
      
      // For other message types, we'll need to handle them differently
      // Here we're creating a more complex message structure
      final messageData = {
        'text': message,
        'senderId': _firebaseService.currentUser!.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': type, // image, audio, location, etc.
        'metadata': metadata ?? {},
      };
      
      await _firebaseService.sendCustomMessage(
        widget.matchId,
        messageData,
      );
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _otherUserData == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Clear focus when going back
        _focusNode.unfocus();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1C1E),
          elevation: 0,
          leadingWidth: 40,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              _focusNode.unfocus();
              Navigator.pop(context);
            },
            padding: EdgeInsets.zero,
            splashRadius: 24,
          ),
          titleSpacing: 0,
          title: GestureDetector(
            onTap: () {
              if (_otherUserData == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User profile not available'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Create a profile object with the minimum required fields
              // Handle all possible data structures to avoid type errors
              List<String> imagesList = [];
              
              // Try to extract images from different possible sources
              try {
                if (_otherUserData!['photoUrls'] != null) {
                  if (_otherUserData!['photoUrls'] is List) {
                    // If it's already a list, use it
                    imagesList = List<String>.from((_otherUserData!['photoUrls'] as List)
                        .where((item) => item != null)
                        .map((item) => item.toString()));
                  } else if (_otherUserData!['photoUrls'] is String) {
                    // If it's a string, make it a single-item list
                    imagesList.add(_otherUserData!['photoUrls'] as String);
                  }
                }
                
                // If still empty, try profile picture
                if (imagesList.isEmpty && _otherUserData!['profilePicture'] != null) {
                  if (_otherUserData!['profilePicture'] is String) {
                    imagesList.add(_otherUserData!['profilePicture'] as String);
                  }
                }
                
                // If still empty, use placeholder
                if (imagesList.isEmpty) {
                  imagesList.add('https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp');
                }
              } catch (e) {
                // Fallback in case of any errors
                imagesList = ['https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp'];
                print('Error parsing profile images: $e');
              }
              
              final profileData = {
                ..._otherUserData!,
                'images': imagesList,
                'name': _getUserFullName(),
                'age': _otherUserData!['age'] ?? 25,
                'distance': _getLocationOrDistance(),
                'bio': _otherUserData!['bio'] ?? 'No bio available',
                // Add any other required fields with sensible defaults
                'verified': _otherUserData!['verified'] ?? false,
                'interests': _otherUserData!['interests'] is List 
                    ? _otherUserData!['interests'] 
                    : ['Chat', 'Connection'],
                'lookingFor': _otherUserData!['lookingFor'] is List 
                    ? _otherUserData!['lookingFor'] 
                    : ['Friendship'],
              };
              
              // Debug log to check profile data
              print('Sending profile data to ViewProfileScreen: name=${profileData['name']}, keys=${profileData.keys.join(', ')}');
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewProfileScreen(
                    profile: profileData,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: _otherUserData!['photoUrls']?.first ?? _otherUserData!['profilePicture'] ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getUserFullName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () {
                if (_otherUserData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallScreen(
                        user: _otherUserData!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to start video call. User data not available.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              splashRadius: 24,
            ),
            IconButton(
              icon: const Icon(
                Icons.phone_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                if (_otherUserData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AudioCallScreen(
                        user: _otherUserData!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to start call. User data not available.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              splashRadius: 24,
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 24,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'blockUser':
                    _showConfirmDialog(
                      'Block User',
                      'Are you sure you want to block this user? You will no longer receive messages from them.',
                      () {
                        // Implement block user functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User blocked successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context); // Go back to chat list
                      },
                    );
                    break;
                  case 'reportUser':
                    _showConfirmDialog(
                      'Report User',
                      'Are you sure you want to report this user for inappropriate behavior?',
                      () {
                        // Implement report user functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User reported successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    );
                    break;
                  case 'clearChat':
                    _showConfirmDialog(
                      'Clear Chat History',
                      'Are you sure you want to clear your chat history? This action cannot be undone.',
                      () {
                        // Implement clear chat functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat history cleared'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    );
                    break;
                  case 'unmatch':
                    _showConfirmDialog(
                      'Unmatch',
                      'Are you sure you want to unmatch with this user? This action cannot be undone.',
                      () {
                        // Implement unmatch functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You have unmatched with this user'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context); // Go back to chat list
                      },
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'blockUser',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Block User'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'reportUser',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Report User'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clearChat',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Clear Chat History'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'unmatch',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Unmatch'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }

                  final message = _messages[index - 1];
                  // Ensure metadata is safely cast to Map<String, dynamic>
                  Map<String, dynamic>? safeMetadata;
                  final rawMetadata = message['metadata'];
                  if (rawMetadata is Map) {
                    safeMetadata = Map<String, dynamic>.from(rawMetadata.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ));
                  }
                  
                  return MessageBubble(
                    message: message['text'],
                    isMe: message['isMe'],
                    timestamp: message['timestamp'],
                    type: message['type'],
                    metadata: safeMetadata,
                  );
                },
              ),
            ),

            // Input field
            ChatInput(
              onSendMessage: _handleSendMessage,
              focusNode: _focusNode,
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Helper function to get user's full name
  String _getUserFullName() {
    if (_otherUserData == null) return 'Unknown User';
    
    final firstName = _otherUserData!['firstName'] ?? '';
    final lastName = _otherUserData!['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    // If we have a valid full name, use it
    if (fullName.isNotEmpty) return fullName;
    
    // Otherwise fall back to other name fields
    return _otherUserData!['name'] ?? 
           _otherUserData!['username'] ?? 
           'Unknown User';
  }

  // Helper function to get location or distance
  String _getLocationOrDistance() {
    if (_otherUserData == null) return '5 km away';
    
    // First try to get the location text
    if (_otherUserData!['locationText'] != null && _otherUserData!['locationText'].toString().isNotEmpty) {
      return _otherUserData!['locationText'].toString();
    }
    
    // Then try to get the distance
    if (_otherUserData!['distance'] != null) {
      final distance = _otherUserData!['distance'];
      if (distance is num) {
        return '$distance km away';
      } else if (distance is String && distance.isNotEmpty) {
        return distance.contains('km') ? distance : '$distance km away';
      }
    }
    
    // Fallback 
    return '5 km away';
  }
} 