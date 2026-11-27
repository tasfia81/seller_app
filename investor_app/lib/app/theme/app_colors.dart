import 'package:flutter/material.dart';

/// Colour tokens — same values as the investor design canvas.
abstract final class AppColors {
  static const primary = Color(0xFF0B6B4E);
  static const primaryLight = Color(0xFF0E7A57);
  static const primaryMid = Color(0xFF0A5C42);
  static const primaryDark = Color(0xFF08452F);
  static const softGreen = Color(0xFFE4F2EB);
  static const softGreenText = Color(0xFF3C5A4D);

  static const background = Color(0xFFEDF4F0);
  static const surface = Colors.white;
  static const glassSurface = Color(0xF5FFFFFF);
  static const glassEdge = Color(0xFFD8E6DD);
  static const glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF3F9F5)],
  );
  static const backdropGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE6F2EB), Color(0xFFF5F8F6), Color(0xFFEAF4EE)],
  );
  static const textPrimary = Color(0xFF13201A);
  static const textSecondary = Color(0xFF5A6660);
  static const border = Color(0xFFE6EAE8);
  static const borderStrong = Color(0xFFD5DBD8);

  static const dark = Color(0xFF1C1F1E);
  static const onDarkMuted = Color(0xFFB5BDB9);
  static const onPrimaryMuted = Color(0xFFCDE6DA);
  static const onPrimaryGlass = Color(0x29FFFFFF); // white 16%

  static const amber = Color(0xFF8A5A12);
  static const amberSoft = Color(0xFFFBEFD9);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFDE8E6);
  static const dangerText = Color(0xFF7A2A22);
  static const dot = Color(0xFFD93A2B);

  /// Portfolio allocation colours (one per product, last = not invested).
  static const allocation = [
    Color(0xFF0B6B4E),
    Color(0xFF2C8A68),
    Color(0xFF6E8F82),
    Color(0xFFA9BFB5),
    Color(0xFFB8955A),
    Color(0xFFD5DBD8),
  ];

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryMid, primaryDark],
    stops: [0, 0.6, 1],
  );
}
