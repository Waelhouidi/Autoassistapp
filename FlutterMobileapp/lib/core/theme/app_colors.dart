import 'package:flutter/material.dart';

/// App Color Palette
/// Based on the specified design system
class AppColors {
  AppColors._();

  // Primary Colors (Electric Blue)
  static const Color primary = Color(0xFF3A82FF);
  static const Color primaryLight = Color(0xFF66A1FF);
  static const Color primaryDark = Color(0xFF0056D6);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF6584); // Coral Pink
  static const Color secondaryLight = Color(0xFFFF8FA4);
  static const Color secondaryDark = Color(0xFFD94A68);

  // Status Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFF58D68D);
  static const Color successDark = Color(0xFF27AE60);

  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFF7B731);
  static const Color warningDark = Color(0xFFD68910);

  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFEC7063);
  static const Color errorDark = Color(0xFFC0392B);

  // Background & Surface
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Dark Mode Background & Surface (Deep Navy)
  static const Color backgroundDark = Color(0xFF0C1120);
  static const Color surfaceDark = Color(0xFF161B2C);
  static const Color surfaceVariantDark = Color(0xFF1E2638);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textTertiary = Color(0xFFBDC3C7);

  // Dark Mode Text Colors (Near-white + Slate Grey)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF8895A7);
  static const Color textTertiaryDark = Color(0xFF64748B);

  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFECECEC);

  // Dark Mode Border & Divider
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // Priority Colors (for todos)
  static const Color priorityHigh = Color(0xFFE74C3C);
  static const Color priorityMedium = Color(0xFFF39C12);
  static const Color priorityLow = Color(0xFF2ECC71);

  // Status Colors (for todos)
  static const Color statusPending = Color(0xFF95A5A6);
  static const Color statusInProgress = Color(0xFF3498DB);
  static const Color statusCompleted = Color(0xFF2ECC71);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8A85FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF8FA4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8A85FF), Color(0xFFB8B5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
