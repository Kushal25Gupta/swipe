import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I edit my profile?',
      'answer': 'To edit your profile, tap on the menu button in the top right corner of your profile screen and select "Edit Profile". From there, you can update your photos, bio, and other information.',
    },
    {
      'question': 'How do I change my notification settings?',
      'answer': 'You can manage your notification preferences by going to Settings > Notifications. Here you can toggle different types of notifications on or off.',
    },
    {
      'question': 'How do I report a user?',
      'answer': 'To report a user, go to their profile, tap the menu button, and select "Report". Choose the reason for reporting and provide any additional details.',
    },
    {
      'question': 'How do I delete my account?',
      'answer': 'To delete your account, go to Settings > Privacy > Delete Account. Please note that this action cannot be undone.',
    },
    {
      'question': 'How do I change my location settings?',
      'answer': 'You can manage your location settings by going to Settings > Privacy > Location. Here you can enable or disable location sharing.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomPadding + 16,
        ),
        children: [
          // Contact Support
          _buildSection(
            title: 'Contact Support',
            children: [
              _buildSupportTile(
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'Get help via email',
                onTap: () {
                  // TODO: Open email client
                },
              ),
              _buildSupportTile(
                icon: Icons.chat,
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
                onTap: () {
                  // TODO: Open live chat
                },
              ),
              _buildSupportTile(
                icon: Icons.phone,
                title: 'Phone Support',
                subtitle: 'Call our support team',
                onTap: () {
                  // TODO: Open phone dialer
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FAQs
          _buildSection(
            title: 'Frequently Asked Questions',
            children: _faqs.map((faq) => _buildFaqTile(
              question: faq['question'],
              answer: faq['answer'],
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Resources
          _buildSection(
            title: 'Resources',
            children: [
              _buildSupportTile(
                icon: Icons.book,
                title: 'User Guide',
                subtitle: 'Learn how to use Swipe',
                onTap: () {
                  // TODO: Open user guide
                },
              ),
              _buildSupportTile(
                icon: Icons.security,
                title: 'Safety Tips',
                subtitle: 'Stay safe while using Swipe',
                onTap: () {
                  // TODO: Open safety tips
                },
              ),
              _buildSupportTile(
                icon: Icons.gavel,
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () {
                  // TODO: Open terms of service
                },
              ),
              _buildSupportTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Troubleshooting
          _buildSection(
            title: 'Troubleshooting',
            children: [
              _buildSupportTile(
                icon: Icons.bug_report,
                title: 'Report a Bug',
                subtitle: 'Help us improve the app',
                onTap: () {
                  // TODO: Open bug report form
                },
              ),
              _buildSupportTile(
                icon: Icons.sync,
                title: 'Clear Cache',
                subtitle: 'Clear app data and cache',
                onTap: () {
                  _showClearCacheDialog();
                },
              ),
              _buildSupportTile(
                icon: Icons.update,
                title: 'Check for Updates',
                subtitle: 'Update to the latest version',
                onTap: () {
                  // TODO: Check for updates
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

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
              const Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile({
    required String question,
    required String answer,
  }) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Clear Cache',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear the app cache? This will remove temporary data but won\'t affect your account.',
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
              // TODO: Implement cache clearing
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 