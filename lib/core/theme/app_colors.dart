import 'package:flutter/material.dart';

class AppColors
{
  static const primary    = Color(0xFF6366F1);
  static const success    = Color(0xFF10B981);
  static const warning    = Color(0xFFF59E0B);
  static const danger     = Color(0xFFEF4444);
  static const pink       = Color(0xFFEC4899);
  static const purple     = Color(0xFF8B5CF6);
  static const blue       = Color(0xFF3B82F6);
  static const orange     = Color(0xFFFF7849);

  static Color scaffold(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color card(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color title(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color subtitle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

  static Color inputFill(BuildContext context) =>
      Theme.of(context).inputDecorationTheme.fillColor ??
          (isDark(context) ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FF));

  static Color divider(BuildContext context) =>
      Theme.of(context).dividerColor;

  static Color shadow(BuildContext context) =>
      isDark(context) ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);

  static Color cardShadow(BuildContext context) =>
      isDark(context) ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.05);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color greyText(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : Colors.grey.shade600;

  static Color greyLight(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D2D44) : Colors.grey.shade100;

  static Color greyBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D2D44) : Colors.grey.shade200;

  static Color checkboxBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF4B5563) : Colors.grey.shade300;

  static Color completedText(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : Colors.grey.shade400;

  static Color completedCard(BuildContext context) =>
      isDark(context) ? const Color(0xFF16162A) : Colors.grey.shade50;

  static Color iconBg(BuildContext context, Color color) =>
      color.withOpacity(isDark(context) ? 0.2 : 0.1);
}