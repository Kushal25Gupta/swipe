import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _firstTimeKey = 'is_first_time';

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Show splash screen for minimum 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool(_firstTimeKey) ?? true;

      if (isFirstTime) {
        // First time user, show welcome screen and update preference
        await prefs.setBool(_firstTimeKey, false);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRouter.welcome);
      } else {
        // Returning user, show login screen
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } catch (e) {
      // If there's any error, default to welcome screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.welcome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              FadeIn(
                duration: const Duration(milliseconds: 800),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 120,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // App name
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 800),
                from: 30,
                child: const Text(
                  'Swipe',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // App tagline
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 800),
                from: 30,
                child: const Text(
                  'Swipe. Connect. Repeat.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Loading indicator
              FadeIn(
                delay: const Duration(milliseconds: 1000),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 