import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helphub/core/services/chat_service.dart';
import 'package:helphub/core/services/user_service.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/widgets/chat/message_input_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:helphub/models/project_task_model.dart';
import 'package:helphub/view_models/chat/chat_view_model.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/utils/constants.dart';
import '../../models/message_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/chat/chat_task_view_model.dart';
import '../../widgets/chat/chat_participants_bottom_sheet.dart';
import '../../widgets/chat/message_bubble_widget.dart';
import '../../widgets/chat/project_info_bottom_sheet.dart';
import '../../widgets/chat/task_list_tab_view.dart';

enum DisplayMode { chat, tasks }

class ChatProjectScreen extends StatefulWidget {
  final String chatId;
  final DisplayMode initialDisplayMode;

  const ChatProjectScreen({
    super.key,
    required this.chatId,
    required this.initialDisplayMode,
  });

  @override
  State<ChatProjectScreen> createState() => _ChatProjectScreenState();
}

class _ChatProjectScreenState extends State<ChatProjectScreen> {
  late DisplayMode _displayMode;
  late ChatViewModel _viewModel;
  late ChatTaskViewModel _taskViewModel;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;
  final Map<String, BaseProfileModel> _participantsCache = {};
  final NotificationService _notificationService = NotificationService();


  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _taskViewModel = Provider.of<ChatTaskViewModel>(context, listen: false);
    _displayMode = widget.initialDisplayMode;
    _initializeChat();
    _notificationService.setCurrentChatId(widget.chatId);

  }

  Future<void> _initializeChat() async {
    await _viewModel.openChat(widget.chatId);
    if (_viewModel.currentChat?.entityId != null) {
      _taskViewModel.listenToProjectTasks(_viewModel.currentChat!.entityId!);
    }
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
          index * 80,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
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

  Widget _buildChatAvatar(ChatTaskViewModel viewModel) {
    final chat = _viewModel.currentChat;

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

    if (chat?.chatImageUrl != null && chat!.chatImageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showChatImageOptions(context),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: appThemeColors.primaryWhite, width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              chat.chatImageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: appThemeColors.cyanAccent,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: appThemeColors.primaryWhite,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar(viewModel);
              },
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _showChatImageOptions(context),
        child: _buildDefaultAvatar(viewModel),
      );
    }
  }

  Widget _buildDefaultAvatar(ChatTaskViewModel viewModel) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: appThemeColors.cyanAccent,
        shape: BoxShape.circle,
        border: Border.all(color: appThemeColors.primaryWhite, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [appThemeColors.cyanAccent, appThemeColors.blueAccent],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.work,
              color: appThemeColors.primaryWhite,
              size: 28,
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: appThemeColors.primaryWhite,
                shape: BoxShape.circle,
                border: Border.all(color: appThemeColors.cyanAccent, width: 1),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 12,
                color: appThemeColors.cyanAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatViewModel, ChatTaskViewModel>(
      builder: (context, chatViewModel, taskViewModel, child) {
        if (chatViewModel.isLoading ||
            taskViewModel.isLoading && taskViewModel.project == null) {
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

        final totalNeededPeople = taskViewModel.project?.tasks
            ?.map((task) => task.neededPeople ?? 0)
            .fold<int>(0, (sum, count) => sum + count);
        final totalVolunteers = taskViewModel.project?.tasks
            ?.map((task) => task.assignedVolunteerIds?.length ?? 0)
            .fold<int>(0, (sum, count) => sum + count);

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
                _buildChatAvatar(taskViewModel),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskViewModel.project?.title ?? 'Завантаження...',
                        style: TextStyleHelper.instance.title18Bold.copyWith(
                          color: appThemeColors.primaryWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${totalVolunteers ?? 0}/${totalNeededPeople ?? 0} учасників',
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
                  _showProjectOptions(context, taskViewModel);
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
                _buildStatusInfoBar(context, taskViewModel),
                _buildDisplayModeToggle(context),
                const SizedBox(height: 8),
                Expanded(
                  child: _displayMode == DisplayMode.chat
                      ? _buildChatContent(chatViewModel)
                      : TaskListTabView(viewModel: taskViewModel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatContent(ChatViewModel chatViewModel) {
    return Column(
      children: [
        if (_hasUnreadMessages(chatViewModel))
          _buildUnreadMessagesIndicator(chatViewModel),
        Expanded(child: _buildMessagesList(chatViewModel)),
        MessageInput(
          chatId: widget.chatId,
          onSendText: (String chatId, String text){
            chatViewModel.sendMessage(chatId, text);
          },
          onSendMessage: ({
            List<String> attachments = const [],
            required String chatId,
            required String text,
            required MessageType type,
          }) {
            return chatViewModel.sendMessageWithAttachments(
              chatId: chatId,
              text: text,
              type: type,
              attachments: attachments,
            );
          },
          scrollController: _scrollController,
        ),
      ],
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
              'Відправте перше повідомлення в груповий чат проєкту',
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
                  message.senderId == _taskViewModel.project?.organizerId,
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
      if (profile != null) {
        _participantsCache[userId] = profile;
      }
      return profile;
    } catch (e) {
      print('Error fetching participant profile: $e');
      return null;
    }
  }

  Widget _buildDisplayModeToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appThemeColors.grey100, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _displayMode = DisplayMode.chat;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _displayMode == DisplayMode.chat
                      ? appThemeColors.blueMixedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Чат',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _displayMode == DisplayMode.chat
                          ? appThemeColors.primaryBlack
                          : appThemeColors.textMediumGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _displayMode = DisplayMode.tasks;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _displayMode == DisplayMode.tasks
                      ? appThemeColors.blueMixedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Завдання',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _displayMode == DisplayMode.tasks
                          ? appThemeColors.primaryBlack
                          : appThemeColors.textMediumGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoBar(
    BuildContext context,
    ChatTaskViewModel viewModel,
  ) {
    final project = viewModel.project;
    if (project == null) return const SizedBox.shrink();

    // Розрахунок прогресу
    final totalTasks = project.tasks?.length;
    final completedTasks = project.tasks
        ?.where((t) => t.status == TaskStatus.confirmed)
        .length;
    final double progress = totalTasks! > 0
        ? completedTasks! / totalTasks
        : 0.0;

    // Розрахунок кількості днів до завершення
    final daysLeft = project.endDate?.difference(DateTime.now()).inDays;
    String daysLeftText;
    if (daysLeft! < 0) {
      daysLeftText = 'Проєкт завершено';
    } else if (daysLeft == 0) {
      daysLeftText = 'Останній день';
    } else if (daysLeft == 1) {
      daysLeftText = '$daysLeft день до завершення';
    } else if (daysLeft < 5) {
      daysLeftText = '$daysLeft дні до завершення';
    } else {
      daysLeftText = '$daysLeft днів до завершення';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem(
                Icons.check_circle_outline_rounded,
                'Виконано: ${project.tasks?.where((t) => t.status == TaskStatus.confirmed).length}/${project.tasks?.length} завдань',
              ),
              _buildStatusItem(Icons.calendar_today_outlined, daysLeftText),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(progress),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: appThemeColors.backgroundLightGrey, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 8,
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey.withAlpha(76),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: appThemeColors.successGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  void _showProjectOptions(BuildContext context, ChatTaskViewModel viewModel) {
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
              'Налаштування проєкту',
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
                'Інформація про проєкт',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showProjectInfo(context, viewModel);
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

  void _showProjectInfo(BuildContext context, ChatTaskViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appThemeColors.primaryWhite,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProjectInfoBottomSheet(project: viewModel.project!),
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
        organizerId: _taskViewModel.project!.organizerId!,
      ),
    );
  }

  @override
  void dispose() {
    _notificationService.setCurrentChatId(null);

    super.dispose();
  }
}
