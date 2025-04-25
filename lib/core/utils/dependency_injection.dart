import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/services/firebase_service.dart';
import '../../config/firebase_config.dart';

/// Global service locator
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
Future<void> setupDependencies() async {
  // External services
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Core
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Firebase Services - Use the already initialized instances
  sl.registerSingleton<FirebaseAuth>(FirebaseConfig.auth);
  sl.registerSingleton<FirebaseFirestore>(FirebaseConfig.firestore);
  sl.registerSingleton<FirebaseStorage>(FirebaseConfig.storage);
  
  // Firebase Service
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
} 