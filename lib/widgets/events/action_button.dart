import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';

import '../../data/models/event_model.dart';
import '../../data/services/event_service.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/event/event_view_model.dart';
import '../custom_elevated_button.dart';

Widget buildActionButton(
  BuildContext context,
  EventViewModel viewModel,
  EventModel event,
  String currentUserId,
  bool isOrganizer,
  bool isParticipant,
  bool isEventFinished,
  bool isFull,
) {
  String buttonText;
  Color buttonColor;
  VoidCallback? onPressed;

  if (isEventFinished) {
    buttonText = 'Подія завершена';
    buttonColor = appThemeColors.textLightColor;
    onPressed = null;
  } else if (isOrganizer || isParticipant) {
    // Організатор завжди бачить кнопку "Чат події"
    buttonText = 'Чат події';
    buttonColor = appThemeColors.blueAccent;
    onPressed = () async {
      final eventService = EventService();
      String? chatId = await eventService.getEventChatId(event.id!);

      if (chatId != null) {
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.chatEventScreen, arguments: chatId);
      }
    };
  } else if (isFull) {
    buttonText = 'Місць немає';
    buttonColor = appThemeColors.textLightColor;
    onPressed = null;
  } else {
    // Користувач не організатор, не учасник і є місця
    buttonText = viewModel.isJoiningLeaving ? 'В процесі...' : 'Долучитися';
    buttonColor = appThemeColors.successGreen;
    onPressed = viewModel.isJoiningLeaving
        ? null
        : () async {
            final result = await viewModel.joinEvent(event, currentUserId);
            if (result != null) {
              Constants.showErrorMessage(context, 'Помилка: $result');
            }
          };
  }

  return CustomElevatedButton(
    text: buttonText,
    onPressed: onPressed,
    backgroundColor: buttonColor,
    width: 150,
    height: 48,
    textStyle: TextStyleHelper.instance.title16Bold.copyWith(
      color: appThemeColors.primaryWhite,
    ),
  );
}
