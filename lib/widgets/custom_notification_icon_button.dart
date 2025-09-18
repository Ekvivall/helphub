import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/view_models/notification/notification_view_model.dart';
import 'package:provider/provider.dart';

import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

class CustomNotificationIconButton extends StatelessWidget {
  const CustomNotificationIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, viewModel, child) {
        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.notificationsScreen);
              },
              icon: Icon(
                Icons.notifications,
                size: 24,
                color: appThemeColors.primaryWhite,
              ),
            ),
            // Badge з кількістю непрочитаних нотифікацій
            if (viewModel.unreadCount > 0)
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
                    viewModel.unreadCount > 99
                        ? '99+'
                        : '${viewModel.unreadCount}',
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
      },
    );
  }
}
