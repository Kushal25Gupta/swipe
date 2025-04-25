import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _showOnlineStatus = true;
  bool _showAge = true;
  bool _showDistance = true;
  bool _showLastActive = true;
  bool _showProfileViews = true;
  bool _showActivityStatus = true;
  bool _showLocation = true;
  bool _showJob = true;
  bool _showEducation = true;
  bool _showInterests = true;
  bool _showHobbies = true;
  bool _showLanguages = true;
  bool _showRelationshipStatus = true;
  bool _showHeight = true;
  bool _showZodiacSign = true;
  bool _showPersonality = true;
  bool _showLookingFor = true;
  bool _showFavorites = true;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Privacy'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomPadding + 16,
        ),
        children: [
          // Profile Visibility
          _buildSection(
            title: 'Profile Visibility',
            children: [
              _buildPrivacyTile(
                icon: Icons.visibility,
                title: 'Show Online Status',
                subtitle: 'Let others see when you\'re online',
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() {
                    _showOnlineStatus = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.calendar_today,
                title: 'Show Age',
                subtitle: 'Display your age on your profile',
                value: _showAge,
                onChanged: (value) {
                  setState(() {
                    _showAge = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.location_on,
                title: 'Show Distance',
                subtitle: 'Show how far you are from others',
                value: _showDistance,
                onChanged: (value) {
                  setState(() {
                    _showDistance = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.access_time,
                title: 'Show Last Active',
                subtitle: 'Display when you were last active',
                value: _showLastActive,
                onChanged: (value) {
                  setState(() {
                    _showLastActive = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.remove_red_eye,
                title: 'Show Profile Views',
                subtitle: 'Let others see who viewed their profile',
                value: _showProfileViews,
                onChanged: (value) {
                  setState(() {
                    _showProfileViews = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.bolt,
                title: 'Show Activity Status',
                subtitle: 'Display your current activity',
                value: _showActivityStatus,
                onChanged: (value) {
                  setState(() {
                    _showActivityStatus = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Information
          _buildSection(
            title: 'Profile Information',
            children: [
              _buildPrivacyTile(
                icon: Icons.location_on,
                title: 'Show Location',
                subtitle: 'Display your current location',
                value: _showLocation,
                onChanged: (value) {
                  setState(() {
                    _showLocation = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.work,
                title: 'Show Job',
                subtitle: 'Display your occupation',
                value: _showJob,
                onChanged: (value) {
                  setState(() {
                    _showJob = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.school,
                title: 'Show Education',
                subtitle: 'Display your education details',
                value: _showEducation,
                onChanged: (value) {
                  setState(() {
                    _showEducation = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Personal Information
          _buildSection(
            title: 'Personal Information',
            children: [
              _buildPrivacyTile(
                icon: Icons.favorite,
                title: 'Show Interests',
                subtitle: 'Display your interests',
                value: _showInterests,
                onChanged: (value) {
                  setState(() {
                    _showInterests = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.sports,
                title: 'Show Hobbies',
                subtitle: 'Display your hobbies',
                value: _showHobbies,
                onChanged: (value) {
                  setState(() {
                    _showHobbies = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.language,
                title: 'Show Languages',
                subtitle: 'Display languages you speak',
                value: _showLanguages,
                onChanged: (value) {
                  setState(() {
                    _showLanguages = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.favorite_border,
                title: 'Show Relationship Status',
                subtitle: 'Display your relationship status',
                value: _showRelationshipStatus,
                onChanged: (value) {
                  setState(() {
                    _showRelationshipStatus = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.height,
                title: 'Show Height',
                subtitle: 'Display your height',
                value: _showHeight,
                onChanged: (value) {
                  setState(() {
                    _showHeight = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.star,
                title: 'Show Zodiac Sign',
                subtitle: 'Display your zodiac sign',
                value: _showZodiacSign,
                onChanged: (value) {
                  setState(() {
                    _showZodiacSign = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.psychology,
                title: 'Show Personality',
                subtitle: 'Display your personality traits',
                value: _showPersonality,
                onChanged: (value) {
                  setState(() {
                    _showPersonality = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.search,
                title: 'Show Looking For',
                subtitle: 'Display what you\'re looking for',
                value: _showLookingFor,
                onChanged: (value) {
                  setState(() {
                    _showLookingFor = value;
                  });
                },
              ),
              _buildPrivacyTile(
                icon: Icons.favorite,
                title: 'Show Favorites',
                subtitle: 'Display your favorite profiles',
                value: _showFavorites,
                onChanged: (value) {
                  setState(() {
                    _showFavorites = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data & Privacy
          _buildSection(
            title: 'Data & Privacy',
            children: [
              _buildPrivacyTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: () {
                  _showDeleteAccountDialog();
                },
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

  Widget _buildPrivacyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool? value,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              if (value != null && onChanged != null)
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
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
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 