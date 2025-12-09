import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';


class CustomAdminIconButton extends StatelessWidget {
  const CustomAdminIconButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.adminPanelScreen);
      },
      icon: Icon(Icons.admin_panel_settings, size: 24, color: appThemeColors.backgroundLightGrey,)
    );
  }
}