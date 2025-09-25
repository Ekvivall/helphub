
import 'package:flutter/material.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

Widget buildSettingsItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
    ) {
  return Material(
    color: appThemeColors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appThemeColors.backgroundLightGrey.withAlpha(127),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 20,
                color: appThemeColors.textMediumGrey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: appThemeColors.textMediumGrey,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
