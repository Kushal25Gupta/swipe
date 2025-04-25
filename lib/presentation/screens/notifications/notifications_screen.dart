import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _matchesNotifications = true;
  bool _messagesNotifications = true;
  bool _likesNotifications = true;
  bool _superLikesNotifications = true;
  bool _profileViewsNotifications = true;
  bool _newFeaturesNotifications = true;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomPadding + 16,
        ),
        children: [
          // Notification Settings
          _buildSection(
            title: 'Notification Settings',
            children: [
              _buildNotificationTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications',
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
              _buildNotificationTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Receive email notifications',
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Activity Notifications
          _buildSection(
            title: 'Activity Notifications',
            children: [
              _buildNotificationTile(
                icon: Icons.people_outline,
                title: 'New Matches',
                subtitle: 'When someone matches with you',
                value: _matchesNotifications,
                onChanged: (value) {
                  setState(() {
                    _matchesNotifications = value;
                  });
                },
              ),
              _buildNotificationTile(
                icon: Icons.chat_bubble_outline,
                title: 'Messages',
                subtitle: 'When you receive a new message',
                value: _messagesNotifications,
                onChanged: (value) {
                  setState(() {
                    _messagesNotifications = value;
                  });
                },
              ),
              _buildNotificationTile(
                icon: Icons.favorite_outline,
                title: 'Likes',
                subtitle: 'When someone likes your profile',
                value: _likesNotifications,
                onChanged: (value) {
                  setState(() {
                    _likesNotifications = value;
                  });
                },
              ),
              _buildNotificationTile(
                icon: Icons.star_outline,
                title: 'Super Likes',
                subtitle: 'When someone super likes your profile',
                value: _superLikesNotifications,
                onChanged: (value) {
                  setState(() {
                    _superLikesNotifications = value;
                  });
                },
              ),
              _buildNotificationTile(
                icon: Icons.remove_red_eye_outlined,
                title: 'Profile Views',
                subtitle: 'When someone views your profile',
                value: _profileViewsNotifications,
                onChanged: (value) {
                  setState(() {
                    _profileViewsNotifications = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // App Updates
          _buildSection(
            title: 'App Updates',
            children: [
              _buildNotificationTile(
                icon: Icons.new_releases_outlined,
                title: 'New Features',
                subtitle: 'When new features are available',
                value: _newFeaturesNotifications,
                onChanged: (value) {
                  setState(() {
                    _newFeaturesNotifications = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notification History
          _buildSection(
            title: 'Recent Notifications',
            children: [
              _buildNotificationHistoryItem(
                icon: Icons.people_outline,
                title: 'New Match',
                subtitle: 'You matched with Sarah',
                time: '2 hours ago',
                color: AppColors.primary,
              ),
              _buildNotificationHistoryItem(
                icon: Icons.chat_bubble_outline,
                title: 'New Message',
                subtitle: 'Hey! How are you?',
                time: '3 hours ago',
                color: Colors.blue,
              ),
              _buildNotificationHistoryItem(
                icon: Icons.favorite_outline,
                title: 'New Like',
                subtitle: 'Someone liked your profile',
                time: '5 hours ago',
                color: Colors.pink,
              ),
              _buildNotificationHistoryItem(
                icon: Icons.star_outline,
                title: 'Super Like',
                subtitle: 'Someone super liked your profile',
                time: '1 day ago',
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.subtitle1Dark.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 