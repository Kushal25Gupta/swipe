import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/services/firebase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../chat/chat_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ViewProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final _firebaseService = GetIt.instance<FirebaseService>();
  final PageController _pageController = PageController();
  bool _isProcessing = false;
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Extract profile data safely
  String _getName() {
    return widget.profile['name']?.toString() ?? 
           widget.profile['username']?.toString() ?? 
           widget.profile['displayName']?.toString() ?? 
           'Unknown';
  }

  String _getAgeString() {
    final dynamic age = widget.profile['age'] ?? 25;
    return age is int ? age.toString() : age.toString();
  }

  String _getDistance() {
    return widget.profile['distance']?.toString() ?? '5 miles away';
  }

  String _getBio() {
    return widget.profile['bio']?.toString() ?? 'No bio available';
  }

  bool _isVerified() {
    return widget.profile['verified'] == true || widget.profile['isVerified'] == true;
  }

  List<String> _getPhotoUrls() {
    List<String> urls = [];
    
    try {
      // Try to get images from the 'images' field
      if (widget.profile['images'] != null && widget.profile['images'] is List) {
        for (var img in widget.profile['images']) {
          if (img != null && img.toString().isNotEmpty) {
            urls.add(img.toString());
          }
        }
      }
      
      // Also try 'photoUrls' field if exists
      if (widget.profile['photoUrls'] != null && widget.profile['photoUrls'] is List) {
        for (var img in widget.profile['photoUrls']) {
          if (img != null && img.toString().isNotEmpty) {
            urls.add(img.toString());
          }
        }
      }
    } catch (e) {
      print('Error extracting photo URLs: $e');
    }
    
    return urls;
  }

  bool _hasNonEmptyList(String key) {
    try {
      return widget.profile[key] != null && 
             widget.profile[key] is List && 
             (widget.profile[key] as List).isNotEmpty;
    } catch (e) {
      print('Error checking if $key is a non-empty list: $e');
      return false;
    }
  }

  List _getListItems(String key) {
    try {
      if (_hasNonEmptyList(key)) {
        return widget.profile[key] as List;
      }
      return [];
    } catch (e) {
      print('Error getting list items for $key: $e');
      return [];
    }
  }

  Future<void> _handleLike() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final String userId = widget.profile['id'];
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
          
          // Show match dialog and then pop
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => MatchDialog(
                currentUser: currentUser,
                matchedUser: otherUserDoc,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
            }
          }
        } else {
          // Not a match, just show snackbar and pop
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
        children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Liked ${_getName()}',
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
            
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error handling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handlePass() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final String userId = widget.profile['id'];
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) return;

      // Add to passed users
      await _firebaseService.updateUserProfile({
        'passedUsers': FieldValue.arrayUnion([userId])
      });

      // Update user stats for pass
      await _firebaseService.incrementUserStats(currentUser.uid, 'passed');

      // Show snackbar and return to previous screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.close_rounded, color: Colors.white),
                const SizedBox(width: 8),
          Text(
                  'Passed on ${_getName()}',
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
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      print('Error handling pass: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleSuperLike() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final String userId = widget.profile['id'];
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
          
          // Show match dialog and then pop
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => MatchDialog(
                currentUser: currentUser,
                matchedUser: otherUserDoc,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
            }
          }
        } else {
          // Not a match, just show snackbar and pop
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Super liked ${_getName()}',
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
            
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error handling super like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> photoUrls = _getPhotoUrls();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile Images
          SliverAppBar(
            expandedHeight: screenHeight * 0.6,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
        children: [
                  // Photo gallery
                  photoUrls.isNotEmpty
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: photoUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPhotoIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: photoUrls[index],
                    fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[850],
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                      color: Colors.grey[850],
                      child: const Icon(Icons.person, size: 100, color: Colors.white30),
                    ),
                          );
                        },
                  )
                : Container(
                    color: Colors.grey[850],
                    child: const Icon(Icons.person, size: 100, color: Colors.white30),
                  ),
                      
                  // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.backgroundDark,
                        AppColors.backgroundDark.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
                  
                  // Photo indicators
                  if (photoUrls.length > 1)
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photoUrls.length, (index) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPhotoIndex == index
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }),
                      ),
                    ),
                    
                  // Basic info overlay
              Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                            Expanded(
                              child: Text(
                                '${_getName()}, ${_getAgeString()}',
                          style: TextStyles.headline4Dark.copyWith(
                            color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isVerified())
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.blue,
                                  size: 24,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                              _getDistance(),
                          style: TextStyles.bodyText2Dark.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
          
          // Profile Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // About section
                  _buildSectionTitle('About'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getBio(),
                  style: TextStyles.bodyText1Dark.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                ),
                const SizedBox(height: 24),

                  // Basic info
                  _buildSectionTitle('Basic Info'),
                  const SizedBox(height: 12),
                  _buildInfoGrid([
                    if (widget.profile['job'] != null)
                      _InfoItem(Icons.work_rounded, 'Profession', widget.profile['job'].toString()),
                    if (widget.profile['education'] != null)
                      _InfoItem(Icons.school_rounded, 'Education', widget.profile['education'].toString()),
                    if (widget.profile['relationshipStatus'] != null)
                      _InfoItem(Icons.favorite_rounded, 'Relationship', widget.profile['relationshipStatus'].toString()),
                    if (widget.profile['height'] != null)
                      _InfoItem(Icons.height_rounded, 'Height', widget.profile['height'].toString()),
                    if (widget.profile['zodiacSign'] != null)
                      _InfoItem(Icons.star_rounded, 'Zodiac Sign', widget.profile['zodiacSign'].toString()),
                  ]),
                  const SizedBox(height: 24),
                  
                  // Interests section
                  if (_hasNonEmptyList('interests')) ...[
                    _buildSectionTitle('Interests'),
                    const SizedBox(height: 12),
                    _buildChipsList(_getListItems('interests')),
                  const SizedBox(height: 24),
                ],

                  // Hobbies section
                  if (_hasNonEmptyList('hobbies')) ...[
                    _buildSectionTitle('Hobbies'),
                  const SizedBox(height: 12),
                    _buildChipsList(_getListItems('hobbies')),
                  const SizedBox(height: 24),
                ],

                  // Languages section
                if (_hasNonEmptyList('languages')) ...[
                    _buildSectionTitle('Languages'),
                  const SizedBox(height: 12),
                    _buildChipsList(_getListItems('languages')),
                  const SizedBox(height: 24),
                ],

                  // Personality section
                  if (_hasNonEmptyList('personality')) ...[
                    _buildSectionTitle('Personality'),
                  const SizedBox(height: 12),
                    _buildChipsList(_getListItems('personality')),
                  const SizedBox(height: 24),
                ],

                  // Looking for section
                  if (_hasNonEmptyList('lookingFor')) ...[
                    _buildSectionTitle('Looking For'),
                  const SizedBox(height: 12),
                    _buildChipsList(_getListItems('lookingFor')),
                    const SizedBox(height: 24),
                  ],
                  
                  // Extra space at bottom for action buttons
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                Icons.close_rounded, 
                Colors.red, 
                'Pass',
                onTap: _isProcessing ? null : _handlePass,
              ),
              _buildActionButton(
                Icons.star_rounded,
                Colors.blue,
                'Super Like',
                onTap: _isProcessing ? null : _handleSuperLike,
              ),
              _buildActionButton(
                Icons.favorite_rounded, 
                Colors.green,
                'Like',
                onTap: _isProcessing ? null : _handleLike,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyles.headline6Dark.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildInfoGrid(List<_InfoItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
    return Container(
          padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: AppColors.primary,
        size: 20,
      ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: TextStyles.caption.copyWith(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyles.bodyText2Dark.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildChipsList(List items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            item.toString(),
            style: TextStyles.bodyText2Dark.copyWith(
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildActionButton(IconData icon, Color color, String label, {required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
            child: _isProcessing
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Icon(
                    icon,
        color: color,
                    size: 28,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for info items
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  
  _InfoItem(this.icon, this.label, this.value);
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
    final String name = widget.matchedUser['name']?.toString() ?? 
                        widget.matchedUser['firstName']?.toString() ?? 
                        'your match';
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'It\'s a Match!',
              style: TextStyles.headline5Dark.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You and $name have liked each other!',
              style: TextStyles.bodyText1Dark.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Keep Swiping',
                      style: TextStyles.buttonDark.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
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
                              Navigator.pop(context, true);
                              
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
                            Navigator.pop(context, false);
                          }
                        }
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 