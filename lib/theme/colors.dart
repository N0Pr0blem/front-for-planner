import 'package:flutter/material.dart';

class AppColors {
  // Основные цвета
  static const Color primaryDark = Color.fromARGB(255, 23, 54, 19);
  static const Color primary = Color.fromARGB(255, 50, 117, 41);
  static const Color primaryLight = Color.fromARGB(255, 21, 136, 50);
  
  // Фоновые цвета
  static const Color background = Color.fromARGB(255, 223, 223, 223);
  static const Color second_background = Color.fromARGB(255, 195, 195, 195);
  static const Color third_background = Color.fromARGB(255, 75, 75, 75);
  static const Color cardGradientStart = Color(0xFFFFFFFF);
  static const Color cardGradientEnd = Color(0xFFF4F7FB);
  static const Color cardBorder = Color(0xFFFFFFFF);
  
  // Текст
  static const Color textPrimary = Color.fromARGB(255, 23, 54, 19);
  static const Color textSecondary = Color.fromARGB(255, 10, 80, 7);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textError = Colors.red;
  static const Color textOnPrimary = Colors.white;
  
  // Тени
  static const Color shadowPrimary = Color.fromARGB(133, 133, 215, 133);
  static const Color shadowLight = Color.fromARGB(51, 207, 255, 219);
  
  // Социальные кнопки
  static const Color socialButtonStart = Colors.black;
  static const Color socialButtonEnd = Color(0xFF707070);
}

// Градиенты для удобного использования
class AppGradients {
  static const LinearGradient cardBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
  );
  
  static const LinearGradient primaryButton = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient socialButton = LinearGradient(
    colors: [AppColors.socialButtonStart, AppColors.socialButtonEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}