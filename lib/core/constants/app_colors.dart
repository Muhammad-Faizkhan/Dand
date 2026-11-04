import 'package:flutter/material.dart';

/// Design tokens taken directly from the DAN D COLLECTION Figma file.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0406);
  static const Color backgroundPure = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF161618);
  static const Color surfaceAlt = Color(0xFF1F1F23);
  static const Color surfaceLight = Color(0xFF232326);
  static const Color navBar = Color(0xFF09090B);
  static const Color navBorder = Color(0xFF161617);
  static const Color navIndicator = Color(0xFFA2141A);
  static const Color navLabel = Color(0xFF5F5F60);
  static const Color sheet = Color(0xFF161617);
  static const Color drawer = Color(0xFF420411);

  // Brand red
  static const Color red = Color(0xFFF13A3F);
  static const Color redDark = Color(0xFFA91318);
  static const Color redSolid = Color(0xFFE4232B);
  static const Color redTint = Color(0xFF21060B);

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redDark],
  );

  static const LinearGradient redGradientH = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [red, redDark],
  );

  static const Color blueLight = Color(0xFF5470F0);

  /// The docked "+" disc: measured off the Figma frames, brightest at the
  /// bottom-left corner and darkest at the top-right.
  static const LinearGradient navAddGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF9F1319), Color(0xFFDC2128)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5470F0), Color(0xFF2B3FC4)],
  );

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9AA3);
  static const Color textTertiary = Color(0xFF6B6B70);

  // Accents
  static const Color green = Color(0xFF1BB76C);
  static const Color greenDark = Color(0xFF0E5C38);
  static const Color blue = Color(0xFF2847C0);
  static const Color teal = Color(0xFF3FA9A0);
  static const Color amber = Color(0xFFF5B301);

  // Lines
  static const Color border = Color(0x14FFFFFF);
  static const Color borderStrong = Color(0x24FFFFFF);
  static const Color redBorder = Color(0x66F13A3F);
  static const Color blueBorder = Color(0x883D5FE8);

  // Subscription tiers
  static const Color planBlue = Color(0xFF3D5FE8);
  static const Color planSilver = Color(0xFFBFBFC6);
  static const Color planGold = Color(0xFFE8B923);
  static const Color planPurple = Color(0xFF6B4FD8);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
