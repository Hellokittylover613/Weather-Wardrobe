import 'package:flutter/material.dart';

/// Shared colors + gradients for the whole app.
/// Keeping these in one place means every screen matches
/// the same style — change values here, not in individual screens.
class AppColors {
  static const Color bgTop = Color(0xFFFFFFFF); // white
  static const Color bgBottom = Color(0xFFEDF1F5); // soft grey
  static const Color coral = Color(0xFF6FA8DC); // primary blue (was coral)
  static const Color teal = Color(0xFF3D5A80); // deep navy blue (was teal)
  static const Color plum = Color(0xFF2B3A55); // dark navy text (was plum)
  static const Color hintGrey = Color(0xFFB0B8C1);
  static const Color cardWhite = Colors.white;

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );
}
