import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App logo
              const Icon(
                Icons.favorite,
                color: AppColors.primary,
                size: 80,
              ),
              const SizedBox(height: 16),
              // App name
              const Text(
                'Swipe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                'Find your perfect match',
                textAlign: TextAlign.center,
                style: TextStyles.headline6Light.copyWith(
                  color: AppColors.textLightSecondary,
                ),
              ),
              const Spacer(),
              // Get Started button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
                },
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 16),
              // Already have account button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRouter.login);
                },
                child: const Text('Already have an account? Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 