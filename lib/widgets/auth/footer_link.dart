
import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

Widget buildFooterLink(BuildContext context) {
  return Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Вже маєте обліковий запис? ',
          style: TextStyleHelper.instance.title16Regular.copyWith(
            height: 1.2,
            color: appThemeColors.textMediumGrey,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen),
          child: Text(
            'Увійти',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              height: 1.2,
              color: appThemeColors.blueAccent,
              decoration: TextDecoration.underline,
              decorationColor: appThemeColors.blueAccent,
            ),
          ),
        ),
      ],
    ),
  );
}