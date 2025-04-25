import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;
  static bool _isInitialized = false;

  static FirebaseAuth get auth {
    if (_auth == null) {
      _auth = FirebaseAuth.instance;
    }
    return _auth!;
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      _firestore = FirebaseFirestore.instance;
    }
    return _firestore!;
  }

  static FirebaseStorage get storage {
    if (_storage == null) {
      _storage = FirebaseStorage.instance;
    }
    return _storage!;
  }

  static Future<void> initialize() async {
    try {
      print('Starting Firebase initialization...');
      
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        print('Firebase is already initialized, using existing instance');
        print('Current Firebase apps: ${Firebase.apps.length}');
        _initializeInstances();
        return;
      }
      
      print('Initializing new Firebase instance...');
      
      // Get values from environment variables
      final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? 
          "AIzaSyCfqqcVNkx91weECAivEctgmht6hR9DlMo"; // Fallback for development
      final appId = dotenv.env['FIREBASE_APP_ID'] ?? 
          "1:106877368066:android:1d1b4c5f9636e46db4741b"; // Fallback for development
      final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 
          "106877368066"; // Fallback for development
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? 
          "destined-32484"; // Fallback for development
      final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 
          "destined-32484.appspot.com"; // Fallback for development
      
      final options = FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );
      
      print('Initializing with options from environment variables');
      await Firebase.initializeApp(options: options);
      print('Firebase initialized successfully');
      
      // Initialize instances with verification
      print('Initializing Firebase services...');
      _auth = FirebaseAuth.instance;
      print('Auth instance created');
      
      _firestore = FirebaseFirestore.instance;
      print('Firestore instance created');
      
      _storage = FirebaseStorage.instance;
      print('Storage instance created');
      
      _isInitialized = true;
      print('All Firebase services initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      print('Continuing with app initialization despite Firebase error');
    }
  }

  static void _initializeInstances() {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _isInitialized = true;
    print('Firebase services initialized');
  }
} 