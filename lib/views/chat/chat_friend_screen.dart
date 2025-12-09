
import 'package:flutter/material.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/chat/message_input_widget.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:provider/provider.dart';

import '../../data/models/admin_model.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/message_model.dart';
import '../../data/models/organization_model.dart';
import '../../view_models/chat/chat_view_model.dart';
import '../../widgets/chat/message_bubble_widget.dart';

class ChatFriendScreen extends StatefulWidget {
  final String chatId;

  const ChatFriendScreen({super.key, required this.chatId});

  @override
  State<ChatFriendScreen> createState() => _ChatFriendScreenState();
}

class _ChatFriendScreenState extends State<ChatFriendScreen> {
  final ScrollController _scrollController = ScrollController();

  late ChatViewModel _viewModel;
  final NotificationService _notificationService = NotificationService();


  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _viewModel.openChat(widget.chatId);
    _notificationService.setCurrentChatId(widget.chatId);

  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Scaffold(
            backgroundColor: appThemeColors.blueAccent,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.9, -0.4),
                  end: Alignment(-0.9, 0.4),
                  colors: [
                    appThemeColors.blueAccent,
                    appThemeColors.cyanAccent,
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          );
        }
        final friendProfile = viewModel.friendProfile;
        return Scaffold(
          backgroundColor: appThemeColors.blueAccent,
          appBar: AppBar(
            backgroundColor: appThemeColors.appBarBg,
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back,
                size: 40,
                color: appThemeColors.primaryWhite,
              ),
            ),
            title: Row(
              children: [
                if (friendProfile != null) ...[
                  UserAvatarWithFrame(
                    size: 20,
                    role: friendProfile.role,
                    photoUrl: friendProfile.photoUrl,
                    frame: friendProfile is VolunteerModel
                        ? friendProfile.frame
                        : null,
                    uid: friendProfile.uid,
                  ),
                ] else ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: appThemeColors.grey200,
                    child: Icon(
                      Icons.person,
                      color: appThemeColors.textMediumGrey,
                      size: 20,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (friendProfile is VolunteerModel
                        ? friendProfile.fullName ??
                              friendProfile.displayName ??
                              'Волонтер'
                        : friendProfile is OrganizationModel
                        ? friendProfile
                                  .organizationName ??
                              'Фонд'
                        : friendProfile is AdminModel
                        ? (friendProfile).fullName ?? 'Адмін'
                        : 'Завантаження...'),
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.9, -0.4),
                end: Alignment(-0.9, 0.4),
                colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
              ),
            ),
            child: Column(
              children: [
                Expanded(child: _buildMessagesList(viewModel)),
                MessageInput(
                  chatId: widget.chatId,
                  onSendText: (String chatId, String text) {
                    _viewModel.sendMessage(chatId, text);
                  },
                  onSendMessage:
                      ({
                        List<String> attachments = const [],
                        required chatId,
                        required String text,
                        required MessageType type,
                      }) {
                        return _viewModel.sendMessageWithAttachments(
                          chatId: chatId,
                          text: text,
                          type: type,
                          attachments: attachments,
                        );
                      }, scrollController: _scrollController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(ChatViewModel viewModel) {
    if (viewModel.currentMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: appThemeColors.backgroundLightGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Почніть розмову',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Відправте перше повідомлення, щоб розпочати чат',
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.grey200,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: viewModel.currentMessages.length,
      itemBuilder: (context, index) {
        final message = viewModel.currentMessages[index];
        final isMine = message.senderId == viewModel.currentUserId;

        return MessageBubble(
          message: message,
          isMine: isMine,
          senderProfile: isMine ? null : viewModel.friendProfile,
          showAvatar: true,
          showSenderName: false,
          isOrganizer: false,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationService.setCurrentChatId(null);

    super.dispose();
  }
}
