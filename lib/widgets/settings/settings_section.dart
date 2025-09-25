
import 'package:flutter/material.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

Widget buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> items,
    ) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
          ],
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: appThemeColors.primaryWhite.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: appThemeColors.primaryWhite.withAlpha(125),
          ),
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                item,
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    color: appThemeColors.grey200,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );
}
