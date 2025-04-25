import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/onboarding/profile_setup_screen.dart';
import '../presentation/screens/onboarding/welcome_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String profile = '/profile';

  // Route generator
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case profileSetup:
        return MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
          settings: const RouteSettings(name: profileSetup),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: const RouteSettings(name: home),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 