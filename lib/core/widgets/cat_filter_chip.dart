import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CatFilterChip extends StatelessWidget {
  final String category;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const CatFilterChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category);
    return FilterChip(
      label: Text(category[0].toUpperCase() + category.substring(1)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      side: selected ? BorderSide(color: color) : null,
    );
  }
}
