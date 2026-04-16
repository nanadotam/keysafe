import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 40});

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return Symbols.people;
      case 'finance':
        return Symbols.account_balance;
      case 'email':
        return Symbols.email;
      case 'shopping':
        return Symbols.shopping_bag;
      case 'apps':
        return Symbols.apps;
      case 'wifi':
        return Symbols.wifi;
      case 'personal':
        return Symbols.person;
      default:
        return Symbols.key_vertical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(_iconFor(category), color: color, size: size * 0.55),
    );
  }
}
