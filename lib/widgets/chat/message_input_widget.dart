import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/constants.dart';
import '../../models/message_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

class MessageInput extends StatefulWidget {
  final String chatId;
  final Function(String, String) onSendText;
  final Future<bool> Function({
    List<String> attachments,
    required String chatId,
    required String text,
    required MessageType type,
  })
  onSendMessage;
  final bool isSending;
  final String hintText;
  final ScrollController scrollController;

  const MessageInput({
    super.key,
    required this.chatId,
    required this.onSendText,
    required this.onSendMessage,
    this.isSending = false,
    this.hintText = 'Введіть повідомлення...',
    required this.scrollController,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingFile = false;

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      widget.onSendText(widget.chatId, text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: appThemeColors.primaryWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            Text(
              'Прикріпити файл',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 20),
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
                  _uploadAndSendImage,
                  1024,
                  1024,
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
                  _uploadAndSendImage,
                  1024,
                  1024,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    setState(() {
      _isUploadingFile = true;
    });
    try {
      final fileName =
          'chat_attachments/${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        fileName,
      );
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      // Відправляє повідомлення з прикріпленням
      final success = await widget.onSendMessage(
        chatId: widget.chatId,
        text: '',
        type: MessageType.image,
        attachments: [downloadUrl],
      );
      if (success) {
        _scrollToBottom();
      } else {
        Constants.showErrorMessage(context, 'Помилка при відправці фото');
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка завантаження фото: $e');
    } finally {
      setState(() {
        _isUploadingFile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _isUploadingFile ? null : _showAttachmentOptions,
              icon: _isUploadingFile
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: appThemeColors.blueAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.attach_file, color: appThemeColors.blueAccent),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: appThemeColors.backgroundLightGrey,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.isSending ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: appThemeColors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: widget.isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: appThemeColors.primaryWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: appThemeColors.primaryWhite,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
