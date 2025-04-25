import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Brand Colors
  static const Color primary = Color(0xFFFF3A5A);
  static const Color secondary = Color(0xFF6C63FF);
  static const Color tertiary = Color(0xFF00D9DA);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Light Theme
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF212121);
  static const Color textLightSecondary = Color(0xFF757575);
  static const Color dividerLight = Color(0xFFDDDDDD);
  static const Color inputBackgroundLight = Color(0xFFF5F5F5);
  static const Color borderLight = Color(0xFFE0E0E0);
  
  // Dark Theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFEEEEEE);
  static const Color textDarkSecondary = Color(0xFFAAAAAA);
  static const Color dividerDark = Color(0xFF3A3A3A);
  static const Color inputBackgroundDark = Color(0xFF2C2C2C);
  
  // Match and Swipe Indicators
  static const Color matchGreen = Color(0xFF43A047);
  static const Color swipeRed = Color(0xFFE53935);
  static const Color superLikeBlue = Color(0xFF1E88E5);
  
  // Premium Features
  static const Color goldPremium = Color(0xFFFFD700);
  static const Color platinumPremium = Color(0xFFE5E4E2);
  
  // Gradient
  static const List<Color> primaryGradient = [
    Color(0xFFFF3A5A),
    Color(0xFFFF7676),
  ];
} 