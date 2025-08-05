import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';

Widget buildBottomNavigationBar(
    BuildContext context,
    int currentIndex,
    ) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: (index) {
      switch (index) {
        case 0:
        // Екран "Події"
          Navigator.pushReplacementNamed(context, AppRoutes.eventListScreen);
          break;
        case 1:
        // Екран "Проєкти"
          Navigator.pushReplacementNamed(context, AppRoutes.createProjectScreen, arguments: '');
          break;
        case 2:
        // Екран "Збори"
          /*Navigator.pushReplacementNamed(
            context,
            AppRoutes.fundraisingListScreen,
          );*/
          break;
        case 3:
        // Екран "Календар"
          //Navigator.pushReplacementNamed(context, AppRoutes.calendarScreen);
          break;
        case 4:
        // Екран "Чати"
          //Navigator.pushReplacementNamed(context, AppRoutes.chatListScreen);
          break;
      }
    },
    selectedItemColor: appThemeColors.blueAccent,
    unselectedItemColor: appThemeColors.textMediumGrey,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    backgroundColor: appThemeColors.primaryWhite,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: 'Події',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment),
        label: 'Проєкти',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.monetization_on),
        label: 'Збори',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month),
        label: 'Календар',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: 'Чати',
      ),
    ],
  );
}