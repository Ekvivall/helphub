import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';

class TextStyleHelper {
  static TextStyleHelper? _instance;

  TextStyleHelper._();

  static TextStyleHelper get instance {
    _instance ??= TextStyleHelper._();
    return _instance!;
  }

  TextStyle get title32Bold => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: 'Roboto',
  );

  TextStyle get headline24SemiBold => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: appThemeColors.backgroundLightGrey,
    fontFamily: 'Roboto',
  );

  TextStyle get title20Regular => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    fontFamily: 'Roboto',
  );

  TextStyle get title18Bold => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFamily: 'Roboto',
  );

  TextStyle get title16ExtraBold => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: appThemeColors.blueAccent,
    fontFamily: 'Roboto',
  );

  TextStyle get title16Regular => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: appThemeColors.blueAccent,
    fontFamily: 'Roboto',
  );

  TextStyle get title13Regular => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: appThemeColors.blueAccent,
    fontFamily: 'Roboto',
  );

  TextStyle get title14Regular => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: appThemeColors.blueAccent,
    fontFamily: 'Roboto',
  );

  TextStyle get bodyTextRegular =>
      TextStyle(fontWeight: FontWeight.w400, fontFamily: 'Open Sans');
}
