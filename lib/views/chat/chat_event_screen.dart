import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/services/chat_service.dart';
import 'package:helphub/data/services/user_service.dart';
import 'package:helphub/data/models/chat_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/chat/message_input_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/services/notification_service.dart';
import '../../core/utils/constants.dart';
import '../../data/models/base_profile_model.dart';
import '../../data/models/message_model.dart';
import '../../view_models/chat/chat_view_model.dart';
import '../../widgets/chat/message_bubble_widget.dart';
import '../../widgets/chat/chat_participants_bottom_sheet.dart';
import '../../widgets/chat/event_info_bottom_sheet.dart';

class ChatEventScreen extends StatefulWidget {
  final String chatId;

  const ChatEventScreen({super.key, required this.chatId});

  @override
  State<ChatEventScreen> createState() => _ChatEventScreenState();
}

class _ChatEventScreenState extends State<ChatEventScreen> {
  final ScrollController _scrollController = ScrollController();
  late ChatViewModel _viewModel;
  final ImagePicker _imagePicker = ImagePicker();

  final Map<String, BaseProfileModel> _participantsCache = {};
  bool _isUploadingImage = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _viewModel.openChat(widget.chatId);
    _notificationService.setCurrentChatId(widget.chatId);

  }

  Future<void> _scrollToFirstUnread() async {
    if (_viewModel.currentUserId == null ||
        _viewModel.currentChat?.id == null) {
      return;
    }

    ChatService chatService = ChatService();
    final firstUnread = await chatService.getFirstUnreadMessage(
      _viewModel.currentChat!.id!,
      _viewModel.currentUserId!,
    );

    if (firstUnread != null && _viewModel.currentMessages.isNotEmpty) {
      final index = _viewModel.currentMessages.indexWhere(
        (message) => message.id == firstUnread.id,
      );

      if (index != -1) {
        await _scrollController.animateTo(
          index * 80.0, // Приблизна висота одного повідомлення
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
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
                _buildEventAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _viewModel.currentEvent?.name ?? 'Завантаження...',
                        style: TextStyleHelper.instance.title18Bold.copyWith(
                          color: appThemeColors.primaryWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${viewModel.currentChat?.participants.length ?? 0} учасників',
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.primaryWhite.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  _showEventOptions(context);
                },
                icon: Icon(
                  Icons.more_vert,
                  color: appThemeColors.primaryWhite,
                  size: 40,
                ),
              ),
            ],
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
                if (_hasUnreadMessages(viewModel))
                  _buildUnreadMessagesIndicator(viewModel),
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
                      },
                  scrollController: _scrollController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventAvatar() {
    ChatModel? currentChat = _viewModel.currentChat;
    if (_isUploadingImage) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: appThemeColors.primaryWhite, width: 2),
        ),
        child: CircularProgressIndicator(
          color: appThemeColors.primaryWhite,
          strokeWidth: 3,
        ),
      );
    }

    if (currentChat != null &&
        currentChat.chatImageUrl != null &&
        currentChat.chatImageUrl!.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: appThemeColors.primaryWhite, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            currentChat.chatImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultEventAvatar();
            },
          ),
        ),
      );
    } else {
      return _buildDefaultEventAvatar();
    }
  }

  Widget _buildDefaultEventAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: appThemeColors.lightGreenColor,
        shape: BoxShape.circle,
        border: Border.all(color: appThemeColors.primaryWhite, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [appThemeColors.lightGreenColor, appThemeColors.successGreen],
        ),
      ),
      child: Center(
        child: Icon(Icons.event, color: appThemeColors.primaryWhite, size: 28),
      ),
    );
  }

  bool _hasUnreadMessages(ChatViewModel viewModel) {
    if (viewModel.currentUserId == null) return false;

    return viewModel.currentMessages.any(
      (message) =>
          message.senderId != viewModel.currentUserId &&
          !message.isReadBy(viewModel.currentUserId!),
    );
  }

  Widget _buildUnreadMessagesIndicator(ChatViewModel viewModel) {
    final unreadCount = viewModel.currentMessages
        .where(
          (message) =>
              message.senderId != viewModel.currentUserId &&
              !message.isReadBy(viewModel.currentUserId!),
        )
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _scrollToFirstUnread,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: appThemeColors.lightGreenColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down,
                color: appThemeColors.primaryWhite,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$unreadCount нових повідомлень',
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
              'Відправте перше повідомлення в груповий чат події',
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

        bool showAvatar = true;
        if (index > 0) {
          final previousMessage = viewModel.currentMessages[index - 1];
          showAvatar = previousMessage.senderId != message.senderId;
        }

        return FutureBuilder<BaseProfileModel?>(
          future: _getParticipantProfile(message.senderId),
          builder: (context, snapshot) {
            return MessageBubble(
              message: message,
              isMine: isMine,
              senderProfile: isMine ? null : snapshot.data,
              showAvatar: showAvatar && !isMine,
              showSenderName: !isMine,
              isOrganizer:
                  message.senderId == viewModel.currentEvent!.organizerId,
            );
          },
        );
      },
    );
  }

  Future<BaseProfileModel?> _getParticipantProfile(String userId) async {
    if (_participantsCache.containsKey(userId)) {
      return _participantsCache[userId];
    }

    UserService userService = UserService();
    try {
      final profile = await userService.fetchUserProfile(userId);
      _participantsCache[userId] = profile!;
      return profile;
    } catch (e) {
      print('Error fetching participant profile: $e');
      return null;
    }
  }

  void _showEventOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appThemeColors.primaryWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appThemeColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Налаштування події',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: appThemeColors.lightGreenColor.withAlpha(30),
                child: Icon(
                  Icons.info_outline,
                  color: appThemeColors.lightGreenColor,
                ),
              ),
              title: Text(
                'Деталі події',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEventInfo(context);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: appThemeColors.blueAccent.withAlpha(30),
                child: Icon(
                  Icons.people_outline,
                  color: appThemeColors.blueAccent,
                ),
              ),
              title: Text(
                'Учасники (${_viewModel.currentChat?.participants.length ?? 0})',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showParticipants(context);
              },
            ),

            ListTile(
              leading: CircleAvatar(
                backgroundColor: appThemeColors.cyanAccent.withAlpha(30),
                child: Icon(
                  Icons.photo_camera,
                  color: appThemeColors.cyanAccent,
                ),
              ),
              title: Text(
                'Змінити фото чату',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showChatImageOptions(context);
              },
            ),
            const SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }

  void _showEventInfo(BuildContext context) {
    if (_viewModel.currentEvent == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: appThemeColors.primaryWhite,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          EventInfoBottomSheet(event: _viewModel.currentEvent!),
    );
  }

  void _showParticipants(BuildContext context) {
    if (_viewModel.currentChat == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: appThemeColors.primaryWhite,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChatParticipantsBottomSheet(
        chat: _viewModel.currentChat!,
        currentUserId: _viewModel.currentUserId!,
        organizerId: _viewModel.currentEvent!.organizerId,
      ),
    );
  }

  void _showChatImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appThemeColors.primaryWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appThemeColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Змінити фото чату',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: appThemeColors.lightGreenColor.withAlpha(30),
                child: Icon(
                  Icons.camera_alt,
                  color: appThemeColors.lightGreenColor,
                ),
              ),
              title: Text(
                'Зробити фото',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Constants.pickImageFromCamera(
                  _imagePicker,
                  context,
                  _uploadAndSetChatImage,
                  800,
                  600,
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: appThemeColors.blueAccent.withAlpha(30),
                child: Icon(
                  Icons.photo_library,
                  color: appThemeColors.blueAccent,
                ),
              ),
              title: Text(
                'Вибрати з галереї',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Constants.pickImageFromGallery(
                  _imagePicker,
                  context,
                  _uploadAndSetChatImage,
                  800,
                  600,
                );
              },
            ),
            if (_viewModel.currentChat?.chatImageUrl != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: appThemeColors.errorRed.withAlpha(30),
                  child: Icon(Icons.delete, color: appThemeColors.errorRed),
                ),
                title: Text(
                  'Видалити фото',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.errorRed,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeChatImage();
                },
              ),
            const SizedBox(height: 20,)

          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSetChatImage(File imageFile) async {
    if (_viewModel.currentChat?.id == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final fileName =
          'chat_images/${_viewModel.currentChat!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageRef = FirebaseStorage.instance.ref().child(
        fileName,
      );
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Оновлюємо чат з новим URL фото
      final success = await _viewModel.updateChatImage(
        _viewModel.currentChat!.id!,
        downloadUrl,
      );

      if (success) {
        Constants.showSuccessMessage(context, 'Фото чату успішно оновлено');
      } else {
        Constants.showErrorMessage(context, 'Помилка при оновленні фото чату');
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка завантаження фото: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _removeChatImage() async {
    if (_viewModel.currentChat?.id == null) return;

    try {
      // Видаляємо фото з Firebase Storage якщо потрібно
      if (_viewModel.currentChat!.chatImageUrl != null) {
        try {
          final Reference storageRef = FirebaseStorage.instance.refFromURL(
            _viewModel.currentChat!.chatImageUrl!,
          );
          await storageRef.delete();
        } catch (e) {
          print('Error deleting image from storage: $e');
        }
      }

      // Оновлюємо чат, видаляючи URL фото
      final success = await _viewModel.updateChatImage(
        _viewModel.currentChat!.id!,
        null,
      );

      if (success) {
        Constants.showSuccessMessage(context, 'Фото чату видалено');
      } else {
        Constants.showErrorMessage(context, 'Помилка при видаленні фото чату');
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка видалення фото: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationService.setCurrentChatId(null);
    super.dispose();
  }
}
