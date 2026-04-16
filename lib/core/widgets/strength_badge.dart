import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PasswordStrength { weak, fair, strong }

PasswordStrength strengthFromScore(int score) {
  if (score >= 70) return PasswordStrength.strong;
  if (score >= 40) return PasswordStrength.fair;
  return PasswordStrength.weak;
}

class StrengthBadge extends StatelessWidget {
  final PasswordStrength strength;

  const StrengthBadge({super.key, required this.strength});

  factory StrengthBadge.fromScore(int score) =>
      StrengthBadge(strength: strengthFromScore(score));

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (strength) {
      PasswordStrength.strong => ('Strong', AppColors.strengthStrong),
      PasswordStrength.fair => ('Fair', AppColors.strengthFair),
      PasswordStrength.weak => ('Weak', AppColors.strengthWeak),
    };
    return Chip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
