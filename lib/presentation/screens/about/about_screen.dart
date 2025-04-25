import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('About'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomPadding + 16,
        ),
        children: [
          // App Logo and Info
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Swipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // App Description
          _buildSection(
            title: 'About Swipe',
            children: [
              const Text(
                'Swipe is a modern dating app that helps you find meaningful connections. Our mission is to create a safe and inclusive platform where people can meet, chat, and build relationships.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Features
          _buildSection(
            title: 'Features',
            children: [
              _buildFeatureTile(
                icon: Icons.people,
                title: 'Smart Matching',
                description: 'Find compatible matches based on your preferences and interests',
              ),
              _buildFeatureTile(
                icon: Icons.chat,
                title: 'Real-time Chat',
                description: 'Connect with your matches through instant messaging',
              ),
              _buildFeatureTile(
                icon: Icons.verified,
                title: 'Verified Profiles',
                description: 'Ensure authenticity with our verification system',
              ),
              _buildFeatureTile(
                icon: Icons.security,
                title: 'Privacy Controls',
                description: 'Control who sees your profile and information',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Social Media
          _buildSection(
            title: 'Follow Us',
            children: [
              _buildSocialTile(
                icon: Icons.facebook,
                title: 'Facebook',
                onTap: () {
                  // TODO: Open Facebook
                },
              ),
              _buildSocialTile(
                icon: Icons.camera_alt,
                title: 'Instagram',
                onTap: () {
                  // TODO: Open Instagram
                },
              ),
              _buildSocialTile(
                icon: Icons.chat_bubble,
                title: 'Twitter',
                onTap: () {
                  // TODO: Open Twitter
                },
              ),
              _buildSocialTile(
                icon: Icons.play_circle_fill,
                title: 'YouTube',
                onTap: () {
                  // TODO: Open YouTube
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Legal
          _buildSection(
            title: 'Legal',
            children: [
              _buildLegalTile(
                title: 'Terms of Service',
                onTap: () {
                  // TODO: Open Terms of Service
                },
              ),
              _buildLegalTile(
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Open Privacy Policy
                },
              ),
              _buildLegalTile(
                title: 'Cookie Policy',
                onTap: () {
                  // TODO: Open Cookie Policy
                },
              ),
              _buildLegalTile(
                title: 'Community Guidelines',
                onTap: () {
                  // TODO: Open Community Guidelines
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Credits
          _buildSection(
            title: 'Credits',
            children: [
              const Text(
                '© 2024 Swipe. All rights reserved.\n\n'
                'Made with ❤️ by the Swipe team.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
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

  Widget _buildLegalTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
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
} 