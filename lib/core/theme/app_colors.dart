import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Map<String, Color> categoryColors = {
    'social': Color(0xFF007AFF),
    'finance': Color(0xFF60BA46),
    'email': Color(0xFFF6821E),
    'shopping': Color(0xFFFFC600),
    'apps': Color(0xFFA550A7),
    'wifi': Color(0xFF60BA46),
    'personal': Color(0xFFF84F9E),
  };

  static const Color strengthStrong = Color(0xFF60BA46);
  static const Color strengthFair = Color(0xFFFFC600);
  static const Color strengthWeak = Color(0xFFFE5257);

  static Color categoryColor(String category) =>
      categoryColors[category.toLowerCase()] ?? const Color(0xFF007AFF);
}
