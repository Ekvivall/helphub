import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';

enum NotificationType {
  chat, // Нові повідомлення в чаті
  fundraisingApplication, // Заявки на збори
  fundraisingApplicationEdit,
  projectApplication, // Заявки на проєкти
  projectApplicationEdit,
  fundraisingDonation, // Донати на збори
  reportCreated, // Створення звітів
  friendRequest, // Запити дружби
  friendRequestEdit,
  eventUpdate, // Оновлення подій
  newFundraising, // Нові збори коштів
  fundraisingCompleted, // Завершення зборів
  taskAssigned, // Призначення завдань
  taskCompleted, // Завершення завдань
  taskConfirmed,
  raffleWinner, // Виграш у розіграші
  eventReminder, // Нагадування про події
  projectDeadline, // Нагадування про дедлайн проєктів
  achievement, // Досягнення
  levelUp, // Підняття рівня
  tournamentSeasonStart, // Початок турніру
  supportReply, // Відповідь від адміністратора
  tournamentMedal, // Перемога в турніні
  general, // Загальні сповіщення
  adminNotification, // Сповіщення для адмінів
}


enum NotificationCategory {
  messagesAndChat,
  projectActivities,
  fundraisingActivities,
  eventActivities,
  social,
  game,
  accountAndSystem,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, String> data;
  final bool isRead;
  final DateTime timestamp;
  final String? imageUrl;
  final String? actionUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.timestamp,
    this.imageUrl,
    this.actionUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? timestampToDateTime(dynamic ts) {
      if (ts is Timestamp) {
        return ts.toDate();
      } else if (ts is String) {
        return DateTime.tryParse(ts);
      }
      return null;
    }

    return NotificationModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      data: Map<String, String>.from(map['data'] ?? {}),
      isRead: map['isRead'] as bool? ?? false,
      timestamp: timestampToDateTime(map['timestamp']) ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      actionUrl: map['actionUrl'] as String?,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, String>? data,
    bool? isRead,
    DateTime? timestamp,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  IconData getTypeIcon() {
    switch (type) {
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.eventUpdate:
      case NotificationType.eventReminder:
        return Icons.event_available_outlined;
      case NotificationType.projectApplication:
      case NotificationType.projectApplicationEdit:
      case NotificationType.projectDeadline:
        return Icons.assignment_outlined;
      case NotificationType.fundraisingApplication:
      case NotificationType.fundraisingApplicationEdit:
      case NotificationType.fundraisingDonation:
      case NotificationType.newFundraising:
      case NotificationType.fundraisingCompleted:
        return Icons.volunteer_activism_outlined;
      case NotificationType.reportCreated:
        return Icons.bar_chart_outlined;
      case NotificationType.friendRequest:
      case NotificationType.friendRequestEdit:
        return Icons.group_add_outlined;
      case NotificationType.taskAssigned:
      case NotificationType.taskCompleted:
      case NotificationType.taskConfirmed:
        return Icons.edit_note_outlined;
      case NotificationType.raffleWinner:
        return Icons.emoji_events_outlined;
      case NotificationType.achievement:
        return Icons.stars_outlined;
      case NotificationType.adminNotification:
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }


  Color getTypeColor(){
    switch(type){
      case NotificationType.chat:
        return appThemeColors.blueAccent;
      case NotificationType.eventUpdate:
      case NotificationType.eventReminder:
        return appThemeColors.successGreen;
      case NotificationType.projectApplication:
      case NotificationType.projectApplicationEdit:
      case NotificationType.projectDeadline:
        return appThemeColors.orangeAccent;
      case NotificationType.fundraisingApplication:
      case NotificationType.fundraisingApplicationEdit:
      case NotificationType.fundraisingDonation:
      case NotificationType.newFundraising:
      case NotificationType.fundraisingCompleted:
        return appThemeColors.errorRed;
      case NotificationType.reportCreated:
        return appThemeColors.purpleColor;
      case NotificationType.friendRequest:
      case NotificationType.friendRequestEdit:
        return appThemeColors.cyanAccent;
      case NotificationType.taskAssigned:
      case NotificationType.taskCompleted:
      case NotificationType.taskConfirmed:
        return appThemeColors.lightGreenColor;
      case NotificationType.raffleWinner:
        return appThemeColors.yellowColor;
      case NotificationType.achievement:
        return appThemeColors.goldColor;
      case NotificationType.adminNotification:
        return appThemeColors.textLightColor;
      default:
        return appThemeColors.textMediumGrey;
    }
  }
}

