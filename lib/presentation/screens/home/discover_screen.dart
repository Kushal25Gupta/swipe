import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/services/firebase_service.dart';
import '../../widgets/cards/profile_card.dart';
import '../../widgets/common/swipe_buttons.dart';
import '../../screens/activity/activity_screen.dart';
import '../../screens/filters/filters_screen.dart';
import '../../screens/profile/view_profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import '../chat/chat_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final User currentUser;
  
  const DiscoverScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with TickerProviderStateMixin {
  late CardSwiperController _cardController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _previousMatches = [];
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  String? _error;
  
  final _firebaseService = GetIt.instance<FirebaseService>();
  int _unreadNotifications = 0;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _cardController = CardSwiperController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadProfiles();
    _loadUnreadNotifications();
  }

  Future<void> _loadProfiles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Get current user's data
      final userDoc = await _firebaseService.getUserData(currentUser.uid);
      if (userDoc == null) {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      // Debug print user document
      print('User document: $userDoc');

      // Get previously passed and liked users
      final passedUsers = List<String>.from(userDoc['passedUsers'] ?? []);
      final likedUsers = List<String>.from(userDoc['likedUsers'] ?? []);

      // Get current user's location
      final locationString = userDoc['location'] as String?;
      print('Location string: $locationString');
      
      if (locationString == null || locationString.isEmpty) {
        setState(() {
          _error = 'Location not set in profile';
          _isLoading = false;
        });
        return;
      }

      // Parse location string (assuming format: "latitude,longitude")
      final locationParts = locationString.split(',');
      print('Location parts: $locationParts');
      
      if (locationParts.length != 2) {
        setState(() {
          _error = 'Invalid location format';
          _isLoading = false;
        });
        return;
      }

      final latitude = double.tryParse(locationParts[0]);
      final longitude = double.tryParse(locationParts[1]);
      print('Parsed coordinates - Latitude: $latitude, Longitude: $longitude');
      
      if (latitude == null || longitude == null) {
        setState(() {
          _error = 'Invalid location coordinates';
          _isLoading = false;
        });
        return;
      }

      // Load filtered potential matches
      final matches = await _firebaseService.getPotentialMatches(
        currentUserId: currentUser.uid,
        latitude: latitude,
        longitude: longitude,
        radiusInKm: 50.0, // 50km radius
      );

      print('DEBUG MATCHING: Got ${matches.length} potential matches from Firebase service');

      // Filter out passed and liked users
      final filteredMatches = matches.where((match) {
        final userId = match['id'] as String;
        final isNotPassed = !passedUsers.contains(userId);
        final isNotLiked = !likedUsers.contains(userId);
        print('DEBUG MATCHING: User ${match['name']} (ID: $userId) - Not passed: $isNotPassed, Not liked: $isNotLiked');
        return isNotPassed && isNotLiked;
      }).toList();

      print('DEBUG MATCHING: After filtering passed/liked users, ${filteredMatches.length} matches remain');

      setState(() {
        _profiles = filteredMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profiles: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _animationController.dispose();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _loadUnreadNotifications() {
    if (widget.currentUser == null) return;
    
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: widget.currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _unreadNotifications = snapshot.docs.length;
            });
          }
        }, onError: (error) {
          print('Error loading notifications: $error');
          if (mounted) {
            setState(() {
              _unreadNotifications = 0;
            });
          }
        });
  }

  Future<void> _handleLike(String userId) async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) return;

      // Add to liked users
      await _firebaseService.updateUserProfile({
        'likedUsers': FieldValue.arrayUnion([userId])
      });

      // Update user stats for like
      await _firebaseService.incrementUserStats(currentUser.uid, 'likes');

      // Send notification to the liked user
      await _firebaseService.sendNotification(
        userId,
        'New Like',
        '${currentUser.displayName ?? 'Someone'} liked your profile!',
        type: 'like',
      );

      // Check if it's a match
      final otherUserDoc = await _firebaseService.getUserData(userId);
      if (otherUserDoc != null) {
        final otherUserLikes = List<String>.from(otherUserDoc['likedUsers'] ?? []);
        if (otherUserLikes.contains(currentUser.uid)) {
          // It's a match! Create a chat room
          await _firebaseService.createMatch(currentUser.uid, userId);
          
          // Show match dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => MatchDialog(
                currentUser: currentUser,
                matchedUser: otherUserDoc,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error handling like: $e');
    }
  }

  Future<void> _handlePass(String userId) async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) return;

      // Add to passed users
      await _firebaseService.updateUserProfile({
        'passedUsers': FieldValue.arrayUnion([userId])
      });

      // Update user stats for pass
      await _firebaseService.incrementUserStats(currentUser.uid, 'passed');
    } catch (e) {
      print('Error handling pass: $e');
    }
  }

  Future<void> _handleSuperLike(String userId) async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) return;

      // Add to liked users and favorites
      await _firebaseService.updateUserProfile({
        'likedUsers': FieldValue.arrayUnion([userId]),
        'favoriteUsers': FieldValue.arrayUnion([userId])
      });

      // Update user stats for super like
      await _firebaseService.incrementUserStats(currentUser.uid, 'superLikes');

      // Send notification to the super liked user
      await _firebaseService.sendNotification(
        userId,
        'New Super Like',
        '${currentUser.displayName ?? 'Someone'} super liked your profile!',
      );

      // Check if it's a match
      final otherUserDoc = await _firebaseService.getUserData(userId);
      if (otherUserDoc != null) {
        final otherUserLikes = List<String>.from(otherUserDoc['likedUsers'] ?? []);
        if (otherUserLikes.contains(currentUser.uid)) {
          // It's a match! Create a chat room
          await _firebaseService.createMatch(currentUser.uid, userId);
          
          // Show match dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => MatchDialog(
                currentUser: currentUser,
                matchedUser: otherUserDoc,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error handling super like: $e');
    }
  }

  void _onPass() {
    if (_currentIndex < _profiles.length) {
      final currentProfile = _profiles[_currentIndex];
      
      // First swipe the card to animate it
      _cardController.swipeLeft();
      
      // After animation would complete, update the data
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _handlePass(currentProfile['id']);
        _previousMatches.add(currentProfile);
        
        // Only remove from profiles list if it still exists
        // Do a safe check to prevent duplicate removals
        if (mounted) {
          setState(() {
            final profileIndex = _profiles.indexWhere((p) => p['id'] == currentProfile['id']);
            if (profileIndex >= 0) {
              _profiles.removeAt(profileIndex);
            }
            
            // Debug log profile count
            print('DEBUG: Profiles remaining after pass: ${_profiles.length}');
          });
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.close_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Passed on ${currentProfile['name']}',
                style: TextStyles.bodyText2Dark.copyWith(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onSuperLike() {
    if (_currentIndex < _profiles.length) {
      final currentProfile = _profiles[_currentIndex];
      
      // First swipe the card to animate it
      _cardController.swipeTop();
      
      // After animation would complete, update the data
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _handleSuperLike(currentProfile['id']);
        _previousMatches.add(currentProfile);
        
        // Only remove from profiles list if it still exists
        // Do a safe check to prevent duplicate removals
        if (mounted) {
          setState(() {
            final profileIndex = _profiles.indexWhere((p) => p['id'] == currentProfile['id']);
            if (profileIndex >= 0) {
              _profiles.removeAt(profileIndex);
            }
            
            // Debug log profile count
            print('DEBUG: Profiles remaining after super like: ${_profiles.length}');
          });
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Super liked ${currentProfile['name']}',
                style: TextStyles.bodyText2Dark.copyWith(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onLike() {
    if (_currentIndex < _profiles.length) {
      final currentProfile = _profiles[_currentIndex];
      
      // First swipe the card to animate it
      _cardController.swipeRight();
      
      // After animation would complete, update the data
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _handleLike(currentProfile['id']);
        _previousMatches.add(currentProfile);
        
        // Only remove from profiles list if it still exists
        // Do a safe check to prevent duplicate removals
        if (mounted) {
          setState(() {
            final profileIndex = _profiles.indexWhere((p) => p['id'] == currentProfile['id']);
            if (profileIndex >= 0) {
              _profiles.removeAt(profileIndex);
            }
            
            // Debug log profile count
            print('DEBUG: Profiles remaining after like: ${_profiles.length}');
          });
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Liked ${currentProfile['name']}',
                style: TextStyles.bodyText2Dark.copyWith(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onRewind() {
    if (_previousMatches.isNotEmpty) {
      setState(() {
        _profiles.insert(0, _previousMatches.removeLast());
        _currentIndex = 0;
      });
    }
  }

  void _onBoost() {
    // TODO: Implement boost functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Boost functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 8,
              left: 20,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Swipe',
                  style: TextStyles.headline4Dark.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
                ),
                Row(
                  children: [
                    _buildIconButton(
                      Icons.notifications_outlined,
                      _unreadNotifications > 0 ? _unreadNotifications.toString() : null,
                      _showNotifications,
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      Icons.tune_rounded,
                      null,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FiltersScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _profiles.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Card Swiper
                        SizedBox(
                          height: _profiles.length >= 3 
                              ? screenSize.height * 0.66 
                              : screenSize.height * 0.69,
                          child: CardSwiper(
                            controller: _cardController,
                            cardsCount: _profiles.length,
                            onSwipe: (previousIndex, currentIndex, direction) {
                              // Handle the swipe based on direction
                              if (previousIndex != null) {
                                final swipedProfile = _profiles[previousIndex];
                                final swipedProfileId = swipedProfile['id'];
                                
                                if (direction == CardSwiperDirection.left) {
                                  _handlePass(swipedProfileId);
                                } else if (direction == CardSwiperDirection.right) {
                                  _handleLike(swipedProfileId);
                                } else if (direction == CardSwiperDirection.top) {
                                  _handleSuperLike(swipedProfileId);
                                }
                                
                                // Add to previous matches for possible rewind
                                _previousMatches.add(swipedProfile);
                                
                                // Let the swipe animation complete first
                                print('Swiped profile: ${swipedProfile['name']} (${direction.toString()})');
                              }
                              
                              return true;
                            },
                            numberOfCardsDisplayed: _profiles.length >= 3 ? 3 : _profiles.length,
                            backCardOffset: const Offset(0, 40),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            cardBuilder: (context, index, _, __) {
                              // Prevent RangeError if index is out-of-bounds
                              if (index < 0 || index >= _profiles.length) {
                                print('CardSwiper requested invalid index: $index (available: ${_profiles.length})');
                                return const SizedBox.shrink();
                              }
                              
                              // Make sure we have a valid profile at this index
                              final profile = _profiles[index];
                              if (profile == null) {
                                print('Profile at index $index is null');
                                return const SizedBox.shrink();
                              }
                              
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewProfileScreen(
                                        profile: profile,
                                      ),
                                    ),
                                  );
                                },
                                child: ProfileCard(
                                  profile: profile,
                                ),
                              );
                            },
                          ),
                        ),

                        // Dynamic spacing based on number of cards
                        SizedBox(
                          height: _profiles.length >= 3 ? 24 : 0,
                        ),
                        
                        // Swipe Buttons
                        SwipeButtons(
                          onPass: _onPass,
                          onSuperLike: _onSuperLike,
                          onLike: _onLike,
                          onRewind: _onRewind,
                          onBoost: _onBoost,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    String? badgeText,
    VoidCallback onPressed,
  ) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon),
          color: Colors.white,
          iconSize: 26,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (badgeText != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundDark,
                  width: 2,
                ),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActivityScreen(),
      ),
    ).then((_) {
      setState(() {
        _unreadNotifications = 0;
      });
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No more profiles',
            style: TextStyles.headline5Dark,
          ),
          const SizedBox(height: 8),
          Text(
            'Come back later to see more people',
            style: TextStyles.bodyText2Dark.copyWith(
              color: AppColors.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProfiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text(
              'Refresh',
              style: TextStyles.buttonDark,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // Go to edit profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((updatedData) {
                // Reload profiles when returning from edit profile
                _loadProfiles();
                
                // Update user stats if available
                if (updatedData != null && updatedData['stats'] != null) {
                  // If you need to save stats in the Discover screen,
                  // you could store them in a variable here
                  
                  // You could also update any UI that shows stats if needed
                }
              });
            },
            child: const Text(
              'Edit Preferences',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchDialog extends StatefulWidget {
  final User currentUser;
  final Map<String, dynamic> matchedUser;

  const MatchDialog({
    super.key,
    required this.currentUser,
    required this.matchedUser,
  });

  @override
  State<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<MatchDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'It\'s a Match!',
              style: TextStyles.headline5Dark.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You and ${widget.matchedUser['name']} have liked each other!',
              style: TextStyles.bodyText2Dark,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _isLoading 
                    ? null 
                    : () {
                        Navigator.pop(context, false);
                      },
                  child: Text(
                    'Keep Swiping',
                    style: TextStyles.buttonDark.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading 
                    ? null 
                    : () async {
                        setState(() => _isLoading = true);
                        
                        try {
                          // Get match ID
                          final currentUserId = widget.currentUser.uid;
                          final matchedUserId = widget.matchedUser['id'];
                          
                          // Get all matches that contain both users
                          final matches = await FirebaseFirestore.instance
                            .collection('matches')
                            .where('users', arrayContains: currentUserId)
                            .get();
                            
                          String? matchId;
                          for (var doc in matches.docs) {
                            final users = List<String>.from(doc.data()['users'] ?? []);
                            if (users.contains(matchedUserId)) {
                              matchId = doc.id;
                              break;
                            }
                          }
                          
                          if (matchId != null) {
                            if (mounted) {
                              // Close dialog first
                              Navigator.pop(context);
                              
                              // Navigate to chat screen, ensuring matchId is not null
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    matchId: matchId!, // Use null assertion operator since we already checked
                                    otherUserId: matchedUserId,
                                  ),
                                ),
                              );
                            }
                          } else {
                            throw Exception('Match not found');
                          }
                        } catch (e) {
                          print('Error navigating to chat: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Start Chat',
                        style: TextStyles.buttonDark,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 