import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';

Widget buildBottomNavigationBar(BuildContext context, int currentIndex) {
  // TODO: Активний індекс та логіка переходу між екранами
  return BottomNavigationBar(
      currentIndex: currentIndex, onTap: (index) {
        //TODO: Реалізувати навігацію за індексом
  },
      selectedItemColor: appThemeColors.blueAccent,
      unselectedItemColor: appThemeColors.textMediumGrey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      backgroundColor: appThemeColors.primaryWhite,
      items: const[
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Події'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Проєкти'),
        BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Збори'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Календар'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чати'),
      ]);
}