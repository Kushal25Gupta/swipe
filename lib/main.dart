import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/dependency_injection.dart';
import 'config/firebase_config.dart';
import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('Starting app initialization...');
    
    // Load environment variables first
    try {
      await dotenv.load(fileName: '.env');
      print('Environment variables loaded successfully');
    } catch (e) {
      debugPrint('Warning: Could not load .env file. Using default values: $e');
    }
    
    // Initialize Firebase with env variables
    await FirebaseConfig.initialize();
    
    // Setup dependency injection
    await setupDependencies();
    
    runApp(const MyApp());
  } catch (e) {
    print('Critical error during app initialization: $e');
    // Even if there's an error, try to run the app
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
