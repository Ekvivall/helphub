import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:helphub/models/project_task_model.dart';
import 'package:helphub/view_models/chat/chat_view_model.dart';
import 'package:provider/provider.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/chat/chat_task_view_model.dart';
import '../../widgets/chat/chat_participants_bottom_sheet.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _viewModel.openChat(widget.chatId);
    _displayMode = widget.initialDisplayMode;
    ChatTaskViewModel chatTaskViewModel = Provider.of<ChatTaskViewModel>(
      context,
      listen: false,
    );
    chatTaskViewModel.listenToProjectTasks(_viewModel.currentChat!.entityId!);
    _displayMode = widget.initialDisplayMode;
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
                _pickImageFromCamera();
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
                _pickImageFromGallery();
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
          ],
        ),
      ),
    );
  }

  void _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAndSetChatImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Помилка при зйомці фото: $e');
    }
  }

  void _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadAndSetChatImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Помилка при виборі фото: $e');
    }
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
        _showSuccessSnackBar('Фото чату успішно оновлено');
      } else {
        _showErrorSnackBar('Помилка при оновленні фото чату');
      }
    } catch (e) {
      _showErrorSnackBar('Помилка завантаження фото: $e');
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
        _showSuccessSnackBar('Фото чату видалено');
      } else {
        _showErrorSnackBar('Помилка при видаленні фото чату');
      }
    } catch (e) {
      _showErrorSnackBar('Помилка видалення фото: $e');
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
    return Consumer<ChatTaskViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.project == null) {
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

        final totalNeededPeople = viewModel.project?.tasks
            ?.map((task) => task.neededPeople ?? 0)
            .fold<int>(0, (sum, count) => sum + count);
        final totalVolunteers = viewModel.project?.tasks
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
                _buildChatAvatar(viewModel),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.project?.title ?? '',
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
                  _showProjectOptions(context, viewModel);
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
                _buildStatusInfoBar(context, viewModel),
                _buildDisplayModeToggle(context),
                const SizedBox(height: 8),
                Expanded(
                  child: _displayMode == DisplayMode.chat
                      ? Center(
                          child: Text(
                            'Тут буде віджет чату',
                            style: TextStyleHelper.instance.title16Regular
                                .copyWith(
                                  color: appThemeColors.backgroundLightGrey,
                                ),
                          ),
                        )
                      : TaskListTabView(viewModel: viewModel),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appThemeColors.errorRed,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appThemeColors.successGreen,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
