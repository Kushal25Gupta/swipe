import 'package:flutter/material.dart';
import 'app_colors.dart';

class TextStyles {
  // Private constructor to prevent instantiation
  TextStyles._();
  
  // Base font sizes
  static const double headline1Size = 32.0;
  static const double headline2Size = 28.0;
  static const double headline3Size = 24.0;
  static const double headline4Size = 20.0;
  static const double headline5Size = 18.0;
  static const double headline6Size = 16.0;
  static const double bodyText1Size = 16.0;
  static const double bodyText2Size = 14.0;
  static const double buttonSize = 16.0;
  static const double captionSize = 12.0;
  static const double overlineSize = 10.0;
  
  // Default Text Styles (used in both light and dark themes)
  static const TextStyle headline1 = TextStyle(
    fontSize: headline1Size,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: -1.0,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: headline2Size,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: headline3Size,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  
  static const TextStyle headline4 = TextStyle(
    fontSize: headline4Size,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  
  static const TextStyle headline5 = TextStyle(
    fontSize: headline5Size,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
  
  static const TextStyle headline6 = TextStyle(
    fontSize: headline6Size,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
  
  static const TextStyle bodyText1 = TextStyle(
    fontSize: bodyText1Size,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontSize: bodyText2Size,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: buttonSize,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: captionSize,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: overlineSize,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
    letterSpacing: 1.5,
  );
  
  // Light Theme Text Styles
  static const TextStyle headline1Light = TextStyle(
    fontSize: headline1Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
    letterSpacing: -1.0,
  );
  
  static const TextStyle headline2Light = TextStyle(
    fontSize: headline2Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline3Light = TextStyle(
    fontSize: headline3Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
  );
  
  static const TextStyle headline4Light = TextStyle(
    fontSize: headline4Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
  );
  
  static const TextStyle headline5Light = TextStyle(
    fontSize: headline5Size,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );
  
  static const TextStyle headline6Light = TextStyle(
    fontSize: headline6Size,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );
  
  static const TextStyle bodyText1Light = TextStyle(
    fontSize: bodyText1Size,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );
  
  static const TextStyle bodyText2Light = TextStyle(
    fontSize: bodyText2Size,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );
  
  static const TextStyle buttonLight = TextStyle(
    fontSize: buttonSize,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  static const TextStyle captionLight = TextStyle(
    fontSize: captionSize,
    fontWeight: FontWeight.normal,
    color: AppColors.textLightSecondary,
  );
  
  static const TextStyle overlineLight = TextStyle(
    fontSize: overlineSize,
    fontWeight: FontWeight.w500,
    color: AppColors.textLightSecondary,
    letterSpacing: 1.5,
  );
  
  // Dark Theme Text Styles
  static const TextStyle headline1Dark = TextStyle(
    fontSize: headline1Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -1.0,
  );
  
  static const TextStyle headline2Dark = TextStyle(
    fontSize: headline2Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline3Dark = TextStyle(
    fontSize: headline3Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static const TextStyle headline4Dark = TextStyle(
    fontSize: headline4Size,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static const TextStyle headline5Dark = TextStyle(
    fontSize: headline5Size,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static const TextStyle headline6Dark = TextStyle(
    fontSize: headline6Size,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static const TextStyle bodyText1Dark = TextStyle(
    fontSize: bodyText1Size,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );
  
  static const TextStyle bodyText2Dark = TextStyle(
    fontSize: bodyText2Size,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );
  
  static const TextStyle buttonDark = TextStyle(
    fontSize: buttonSize,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  static const TextStyle captionDark = TextStyle(
    fontSize: captionSize,
    fontWeight: FontWeight.normal,
    color: AppColors.textDarkSecondary,
  );
  
  static const TextStyle overlineDark = TextStyle(
    fontSize: overlineSize,
    fontWeight: FontWeight.w500,
    color: AppColors.textDarkSecondary,
    letterSpacing: 1.5,
  );

  static final TextStyle subtitle1Dark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: 0.15,
  );
} 