import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────
/// AppColors — Centralized brand palette
/// ──────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand
  static const Color primary   = Color(0xFF032E3F);
  static const Color navy      = Color(0xFF1A3C4A);
  static const Color teal      = Color(0xFF0D9E8A);
  static const Color tealLight = Color(0xFF1BB8A3);
  static const Color tealDark  = Color(0xFF0A7A6A);
  static const Color orange    = Color(0xFFE8631A);

  // Surfaces
  static const Color bg      = Color(0xFFEDF5F3);
  static const Color surface = Colors.white;
  static const Color border  = Color(0xFFD4E8E4);
  static const Color hint    = Color(0xFFAAB8B6);

  // Text
  static const Color textDark  = Color(0xFF032E3F);
  static const Color textMid   = Color(0xFF1A3C4A);
  static const Color textLight = Color(0xFF6B8F8A);

  // Shadows
  static BoxShadow get cardShadow => BoxShadow(
        color: primary.withOpacity(0.08),
        blurRadius: 14,
        offset: const Offset(0, 6),
      );

  static BoxShadow get tealShadow => BoxShadow(
        color: teal.withOpacity(0.25),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );
}
