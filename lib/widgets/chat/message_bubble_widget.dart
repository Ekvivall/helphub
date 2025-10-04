import 'package:flutter/material.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/data/models/message_model.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';

import '../../data/models/organization_model.dart';
import '../../theme/text_style_helper.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final BaseProfileModel? senderProfile;
  final bool showAvatar;
  final bool showSenderName;
  final bool isOrganizer;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.senderProfile,
    this.showAvatar = true,
    this.showSenderName = false,
    required this.isOrganizer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && showAvatar) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ] else if (!isMine && !showAvatar) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMine
                    ? appThemeColors.cyanAccent
                    : appThemeColors.primaryWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSenderName && !isMine && senderProfile != null) ...[
                    Text.rich(
                      TextSpan(
                        text: (senderProfile is VolunteerModel
                            ? (senderProfile as VolunteerModel).fullName ??
                                  (senderProfile as VolunteerModel)
                                      .displayName ??
                                  'Волонтер'
                            : senderProfile is OrganizationModel
                            ? (senderProfile as OrganizationModel)
                                      .organizationName ??
                                  'Фонд'
                            : 'Завантаження...'),
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          if (isOrganizer)
                            TextSpan(
                              text: '  (Організатор)',
                              style: TextStyleHelper.instance.title13Regular
                                  .copyWith(
                                    color: appThemeColors.blueAccent,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (message.type == MessageType.image &&
                      message.attachments.isNotEmpty)
                    _buildImageAttachment(message.attachments.first),
                  if (message.text.isNotEmpty) ...[
                    if (message.type == MessageType.image)
                      const SizedBox(height: 8),
                    Text(
                      message.text,
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: isMine
                            ? appThemeColors.primaryWhite
                            : appThemeColors.primaryBlack,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: isMine
                              ? appThemeColors.primaryWhite.withAlpha(180)
                              : appThemeColors.grey400,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead
                              ? appThemeColors.lightGreenColor
                              : appThemeColors.primaryWhite.withAlpha(180),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (senderProfile != null) {
      return UserAvatarWithFrame(
        size: 16,
        role: senderProfile!.role,
        photoUrl: senderProfile!.photoUrl,
        frame: senderProfile is VolunteerModel
            ? (senderProfile as VolunteerModel).frame
            : null,
        uid: senderProfile!.uid!,
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: appThemeColors.grey200,
        child: Icon(
          Icons.person,
          color: appThemeColors.textMediumGrey,
          size: 16,
        ),
      );
    }
  }

  Widget _buildImageAttachment(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 200,
            color: appThemeColors.grey200,
            child: Center(
              child: CircularProgressIndicator(
                color: appThemeColors.blueAccent,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: appThemeColors.grey200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: appThemeColors.errorRed,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Не вдалося завантажити',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчора';
    } else if (difference.inDays < 7) {
      const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    }
  }
}
