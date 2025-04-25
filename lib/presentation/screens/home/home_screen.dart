import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../chat/chat_list_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import 'discover_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late User? _currentUser;
  late List<Widget> _pages;
  int _unreadNotifications = 0;
  StreamSubscription<bool>? _notificationsSubscription;
  final _firebaseService = FirebaseService();
  
  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _pages = [
      if (_currentUser != null) DiscoverScreen(currentUser: _currentUser!) else const SizedBox(),
      const MatchesScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _loadUnreadNotifications() {
    if (_currentUser == null) return;
    
    _notificationsSubscription = Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => _firebaseService.hasUnreadNotifications())
        .listen((hasUnread) {
          if (mounted) {
            setState(() {
              _unreadNotifications = hasUnread ? 1 : 0;
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Main content with fade transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _pages[_currentIndex],
          ),
          
          // Custom bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 65,
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
                  _buildNavItem(
                    Icons.explore_rounded,
                    'Discover',
                    _currentIndex == 0,
                    () => _changePage(0),
                  ),
                  _buildNavItem(
                    Icons.favorite_outline_rounded,
                    'Matches',
                    _currentIndex == 1,
                    () => _changePage(1),
                  ),
                  _buildNavItem(
                    Icons.chat_bubble_outline_rounded,
                    'Messages',
                    _currentIndex == 2,
                    () => _changePage(2),
                  ),
                  _buildNavItem(
                    Icons.person_outline_rounded,
                    'Profile',
                    _currentIndex == 3,
                    () => _changePage(3),
                    badgeCount: _unreadNotifications > 0 ? _unreadNotifications : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap, {int? badgeCount}) {
    final color = isSelected ? AppColors.primary : Colors.grey[600];
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 70,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
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
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyles.captionDark.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePage(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
} 