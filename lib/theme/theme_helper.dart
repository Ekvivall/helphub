import 'package:flutter/material.dart';

ThemeHelper _themeHelper = ThemeHelper();

LightCodeColors get appThemeColors => _themeHelper.themeColor();

ThemeData get appThemeData => _themeHelper.themeData();

class ThemeHelper {
  LightCodeColors themeColor() {
    return LightCodeColors();
  }

  ThemeData themeData() {
    var colorScheme = ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
    );
  }
}

class ColorSchemes {
  static final lightCodeColorScheme = ColorScheme.light();
}

class LightCodeColors {
  Color get transparent => Colors.transparent;
  Color get primaryBlack => const Color(0xFF1E1E1E);

  Color get primaryWhite => const Color(0xFFFFFFFF);

  Color get primaryGray400 => const Color(0xFF9CA3AF);

  Color get blueAccent => const Color(0xFF2E6FD3);

  Color get cyanAccent => const Color(0xFF55B3D9);

  Color get backgroundLightGrey => const Color(0xFFF5F5F5);

  Color get textMediumGrey => const Color(0xFF757575);

  Color get textTransparentBlack => const Color(0x40000000);

  Color get errorRed => const Color(0xFFFF5252);

  Color get successGreen => const Color(0xFF4CAF50);

  Color get orangeAccent => const Color(0xFFFF6B2C);

  Color get orangeLight => const Color(0x33FF6B2C);

  Color get blueTransparent => const Color(0x7FF8F9FA);

  Color get grey400 => Colors.grey.shade400;

  Color get grey200 => Colors.grey.shade200;

  Color get grey100 => Colors.grey.shade100;

  Color get appBarBg => const Color(0x66757575).withAlpha(70);

  Color get bottomBg => const Color(0xFF2E6FD3).withAlpha(90);

  Color get blueMixedColor => const Color(0xFFCDDAEE);

  Color get lightGreenColor => const Color(0xFFCDDC39);
}
