import 'package:flutter/material.dart';

import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

class CustomNotificationIconButton extends StatelessWidget {
  const CustomNotificationIconButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            //TODO
          },
          icon: Icon(
            Icons.notifications,
            size: 24,
            color: appThemeColors.primaryWhite,
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: appThemeColors.orangeAccent,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              '1',
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.primaryWhite,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}