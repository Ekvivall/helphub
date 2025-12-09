import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:provider/provider.dart';

import '../view_models/chat/chat_view_model.dart';

Widget buildBottomNavigationBar(BuildContext context, int currentIndex) {
  return Consumer<ChatViewModel>(
    builder: (context, chatViewModel, child) {
      final unreadCount = chatViewModel.totalUnreadCount;
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              // Екран "Події"
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.eventListScreen,
              );
              break;
            case 1:
              // Екран "Проєкти"
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.projectListScreen,
              );
              break;
            case 2:
              // Екран "Збори"
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.fundraisingListScreen,
              );
              break;
            case 3:
              // Екран "Календар"
              Navigator.pushReplacementNamed(context, AppRoutes.calendarScreen);
              break;
            case 4:
              // Екран "Чати"
              Navigator.pushReplacementNamed(context, AppRoutes.chatListScreen);
              break;
            case 5:
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.adminPanelScreen,
              );
              break;
          }
        },
        selectedItemColor: appThemeColors.blueAccent,
        unselectedItemColor: appThemeColors.textMediumGrey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: appThemeColors.primaryWhite,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Події',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Проєкти',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Збори',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Календар',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: appThemeColors.orangeAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Чати',
          ),
        ],
      );
    },
  );
}
