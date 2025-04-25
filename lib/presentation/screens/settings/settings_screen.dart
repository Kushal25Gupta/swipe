import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  bool _locationEnabled = true;
  bool _showOnlineStatus = true;
  bool _showAge = true;
  bool _showDistance = true;
  String _selectedLanguage = 'English';
  String _selectedDistanceUnit = 'Miles';
  String _selectedAgeRange = '18-30';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Italian'];
  final List<String> _distanceUnits = ['Miles', 'Kilometers'];
  final List<String> _ageRanges = ['18-30', '25-35', '30-40', '35-45', '40+'];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomPadding + 16,
        ),
        children: [
          // Account Settings
          _buildSection(
            title: 'Account Settings',
            children: [
              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your profile information',
                onTap: () {
                  // TODO: Navigate to edit profile
                },
              ),
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  // TODO: Navigate to privacy screen
                },
              ),
              _buildSettingTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                onTap: () {
                  // TODO: Navigate to notifications screen
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Discovery Settings
          _buildSection(
            title: 'Discovery Settings',
            children: [
              _buildSettingTile(
                icon: Icons.location_on,
                title: 'Location',
                subtitle: 'Control your location settings',
                trailing: Switch(
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              _buildSettingTile(
                icon: Icons.people_outline,
                title: 'Show Me',
                subtitle: 'Control who you see',
                onTap: () {
                  _showAgeRangeSelector();
                },
              ),
              _buildSettingTile(
                icon: Icons.visibility,
                title: 'Show My Profile',
                subtitle: 'Control who can see your profile',
                onTap: () {
                  _showVisibilitySettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Preferences
          _buildSection(
            title: 'Preferences',
            children: [
              _buildSettingTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: _selectedLanguage,
                onTap: () {
                  _showLanguageSelector();
                },
              ),
              _buildSettingTile(
                icon: Icons.straighten,
                title: 'Distance Unit',
                subtitle: _selectedDistanceUnit,
                onTap: () {
                  _showDistanceUnitSelector();
                },
              ),
              _buildSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                trailing: Switch(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Support
          _buildSection(
            title: 'Support',
            children: [
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with your account',
                onTap: () {
                  // TODO: Navigate to help screen
                },
              ),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Learn more about Swipe',
                onTap: () {
                  // TODO: Navigate to about screen
                },
              ),
              _buildSettingTile(
                icon: Icons.logout,
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                onTap: () {
                  _showLogoutDialog();
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
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
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
            ..._languages.map((language) => ListTile(
              title: Text(
                language,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: _selectedLanguage == language
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = language;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDistanceUnitSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
            ..._distanceUnits.map((unit) => ListTile(
              title: Text(
                unit,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: _selectedDistanceUnit == unit
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedDistanceUnit = unit;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAgeRangeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
            ..._ageRanges.map((range) => ListTile(
              title: Text(
                range,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: _selectedAgeRange == range
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedAgeRange = range;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVisibilitySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              title: const Text(
                'Show Online Status',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() {
                    _showOnlineStatus = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
            ),
            ListTile(
              title: const Text(
                'Show Age',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: _showAge,
                onChanged: (value) {
                  setState(() {
                    _showAge = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
            ),
            ListTile(
              title: const Text(
                'Show Distance',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: _showDistance,
                onChanged: (value) {
                  setState(() {
                    _showDistance = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
            onPressed: () {
              // TODO: Implement logout functionality
              Navigator.pop(context);
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
} 