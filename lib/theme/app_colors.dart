import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors
  static const Color darkBg = Color(0xFF09090F);
  static const Color darkSurface = Color(0xFF140A2D);
  static const Color darkSurfaceLighter = Color(0xFF1A0A3E);
  static const Color darkBorder = Color(0xFF2A1A4A);
  
  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Brand Colors
  static const Color primary = Color(0xFFF5C518); // Golden Yellow
  static const Color primaryDark = Color(0xFFD9A815);
  static const Color secondary = Color(0xFF1A0A3E); // Deep Purple
  static const Color accent = Color(0xFFF5C518); // Golden Yellow
  static const Color danger = Color(0xFFEF4444); // Coral Red
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF5C518);

  // Text Colors
  static const Color textDarkPrimary = Color(0xFFFFFFFF);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color textLightPrimary = Color(0xFF0F172A);
  static const Color textLightSecondary = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF5C518), Color(0xFFD9A815)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF5C518), Color(0xFFD9A815)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricGradient = LinearGradient(
    colors: [Color(0xFF1A0A3E), Color(0xFF140A2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [
      Color(0xFF1A0A3E),
      Color(0xFF140A2D),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
