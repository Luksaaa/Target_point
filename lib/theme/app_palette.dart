import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.dartboardDark,
    required this.dartboardLight,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color primary;
  final Color primarySoft;
  final Color accent;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color dartboardDark;
  final Color dartboardLight;

  static AppPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const AppPalette(
        background: Color(0xFF0F1115),
        surface: Color(0xFF171A20),
        surfaceMuted: Color(0xFF20242C),
        primary: Color(0xFF4F8EF7),
        primarySoft: Color(0xFF1D2E47),
        accent: Color(0xFFE3A72F),
        text: Color(0xFFF4F6F8),
        textMuted: Color(0xFF9AA4B2),
        border: Color(0xFF2B313A),
        dartboardDark: Color(0xFF222222),
        dartboardLight: Color(0xFFF2E8CF),
      );
    }

    return const AppPalette(
      background: Color(0xFFF6F7F9),
      surface: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFEDEFF3),
      primary: Color(0xFF1D5FAD),
      primarySoft: Color(0xFFDCE8F7),
      accent: Color(0xFFB7791F),
      text: Color(0xFF18202A),
      textMuted: Color(0xFF687386),
      border: Color(0xFFD8DEE7),
      dartboardDark: Color(0xFF222222),
      dartboardLight: Color(0xFFF2E8CF),
    );
  }
}
