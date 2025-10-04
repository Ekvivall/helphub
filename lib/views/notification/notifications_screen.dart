import 'package:flutter/material.dart';
import 'package:helphub/data/models/notification_model.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/notification/notification_view_model.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/utils/constants.dart';
import '../../theme/text_style_helper.dart';
import '../../widgets/notifications/notifications_settings.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().initialize(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Сповіщення',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, viewModel, child) {
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: appThemeColors.primaryWhite),
                color: appThemeColors.backgroundLightGrey,
                onSelected: (value) async {
                  switch (value) {
                    case 'mark_all_read':
                      await viewModel.markAllAsRead();
                      break;
                    case 'clear_all':
                      _showClearAllDialog(context, viewModel);
                      break;
                    case 'settings':
                      showNotificationsSettings(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all,
                          color: appThemeColors.textMediumGrey,
                        ),
                        const SizedBox(width: 8),
                        Text('Позначити всі як прочитані'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.clear_all,
                          color: appThemeColors.textMediumGrey,
                        ),
                        const SizedBox(width: 8),
                        Text('Очистити всі'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: appThemeColors.textMediumGrey,
                        ),
                        const SizedBox(width: 8),
                        Text('Налаштування'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.9, -0.4),
            end: const Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Consumer<NotificationViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                // Статистика
                if (viewModel.unreadCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appThemeColors.lightGreenColor.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appThemeColors.lightGreenColor.withAlpha(83),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: appThemeColors.lightGreenColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'У вас ${viewModel.unreadCount} непрочитаних сповіщень',
                          style: TextStyleHelper.instance.title14Regular
                              .copyWith(
                                color: appThemeColors.lightGreenColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                // Tabs
                TabBar(
                  labelPadding: EdgeInsets.zero,
                  controller: _tabController,
                  labelColor: appThemeColors.backgroundLightGrey,
                  unselectedLabelColor: appThemeColors.grey400,
                  indicatorColor: appThemeColors.lightGreenColor,
                  tabs: [
                    Tab(text: 'Всі (${viewModel.notifications.length})'),
                    Tab(text: 'Непрочитані (${viewModel.unreadCount})'),
                    Tab(
                      text: 'Прочитані (${viewModel.readNotifications.length})',
                    ),
                  ],
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationsList(
                        viewModel,
                        viewModel.notifications,
                      ),
                      _buildNotificationsList(
                        viewModel,
                        viewModel.unreadNotifications,
                      ),
                      _buildNotificationsList(
                        viewModel,
                        viewModel.readNotifications,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    NotificationViewModel viewModel,
    List<NotificationModel> notifications,
  ) {
    if (viewModel.isLoading && notifications.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: appThemeColors.lightGreenColor),
      );
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorWidget(viewModel);
    }

    if (notifications.isEmpty) {
      return _buildEmptyWidget();
    }

    final groupedNotifications = viewModel.getNotificationsGroupedByDate();

    return RefreshIndicator(
      color: appThemeColors.lightGreenColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedNotifications.length,
        itemBuilder: (context, index) {
          final entry = groupedNotifications.entries.elementAt(index);
          final date = entry.key;
          final dayNotifications = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  date,
                  style: TextStyleHelper.instance.title16Bold.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
              ),
              // Notifications for this date
              ...dayNotifications.map(
                (notification) =>
                    _buildNotificationItem(viewModel, notification),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
      onRefresh: () async {
        await viewModel.refresh();
      },
    );
  }

  Widget _buildNotificationItem(
    NotificationViewModel viewModel,
    NotificationModel notification,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: appThemeColors.errorRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: appThemeColors.primaryWhite),
      ),
      onDismissed: (direction) {
        viewModel.deleteNotification(notification.id);
        Constants.showSuccessMessage(context, 'Сповіщення видалено');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: appThemeColors.transparent,
          child: InkWell(
            onTap: () => viewModel.handleNotificationTap(notification, context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? appThemeColors.primaryWhite
                    : appThemeColors.blueMixedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: notification.isRead
                      ? appThemeColors.grey200
                      : appThemeColors.blueMixedColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: notification.getTypeColor().withAlpha(85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(notification.getTypeIcon(), size: 20),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyleHelper.instance.title14Regular
                                    .copyWith(
                                      color: appThemeColors.primaryBlack,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: appThemeColors.lightGreenColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          notification.body,
                          style: TextStyleHelper.instance.title13Regular
                              .copyWith(color: appThemeColors.textMediumGrey),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          timeago.format(notification.timestamp, locale: 'uk'),
                          style: TextStyleHelper.instance.title13Regular
                              .copyWith(color: appThemeColors.textMediumGrey),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: appThemeColors.textMediumGrey,
                      size: 20,
                    ),
                    color: appThemeColors.primaryWhite,
                    onSelected: (value) async {
                      switch (value) {
                        case 'mark_read':
                          await viewModel.markAsRead(notification.id);
                          break;
                        case 'delete':
                          await viewModel.deleteNotification(notification.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(
                                Icons.done,
                                color: appThemeColors.primaryBlack,
                              ),
                              const SizedBox(width: 8),
                              const Text('Позначити як прочитане'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: appThemeColors.errorRed),
                            const SizedBox(width: 8),
                            const Text('Видалити'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(NotificationViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: appThemeColors.grey400),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.lightGreenColor,
              ),
              child: Text(
                'Спробувати знову',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: appThemeColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'Немає сповіщень',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Тут з\'являться ваші сповіщення про нові повідомлення, заявки та оновлення',
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemeColors.primaryWhite,
        title: Text(
          'Очистити всі сповіщення?',
          style: TextStyleHelper.instance.title18Bold,
        ),
        content: Text(
          'Це дію не можна буде скасувати. Всі сповіщення будуть видалені назавжди.',
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.textMediumGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Скасувати',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await viewModel.clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Очистити',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
