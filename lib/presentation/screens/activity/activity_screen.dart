import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/services/firebase_service.dart';
import '../chat/chat_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../widgets/common/loading_overlay.dart';

enum NotificationType { Match, Like, SuperLike, System, All }

class ActivityNotification {
  final String id;
  final String title;
  final String message;
  final String image;
  final DateTime time;
  final String type;
  final String fromUserId;
  bool isRead;

  ActivityNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.image,
    required this.time,
    required this.type,
    required this.fromUserId,
    this.isRead = false,
  });

  NotificationType get category {
    switch (type) {
      case 'match':
        return NotificationType.Match;
      case 'superlike':
        return NotificationType.SuperLike;
      case 'like':
        return NotificationType.Like;
      default:
        return NotificationType.System;
    }
  }
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late FirebaseService _firebaseService;
  List<ActivityNotification> _notifications = [];
  bool _isLoading = true;
  bool _isHandlingMatch = false;
  bool _isHandlingLike = false;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  final _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;
  NotificationType _selectedType = NotificationType.All;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _firebaseService = GetIt.instance<FirebaseService>();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = NotificationType.values[_tabController.index];
        });
      }
    });
    _animationController.forward();
    _loadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _loadNotifications() {
    if (_currentUser == null) return;
    
    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
          final notifications = <ActivityNotification>[];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Get sender's user data
            final senderId = data['fromUserId'] as String?;
            String senderName = 'Someone';
            
            if (senderId != null) {
              try {
                final senderDoc = await _firestore.collection('users').doc(senderId).get();
                if (senderDoc.exists) {
                  final senderData = senderDoc.data() as Map<String, dynamic>;
                  final firstName = senderData['firstName'] as String? ?? '';
                  final lastName = senderData['lastName'] as String? ?? '';
                  senderName = '$firstName $lastName'.trim();
                }
              } catch (e) {
                print('Error fetching sender data: $e');
              }
            }
            
            notifications.add(ActivityNotification(
              id: doc.id,
              title: data['title'] ?? '',
              message: data['message'] ?? '',
              image: data['image'] ?? '',
              time: (data['createdAt'] as Timestamp).toDate(),
              type: data['type'] ?? '',
              fromUserId: data['fromUserId'] ?? '',
              isRead: data['isRead'] ?? false,
            ));
          }
          
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        });
  }

  List<ActivityNotification> get filteredNotifications {
    if (_selectedType == NotificationType.All) {
      return _notifications;
    }
    return _notifications.where((n) => n.category == _selectedType).toList();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  int getUnreadCountByType(NotificationType type) {
    if (type == NotificationType.All) {
      return unreadCount;
    }
    return _notifications
        .where((n) => !n.isRead && n.category == type)
        .length;
  }

  Future<void> _markAsRead(ActivityNotification notification) async {
    try {
      await _firebaseService.updateNotificationStatus(notification.id, true);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      List<ActivityNotification> unreadNotifications;
      
      if (_selectedType == NotificationType.All) {
        unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      } else {
        unreadNotifications = _notifications
            .where((n) => !n.isRead && n.category == _selectedType)
            .toList();
      }
      
      if (unreadNotifications.isEmpty) return;
      
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      for (var notification in unreadNotifications) {
        await _firebaseService.updateNotificationStatus(notification.id, true);
        notification.isRead = true;
      }
      
      // Refresh UI
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notifications as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    try {
      // Confirm deletion
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete notifications?'),
          content: Text(_selectedType == NotificationType.All
              ? 'This will delete all your notifications'
              : 'This will delete all ${_selectedType.name.toLowerCase()} notifications'),
          backgroundColor: AppColors.backgroundDark,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      List<ActivityNotification> notificationsToDelete;
      
      if (_selectedType == NotificationType.All) {
        notificationsToDelete = List.from(_notifications);
      } else {
        notificationsToDelete = _notifications
            .where((n) => n.category == _selectedType)
            .toList();
      }
      
      if (notificationsToDelete.isEmpty) return;
      
      setState(() {
        _isDeleting = true;
      });
      
      final batch = _firestore.batch();
      
      for (var notification in notificationsToDelete) {
        final docRef = _firestore.collection('notifications').doc(notification.id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      
      setState(() {
        _isDeleting = false;
        if (_selectedType == NotificationType.All) {
          _notifications.clear();
        } else {
          _notifications.removeWhere((n) => n.category == _selectedType);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting notifications: $e');
      setState(() {
        _isDeleting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'match':
        return Colors.green;
      case 'superlike':
        return Colors.blue;
      case 'like':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'match':
        return Icons.favorite_rounded;
      case 'superlike':
        return Icons.star_rounded;
      case 'like':
        return Icons.thumb_up_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Future<void> _handleNotificationPermission(String notificationId, String fromUserId) async {
    try {
      print('Handling notification permission for user: $fromUserId');
      
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        print('Current user is null');
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        );
      }

      // Get the user who liked you
      final userDoc = await _firebaseService.getUserData(fromUserId);
      if (userDoc == null) {
        print('User document not found for ID: $fromUserId');
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find user information. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('Found user document: ${userDoc['name']}');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show permission dialog with user details
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(userDoc['photoUrls']?.first ?? 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y'),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Text(
                userDoc['name'] ?? 'Someone',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '${userDoc['name'] ?? 'Someone'} liked your profile! Would you like to start chatting?',
            style: const TextStyle(color: Colors.white70),
          ),
          backgroundColor: AppColors.backgroundDark,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No Thanks'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start Chat'),
            ),
          ],
        ),
      );

      print('Dialog result: $result');

      if (result == true) {
        print('Creating match...');
        // Create match and chat room
        final matchId = await _firebaseService.createMatch(currentUser.uid, fromUserId);
        print('Match created with ID: $matchId');
        
        // Mark notification as handled
        await _firebaseService.updateNotificationStatus(notificationId, true, status: 'accepted');
        print('Notification marked as accepted');
        
        // Navigate to chat screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                matchId: matchId!,
                otherUserId: fromUserId,
              ),
            ),
          );
        }
      } else {
        print('Notification rejected');
        // Mark notification as rejected
        await _firebaseService.updateNotificationStatus(notificationId, true, status: 'rejected');
      }
    } catch (e) {
      print('Error handling notification permission: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if it's still open
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading || _isDeleting,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity',
                style: TextStyles.headline5Dark.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
              if (unreadCount > 0)
                Text(
                  '$unreadCount new notifications',
                  style: TextStyles.bodyText2Dark.copyWith(
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          actions: [
            if (filteredNotifications.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'read') {
                    _markAllAsRead();
                  } else if (value == 'delete') {
                    _deleteAllNotifications();
                  }
                },
                itemBuilder: (context) => [
                  if (filteredNotifications.any((n) => !n.isRead))
                    const PopupMenuItem<String>(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read),
                          SizedBox(width: 8),
                          Text('Mark all as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 8),
                        Text('Clear all'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            tabs: NotificationType.values.map((type) {
              final unreadCountForType = getUnreadCountByType(type);
              return Tab(
                child: Row(
                  children: [
                    Text(type.name),
                    if (unreadCountForType > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCountForType.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: NotificationType.values.map((type) {
            return _buildNotificationList(type);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationList(NotificationType type) {
    final notifications = type == NotificationType.All
        ? _notifications
        : _notifications.where((n) => n.category == type).toList();
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: notifications.isEmpty
            ? _buildEmptyState(type)
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await Future.delayed(const Duration(milliseconds: 500));
                  _loadNotifications();
                },
                color: AppColors.primary,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildNotificationItem(ActivityNotification notification) {
    final typeColor = _getTypeColor(notification.type);
    final imageUrl = notification.image.isNotEmpty 
        ? notification.image 
        : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';
    
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(notification.fromUserId).get(),
      builder: (context, snapshot) {
        String senderName = 'Someone';
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = userData['firstName'] as String? ?? '';
          final lastName = userData['lastName'] as String? ?? '';
          senderName = '$firstName $lastName'.trim();
        }
        
        return Dismissible(
          key: Key(notification.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            try {
              await _firestore.collection('notifications').doc(notification.id).delete();
              setState(() {
                _notifications.remove(notification);
              });
            } catch (e) {
              print('Error deleting notification: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete notification'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: GestureDetector(
            onTap: () async {
              // If notification is already read or we're handling another action, do nothing
              if (notification.isRead || _isHandlingMatch || _isHandlingLike) return;
              
              // Mark as read immediately
              await _markAsRead(notification);
              setState(() {
                notification.isRead = true;
              });
              
              // Handle notification based on type
              if (notification.type == 'like' || notification.type == 'superlike') {
                setState(() {
                  _isHandlingLike = true;
                });
                try {
                  await _handleNotificationPermission(
                    notification.id,
                    notification.fromUserId,
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isHandlingLike = false;
                    });
                  }
                }
              } else if (notification.type == 'match') {
                setState(() {
                  _isHandlingMatch = true;
                });
                
                try {
                  // Find the match ID by checking if both users are involved in the match
                  final matches = await _firestore
                      .collection('matches')
                      .where('users', arrayContains: _currentUser!.uid)
                      .get();

                  String? matchId;
                  for (var match in matches.docs) {
                    final users = List<String>.from(match['users']);
                    if (users.contains(notification.fromUserId)) {
                      matchId = match.id;
                      break;
                    }
                  }

                  if (matchId != null) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            matchId: matchId!,
                            otherUserId: notification.fromUserId,
                          ),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not find the match. Please try again later.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  print('Error handling match notification: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('An error occurred. Please try again later.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isHandlingMatch = false;
                    });
                  }
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.white.withOpacity(0.03)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notification.isRead
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  if (!notification.isRead)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Hero(
                              tag: 'notification_image_${notification.id}',
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) {
                                      print('Error loading notification image: $exception');
                                    },
                                  ),
                                  border: Border.all(
                                    color: typeColor.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.backgroundDark,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getTypeIcon(notification.type),
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      senderName,
                                      style: TextStyles.subtitle1Dark.copyWith(
                                        color: Colors.white,
                                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeago.format(notification.time),
                                    style: TextStyles.captionDark.copyWith(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: TextStyles.bodyText2Dark.copyWith(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              if (notification.type == 'like' || notification.type == 'superlike')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: notification.isRead ? null : () async {
                                          await _markAsRead(notification);
                                          setState(() {
                                            notification.isRead = true;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          side: BorderSide(
                                            color: notification.isRead 
                                                ? Colors.white24 
                                                : Colors.white54,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          'Dismiss',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: notification.isRead 
                                                ? Colors.white24 
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: notification.isRead ? null : () async {
                                          setState(() {
                                            _isHandlingLike = true;
                                          });
                                          try {
                                            await _handleNotificationPermission(
                                              notification.id,
                                              notification.fromUserId,
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                _isHandlingLike = false;
                                              });
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          backgroundColor: notification.isRead 
                                              ? Colors.white24 
                                              : AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          'Check Profile',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: notification.isRead 
                                                ? Colors.white54 
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(NotificationType type) {
    String message;
    IconData icon;
    
    switch (type) {
      case NotificationType.Match:
        message = 'No matches yet. Keep swiping!';
        icon = Icons.favorite_border_rounded;
        break;
      case NotificationType.Like:
        message = 'No likes yet. Keep improving your profile!';
        icon = Icons.thumb_up_off_alt_rounded;
        break;
      case NotificationType.SuperLike:
        message = 'No super likes yet. Someone special will notice you soon!';
        icon = Icons.star_border_rounded;
        break;
      case NotificationType.System:
        message = 'No system notifications';
        icon = Icons.notifications_none_rounded;
        break;
      case NotificationType.All:
      default:
        message = 'When you get new matches, likes, or messages, they\'ll show up here';
        icon = Icons.notifications_none_rounded;
        break;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Activity Yet',
            style: TextStyles.headline5Dark.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: TextStyles.bodyText1Dark.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 