import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import 'widgets/profile_menu_item.dart';
import 'widgets/profile_stats_item.dart';
import 'widgets/profile_highlight_item.dart';
import './edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../privacy/privacy_screen.dart';
import '../help/help_screen.dart';
import '../about/about_screen.dart';
import '../../../data/services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _firebaseService = GetIt.instance<FirebaseService>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  // Stats that will be fetched from Firebase
  Map<String, dynamic> _stats = {
    'posts': '0',
    'started': '0',
    'passed': '0',
    'matches': '0',
    'likes': '0',
    'superLikes': '0',
  };

  // Menu Items from Firebase
  List<Map<String, dynamic>> _menuItems = [];

  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;
  bool _isPageViewReady = false;

  // Tab Controller for profile sections
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['About', 'Photos', 'Stats'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_handleAnimation);
    _loadUserData();
    _loadMenuItems();
  }

  void _handleAnimation() {
    if (_animationController.isCompleted && _isPageViewReady) {
      _nextPage();
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      
      // Helper function to safely convert to list
      List<dynamic> safeList(dynamic value) {
        if (value == null) return [];
        if (value is List) return value;
        if (value is String) return [value];
        return [];
      }

      // Helper function to safely get string value
      String safeString(dynamic value) {
        if (value == null) return '';
        return value.toString();
      }

      // Calculate age from birthdate
      final birthdate = (data['birthdate'] as Timestamp?)?.toDate();
      final age = birthdate != null 
          ? DateTime.now().year - birthdate.year 
          : null;

      // Format joined date
      final joinedDate = (data['createdAt'] as Timestamp?)?.toDate();
      final formattedJoinedDate = joinedDate != null
          ? '${joinedDate.month}/${joinedDate.year}'
          : 'Unknown';

      // Format last active
      final lastActive = (data['lastActive'] as Timestamp?)?.toDate();
      final formattedLastActive = lastActive != null
          ? _formatLastActive(lastActive)
          : 'Unknown';

      // Fetch user stats
      final statsDoc = await _firestore.collection('user_stats').doc(userId).get();
      if (statsDoc.exists) {
        final statsData = statsDoc.data() as Map<String, dynamic>;
        setState(() {
          _stats = {
            'posts': safeString(statsData['posts'] ?? 0),
            'started': safeString(statsData['started'] ?? 0),
            'passed': safeString(statsData['passed'] ?? 0),
            'matches': safeString(statsData['matches'] ?? 0),
            'likes': safeString(statsData['likes'] ?? 0),
            'superLikes': safeString(statsData['superLikes'] ?? 0),
          };
        });
      }
      
      setState(() {
        _userData = {
          ...data,
          'photoUrls': safeList(data['photoUrls']),
          'firstName': safeString(data['firstName']),
          'lastName': safeString(data['lastName']),
          'username': safeString(data['username']).isEmpty 
              ? 'user${userId.substring(0, 6)}' 
              : data['username'],
          'bio': safeString(data['bio']),
          'location': safeString(data['location']).isEmpty 
              ? 'Not specified' 
              : data['location'],
          'job': safeString(data['job']).isEmpty 
              ? 'Not specified' 
              : data['job'],
          'education': safeString(data['education']).isEmpty 
              ? 'Not specified' 
              : data['education'],
          'relationshipStatus': safeString(data['relationshipStatus']).isEmpty 
              ? 'Not specified' 
              : data['relationshipStatus'],
          'height': safeString(data['height']).isEmpty 
              ? 'Not specified' 
              : data['height'],
          'zodiacSign': safeString(data['zodiacSign']).isEmpty 
              ? 'Not specified' 
              : data['zodiacSign'],
          'personality': safeList(data['personality']),
          'lookingFor': safeList(data['lookingFor']),
          'interests': safeList(data['interests']),
          'hobbies': safeList(data['hobbies']),
          'languages': safeList(data['languages']),
          'favoriteMusic': safeList(data['favoriteMusic']),
          'favoriteMovies': safeList(data['favoriteMovies']),
          'favoriteBooks': safeList(data['favoriteBooks']),
          'favoriteFood': safeList(data['favoriteFood']),
          'favoriteSports': safeList(data['favoriteSports']),
          'favoriteTravel': safeList(data['favoriteTravel']),
          'isVerified': data['isVerified'] ?? false,
          'premium': data['premium'] ?? false,
          'age': age,
          'joinedDate': formattedJoinedDate,
          'lastActive': formattedLastActive,
          'name': '${safeString(data['firstName'])} ${safeString(data['lastName'])}'.trim(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMenuItems() async {
    try {
      final menuData = await _firebaseService.getMenuItems();
      if (menuData.isNotEmpty) {
        setState(() {
          _menuItems = List<Map<String, dynamic>>.from(menuData['items'] ?? []);
        });
      } else {
        // Fallback menu items if Firebase fails
        setState(() {
          _menuItems = [
            {
              'icon': Icons.person_outline,
              'title': 'Edit Profile',
              'route': '/edit-profile',
            },
            {
              'icon': Icons.settings_outlined,
              'title': 'Settings',
              'route': '/settings',
            },
            {
              'icon': Icons.notifications_outlined,
              'title': 'Notifications',
              'route': '/notifications',
            },
            {
              'icon': Icons.security_outlined,
              'title': 'Privacy',
              'route': '/privacy',
            },
            {
              'icon': Icons.help_outline,
              'title': 'Help & Support',
              'route': '/help',
            },
            {
              'icon': Icons.info_outline,
              'title': 'About',
              'route': '/about',
            },
          ];
        });
      }
    } catch (e) {
      print('Error loading menu items: $e');
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastActive.month}/${lastActive.day}/${lastActive.year}';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (!_isPageViewReady) return;
    
    final totalPages = _userData?['photoUrls']?.length ?? 0;
    if (totalPages <= 1) return;

    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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

    if (_userData == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(
            'No profile data available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomNavigationBarHeight = kBottomNavigationBarHeight;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: DefaultTabController(
        length: _tabs.length,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: screenHeight * 0.45,
                pinned: true,
                backgroundColor: AppColors.backgroundDark,
                leading: Container(
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        ).then((updatedData) {
                          if (updatedData != null) {
                            // Calculate age from birthdate
                            final birthdate = (updatedData['birthdate'] as Timestamp?)?.toDate();
                            final age = birthdate != null 
                                ? DateTime.now().year - birthdate.year 
                                : null;
    
                            setState(() {
                              _userData = {
                                ..._userData!,
                                ...updatedData,
                                'name': '${updatedData['firstName']} ${updatedData['lastName']}',
                                'age': age ?? _userData!['age'],
                              };
                              
                              // Update stats if provided in returned data
                              if (updatedData['stats'] != null) {
                                final statsData = updatedData['stats'] as Map<String, dynamic>;
                                _stats = {
                                  'posts': statsData['posts']?.toString() ?? _stats['posts'] ?? '0',
                                  'started': statsData['started']?.toString() ?? _stats['started'] ?? '0',
                                  'passed': statsData['passed']?.toString() ?? _stats['passed'] ?? '0',
                                  'matches': statsData['matches']?.toString() ?? _stats['matches'] ?? '0',
                                  'likes': statsData['likes']?.toString() ?? _stats['likes'] ?? '0',
                                  'superLikes': statsData['superLikes']?.toString() ?? _stats['superLikes'] ?? '0',
                                };
                              }
                            });
                          }
                        });
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      color: Colors.white,
                      onPressed: () => _showMenuOptions(context),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Swipeable Profile Pictures
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: (_userData!['photoUrls'] as List).length,
                        itemBuilder: (context, index) {
                          if (!_isPageViewReady) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _isPageViewReady = true;
                              });
                              _animationController.forward();
                            });
                          }
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'profile_image_$index',
                                child: CachedNetworkImage(
                                  imageUrl: (_userData!['photoUrls'] as List)[index] as String,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[900],
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white38,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      AppColors.backgroundDark.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      // Picture Count Indicator
                      Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            (_userData!['photoUrls'] as List).length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentPage ? AppColors.primary : Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Profile Info Overlay at Bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 50),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_userData!['name'] ?? 'Unknown User'}, ${_userData!['age']?.toString() ?? 'N/A'}',
                                    style: TextStyles.headline4Dark.copyWith(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_userData!['isVerified'] == true)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _userData!['location'] ?? 'Unknown location',
                                    style: TextStyles.bodyText2Dark.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  if (_userData!['premium'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.amber.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 12,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'Premium',
                                            style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Stats Row
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildProfileStat(_stats['matches'] ?? '0', 'Matches'),
                                    _buildStatDivider(),
                                    _buildProfileStat(_stats['likes'] ?? '0', 'Likes'),
                                    _buildStatDivider(),
                                    _buildProfileStat(_stats['superLikes'] ?? '0', 'SuperLikes'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(50),
                  child: Container(
                    color: AppColors.backgroundDark,
                    child: TabBar(
                      tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorSize: TabBarIndicatorSize.label,
                      onTap: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // About Tab
              _buildAboutTab(),
              
              // Photos Tab
              _buildPhotosTab(),
              
              // Stats Tab
              _buildStatsTab(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyles.headline6Dark.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyles.captionDark.copyWith(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }
  
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick action buttons in a row at the top
        _buildQuickActionRow(),
        const SizedBox(height: 24),
        
        // Bio with special styling
        if (_userData!['bio']?.isNotEmpty == true) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'About Me',
                    style: TextStyles.subtitle1Dark.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bio text with a subtle indicator instead of a box
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'In their own words',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userData!['bio'] ?? '',
                      style: TextStyles.bodyText2Dark.copyWith(
                        color: Colors.white,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.08),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],

        // Basic Info
        _buildInfoSection(
          title: 'Basic Info',
          items: [
            _buildInfoItem(Icons.work, 'Work', _userData!['job']),
            _buildInfoItem(Icons.school, 'Education', _userData!['education']),
            _buildInfoItem(Icons.favorite, 'Relationship', _userData!['relationshipStatus']),
            _buildInfoItem(Icons.height, 'Height', _userData!['height']),
            _buildInfoItem(Icons.star, 'Zodiac', _userData!['zodiacSign']),
          ],
        ),
        const SizedBox(height: 16),

        // Personality & Looking For
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Personality & Goals',
                  style: TextStyles.subtitle1Dark.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChipSection('Personality', _userData!['personality'] ?? [], Colors.blue),
                  const SizedBox(height: 16),
                  _buildChipSection('Looking For', _userData!['lookingFor'] ?? [], Colors.pink),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white12),
          ],
        ),
        const SizedBox(height: 16),

        // Interests & Hobbies
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Interests & Hobbies',
                  style: TextStyles.subtitle1Dark.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChipSection('Interests', _userData!['interests'] ?? [], Colors.green),
                  const SizedBox(height: 16),
                  _buildChipSection('Hobbies', _userData!['hobbies'] ?? [], Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white12),
          ],
        ),
        const SizedBox(height: 16),

        // Languages
        _buildInfoSection(
          title: 'Languages',
          items: [
            _buildChipSection('Languages', _userData!['languages'] ?? [], Colors.purple),
          ],
        ),
        const SizedBox(height: 16),

        // Account Info
        _buildInfoSection(
          title: 'Account Info',
          items: [
            _buildInfoItem(Icons.calendar_today, 'Joined', _userData!['joinedDate']),
            _buildInfoItem(Icons.access_time, 'Last Active', _userData!['lastActive']),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildQuickActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButtonCompact(
            icon: Icons.edit,
            label: 'Edit',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((updatedData) {
                if (updatedData != null) {
                  setState(() {
                    _userData = {
                      ..._userData!,
                      ...updatedData,
                    };
                    
                    // Update stats if provided in returned data
                    if (updatedData['stats'] != null) {
                      final statsData = updatedData['stats'] as Map<String, dynamic>;
                      _stats = {
                        'posts': statsData['posts']?.toString() ?? _stats['posts'] ?? '0',
                        'started': statsData['started']?.toString() ?? _stats['started'] ?? '0',
                        'passed': statsData['passed']?.toString() ?? _stats['passed'] ?? '0',
                        'matches': statsData['matches']?.toString() ?? _stats['matches'] ?? '0',
                        'likes': statsData['likes']?.toString() ?? _stats['likes'] ?? '0',
                        'superLikes': statsData['superLikes']?.toString() ?? _stats['superLikes'] ?? '0',
                      };
                    }
                  });
                }
              });
            },
          ),
          _buildActionButtonCompact(
            icon: Icons.emoji_events_outlined,
            label: 'Achievements',
            onTap: () => _showAchievements(context),
          ),
          _buildActionButtonCompact(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          _buildActionButtonCompact(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              // Implement profile sharing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share profile functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtonCompact({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyles.captionDark.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhotosTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildQuickActionRow(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: (_userData!['photoUrls'] as List).length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: (_userData!['photoUrls'] as List)[index] as String,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.person,
                        color: Colors.white38,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick action buttons
        _buildQuickActionRow(),
        const SizedBox(height: 24),
      
        _buildInfoSection(
          title: 'Activity Stats',
          items: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ProfileStatsItem(
                  count: _stats['posts'] ?? '0',
                  label: 'Posts',
                  onTap: () {},
                ),
                ProfileStatsItem(
                  count: _stats['started'] ?? '0',
                  label: 'Started',
                  onTap: () {},
                ),
                ProfileStatsItem(
                  count: _stats['passed'] ?? '0',
                  label: 'Passed',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ProfileStatsItem(
                  count: _stats['matches'] ?? '0',
                  label: 'Matches',
                  onTap: () {},
                ),
                ProfileStatsItem(
                  count: _stats['likes'] ?? '0',
                  label: 'Likes',
                  onTap: () {},
                ),
                ProfileStatsItem(
                  count: _stats['superLikes'] ?? '0',
                  label: 'Super Likes',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // More stats could be added here
        _buildStatProgress('Profile Completion', 0.85),
        const SizedBox(height: 16),
        _buildStatProgress('Response Rate', 0.72),
        const SizedBox(height: 16),
        _buildStatProgress('Activity Level', 0.68),
        
        const SizedBox(height: 32),
        
        // Achievements and Badges section
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                title: 'Achievements',
                description: 'Track your milestones',
                icon: Icons.emoji_events,
                color: Colors.amber,
                onTap: () => _showAchievements(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                title: 'Premium Badges',
                description: _userData?['premium'] == true 
                    ? 'Show off your status' 
                    : 'Unlock with Premium',
                icon: Icons.verified,
                color: _userData?['premium'] == true ? Colors.blue : Colors.grey,
                onTap: () => _showPremiumBadges(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyles.subtitle1Dark.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyles.captionDark.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatProgress(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyles.bodyText2Dark.copyWith(
                color: Colors.white70,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyles.bodyText2Dark.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern section header
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyles.subtitle1Dark.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Content without box, just a subtle left padding
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.08),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String? value) {
    final bool hasValue = value?.isNotEmpty == true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value! : 'Not specified',
                  style: TextStyle(
                    color: hasValue ? Colors.white : Colors.white38,
                    fontSize: 14,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSection(String title, List<dynamic> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIconForChipSection(title),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForItem(item.toString(), title),
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  item.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _getIconForChipSection(String title) {
    switch (title) {
      case 'Interests':
        return Icons.interests;
      case 'Hobbies':
        return Icons.sports_basketball;
      case 'Personality':
        return Icons.psychology;
      case 'Looking For':
        return Icons.favorite;
      case 'Languages':
        return Icons.language;
      default:
        return Icons.tag;
    }
  }

  IconData _getIconForItem(String item, String category) {
    // Match icons to common interests/hobbies
    if (category == 'Interests' || category == 'Hobbies') {
      if (item.toLowerCase().contains('music')) return Icons.music_note;
      if (item.toLowerCase().contains('movie') || item.toLowerCase().contains('film')) return Icons.movie;
      if (item.toLowerCase().contains('art')) return Icons.palette;
      if (item.toLowerCase().contains('book') || item.toLowerCase().contains('read')) return Icons.book;
      if (item.toLowerCase().contains('sport') || item.toLowerCase().contains('gym')) return Icons.fitness_center;
      if (item.toLowerCase().contains('travel')) return Icons.flight;
      if (item.toLowerCase().contains('cook') || item.toLowerCase().contains('food')) return Icons.restaurant;
      if (item.toLowerCase().contains('photo')) return Icons.camera_alt;
      if (item.toLowerCase().contains('game')) return Icons.sports_esports;
      if (item.toLowerCase().contains('dance')) return Icons.music_note;
      if (item.toLowerCase().contains('nature') || item.toLowerCase().contains('hike')) return Icons.terrain;
    } else if (category == 'Languages') {
      return Icons.translate;
    } else if (category == 'Personality') {
      return Icons.person;
    } else if (category == 'Looking For') {
      if (item.toLowerCase().contains('relationship')) return Icons.favorite;
      if (item.toLowerCase().contains('friend')) return Icons.people;
      if (item.toLowerCase().contains('casual')) return Icons.nightlife;
      return Icons.explore;
    }
    
    return Icons.circle;
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((updatedData) {
                      if (updatedData != null) {
                        // Calculate age from birthdate
                        final birthdate = (updatedData['birthdate'] as Timestamp?)?.toDate();
                        final age = birthdate != null 
                            ? DateTime.now().year - birthdate.year 
                            : null;

                        setState(() {
                          _userData = {
                            ..._userData!,
                            ...updatedData,
                            'name': '${updatedData['firstName']} ${updatedData['lastName']}',
                            'age': age ?? _userData!['age'],
                          };
                          
                          // Update stats if provided in returned data
                          if (updatedData['stats'] != null) {
                            final statsData = updatedData['stats'] as Map<String, dynamic>;
                            _stats = {
                              'posts': statsData['posts']?.toString() ?? _stats['posts'] ?? '0',
                              'started': statsData['started']?.toString() ?? _stats['started'] ?? '0',
                              'passed': statsData['passed']?.toString() ?? _stats['passed'] ?? '0',
                              'matches': statsData['matches']?.toString() ?? _stats['matches'] ?? '0',
                              'likes': statsData['likes']?.toString() ?? _stats['likes'] ?? '0',
                              'superLikes': statsData['superLikes']?.toString() ?? _stats['superLikes'] ?? '0',
                            };
                          }
                        });
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.white),
                  title: const Text(
                    'Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.white),
                  title: const Text(
                    'Notifications',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.white),
                  title: const Text(
                    'Privacy',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.white),
                  title: const Text(
                    'Help & Support',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.white),
                  title: const Text(
                    'About',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAchievements(BuildContext context) {
    // Sample achievements data - in a real app, this would come from Firebase
    final achievements = [
      {
        'title': 'Profile Pro',
        'description': 'Completed all profile sections',
        'icon': Icons.person_outline,
        'unlocked': true,
        'progress': 1.0,
      },
      {
        'title': 'Conversation Starter',
        'description': 'Started 10 conversations',
        'icon': Icons.chat_bubble_outline,
        'unlocked': true,
        'progress': 1.0,
      },
      {
        'title': 'Popular Profile',
        'description': 'Received 50 likes',
        'icon': Icons.favorite_border,
        'unlocked': int.parse(_stats['likes'] ?? '0') >= 50,
        'progress': int.parse(_stats['likes'] ?? '0') / 50,
      },
      {
        'title': 'Match Master',
        'description': 'Get 20 matches',
        'icon': Icons.people_outline,
        'unlocked': int.parse(_stats['matches'] ?? '0') >= 20,
        'progress': int.parse(_stats['matches'] ?? '0') / 20,
      },
      {
        'title': 'Super Swiper',
        'description': 'Swipe 100 profiles',
        'icon': Icons.swipe,
        'unlocked': (int.parse(_stats['started'] ?? '0') + int.parse(_stats['passed'] ?? '0')) >= 100,
        'progress': (int.parse(_stats['started'] ?? '0') + int.parse(_stats['passed'] ?? '0')) / 100,
      },
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Achievements',
              style: TextStyles.headline6Dark.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: achievements.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final bool unlocked = achievement['unlocked'] as bool;
                  final double progress = achievement['progress'] as double;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: unlocked 
                                ? AppColors.primary.withOpacity(0.1) 
                                : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            achievement['icon'] as IconData,
                            color: unlocked ? AppColors.primary : Colors.white54,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    achievement['title'] as String,
                                    style: TextStyles.subtitle1Dark.copyWith(
                                      color: unlocked ? Colors.white : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (unlocked)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement['description'] as String,
                                style: TextStyles.bodyText2Dark.copyWith(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    unlocked ? Colors.green : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyles.captionDark.copyWith(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              if (index < achievements.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPremiumBadges(BuildContext context) {
    if (_userData == null || _userData!['premium'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium subscription required to access badges'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }
    
    // Sample badges data - in a real app, this would come from Firebase
    final badges = [
      {
        'title': 'VIP Member',
        'description': 'Premium subscriber badge',
        'icon': Icons.star,
        'color': Colors.amber,
        'enabled': true,
      },
      {
        'title': 'Verified',
        'description': 'Verified profile badge',
        'icon': Icons.verified,
        'color': Colors.blue,
        'enabled': _userData!['isVerified'] == true,
      },
      {
        'title': 'Influencer',
        'description': 'For users with high engagement',
        'icon': Icons.trending_up,
        'color': Colors.purple,
        'enabled': int.parse(_stats['likes'] ?? '0') > 100,
      },
      {
        'title': 'Globe Trotter',
        'description': 'For users who travel frequently',
        'icon': Icons.public,
        'color': Colors.green,
        'enabled': (_userData!['favoriteTravel'] as List?)?.length ?? 0 > 3,
      },
      {
        'title': 'Matchmaker',
        'description': 'For users with many successful matches',
        'icon': Icons.favorite,
        'color': Colors.red,
        'enabled': int.parse(_stats['matches'] ?? '0') > 50,
      },
      {
        'title': 'Socialite',
        'description': 'Active social profile badge',
        'icon': Icons.groups,
        'color': Colors.orange,
        'enabled': false,
      },
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Premium Badges',
                  style: TextStyles.headline6Dark.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Display these badges on your profile to stand out',
                textAlign: TextAlign.center,
                style: TextStyles.bodyText2Dark.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  final bool enabled = badge['enabled'] as bool;
                  final Color color = badge['color'] as Color;
                  
                  return GestureDetector(
                    onTap: enabled 
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${badge['title']} badge applied to your profile!'),
                                backgroundColor: color,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${badge['title']} badge not unlocked yet'),
                                backgroundColor: Colors.grey,
                              ),
                            );
                          },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: enabled ? color.withOpacity(0.1) : Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            badge['icon'] as IconData,
                            color: enabled ? color : Colors.white38,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyles.bodyText2Dark.copyWith(
                            color: enabled ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          badge['description'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyles.captionDark.copyWith(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 