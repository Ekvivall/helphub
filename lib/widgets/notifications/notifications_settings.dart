
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../data/models/notification_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/notification/notification_view_model.dart';

void showNotificationsSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Consumer<NotificationViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: appThemeColors.primaryWhite,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header з drag indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: appThemeColors.textLightColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_outlined,
                      color: appThemeColors.lightGreenColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Налаштування сповіщень',
                      style: TextStyleHelper.instance.title20Regular.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Оберіть типи сповіщень, які ви хочете отримувати',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Global switch
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Увімкнути всі сповіщення',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        viewModel.toggleAllNotifications();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: viewModel.isAllNotificationsEnabled
                              ? appThemeColors.lightGreenColor
                              : appThemeColors.textLightColor,
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: viewModel.isAllNotificationsEnabled
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: appThemeColors.primaryWhite,
                              boxShadow: [
                                BoxShadow(
                                  color: appThemeColors.primaryBlack.withAlpha(
                                    13,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: viewModel.isAllNotificationsEnabled
                                ? Icon(
                              Icons.check,
                              size: 16,
                              color: appThemeColors.lightGreenColor,
                            )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Settings list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: NotificationCategory.values.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = NotificationCategory.values[index];
                    final typesInThisCategory =
                    Constants.notificationGroups[category]!;
                    final isEnabled = typesInThisCategory.every(
                          (type) => viewModel.notificationSettings[type] == true,
                    );
                    return Container(
                      decoration: BoxDecoration(
                        color: appThemeColors.backgroundLightGrey.withAlpha(
                          25,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appThemeColors.grey200,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            viewModel.updateCategorySetting(
                              category,
                              !isEnabled,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      category,
                                    ).withAlpha(85),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category),
                                    color: _getCategoryColor(category),
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Text content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getCategoryName(category),
                                        style: TextStyleHelper
                                            .instance
                                            .title16Bold
                                            .copyWith(
                                          color:
                                          appThemeColors.primaryBlack,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getCategoryDescription(category),
                                        style: TextStyleHelper
                                            .instance
                                            .title13Regular
                                            .copyWith(
                                          color: appThemeColors
                                              .textMediumGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Custom switch
                                GestureDetector(
                                  onTap: () {
                                    viewModel.updateCategorySetting(
                                      category,
                                      !isEnabled,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    width: 52,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: isEnabled
                                          ? appThemeColors.lightGreenColor
                                          : appThemeColors.textLightColor,
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      alignment: isEnabled
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: appThemeColors.primaryWhite,
                                          boxShadow: [
                                            BoxShadow(
                                              color: appThemeColors
                                                  .primaryBlack
                                                  .withAlpha(13),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: isEnabled
                                            ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: appThemeColors
                                              .lightGreenColor,
                                        )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 35),
            ],
          ),
        );
      },
    ),
  );
}

String _getCategoryName(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.messagesAndChat:
      return 'Повідомлення';
    case NotificationCategory.projectActivities:
      return 'Активності в проєктах';
    case NotificationCategory.fundraisingActivities:
      return 'Активності у зборах';
    case NotificationCategory.social:
      return 'Соціальні сповіщення';
    case NotificationCategory.accountAndSystem:
      return 'Системні та адміністративні';
    case NotificationCategory.eventActivities:
      return 'Активності в подіях';
  }
}

String _getCategoryDescription(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.messagesAndChat:
      return 'Повідомлення в чатах';
    case NotificationCategory.projectActivities:
      return 'Заявки, завдання та оновлення, пов\'язані з проєктами';
    case NotificationCategory.fundraisingActivities:
      return 'Донати, заявки, оновлення та виграші в зборах коштів';
    case NotificationCategory.social:
      return 'Запити дружби та інші соціальні взаємодії';
    case NotificationCategory.accountAndSystem:
      return 'Сповіщення про оновлення, технічні роботи, звіти та досягнення';

    case NotificationCategory.eventActivities:
      return 'Нагадування та оновлення, пов\'язані з подіями';
  }
}

IconData _getCategoryIcon(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.messagesAndChat:
      return Icons.chat_bubble_outline;
    case NotificationCategory.projectActivities:
      return Icons.assignment_outlined;
    case NotificationCategory.fundraisingActivities:
      return Icons.volunteer_activism_outlined;
    case NotificationCategory.social:
      return Icons.group_add_outlined;
    case NotificationCategory.accountAndSystem:
      return Icons.settings_applications_outlined;
    case NotificationCategory.eventActivities:
      return Icons.event_available_outlined;
  }
}

Color _getCategoryColor(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.messagesAndChat:
      return appThemeColors.blueAccent;
    case NotificationCategory.projectActivities:
      return appThemeColors.orangeAccent;
    case NotificationCategory.fundraisingActivities:
      return appThemeColors.errorRed;
    case NotificationCategory.social:
      return appThemeColors.cyanAccent;
    case NotificationCategory.accountAndSystem:
      return appThemeColors.textMediumGrey;
    case NotificationCategory.eventActivities:
      return appThemeColors.successGreen;
  }
}