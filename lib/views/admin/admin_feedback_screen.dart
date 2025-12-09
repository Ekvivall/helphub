import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/admin/admin_view_model.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/utils/constants.dart';
import '../../data/models/feedback_model.dart';
import '../../theme/text_style_helper.dart';
import '../../widgets/custom_text_field.dart';

class AdminFeedbackScreen extends StatelessWidget {
  const AdminFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Зворотній зв\'язок',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
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
        child: Consumer<AdminViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoadingFeedback) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.backgroundLightGrey,
                ),
              );
            }
            if (viewModel.feedback.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.feedback,
                      size: 64,
                      color: appThemeColors.backgroundLightGrey.withAlpha(150),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Немає відгуків',
                      style: TextStyleHelper.instance.title18Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.feedback.length,
              itemBuilder: (context, index) {
                final feedback = viewModel.feedback[index];
                return _buildFeedbackCard(feedback, viewModel, context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback,
      AdminViewModel viewModel,
      BuildContext context,) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (feedback.status) {
      case FeedbackStatus.unread:
        statusColor = appThemeColors.errorRed;
        statusText = 'Непрочитано';
        statusIcon = Icons.mark_email_unread;
        break;
      case FeedbackStatus.read:
        statusColor = appThemeColors.orangeAccent;
        statusText = 'Прочитано';
        statusIcon = Icons.mark_email_read;
        break;
      case FeedbackStatus.processed:
        statusColor = appThemeColors.successGreen;
        statusText = 'Опрацьовано';
        statusIcon = Icons.done_all;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: feedback.status == FeedbackStatus.unread
            ? Border.all(color: appThemeColors.errorRed, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.userEmail,
                        style: TextStyleHelper.instance.title16Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(feedback.timestamp, locale: 'uk'),
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: appThemeColors.grey200, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              feedback.feedback,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
          ),
          if (feedback.adminNote != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: appThemeColors.blueMixedColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: appThemeColors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Примітка адміністратора:',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          fontWeight: FontWeight.w700,
                          color: appThemeColors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feedback.adminNote!,
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (feedback.status != FeedbackStatus.processed) ...[
            Divider(color: appThemeColors.grey200, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (feedback.status == FeedbackStatus.unread)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          viewModel.markFeedbackAsRead(feedback.id);
                        },
                        icon: Icon(Icons.done),
                        label: Text('Прочитано'),
                        style: TextButton.styleFrom(
                          foregroundColor: appThemeColors.orangeAccent,
                        ),
                      ),
                    ),
                  if (feedback.status == FeedbackStatus.unread)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showProcessDialog(context, feedback, viewModel);
                      },
                      icon: Icon(Icons.check_circle),
                      label: Text('Опрацьовано'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appThemeColors.successGreen,
                        foregroundColor: appThemeColors.primaryWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showProcessDialog(BuildContext context,
      FeedbackModel feedback,
      AdminViewModel viewModel,) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: appThemeColors.primaryWhite,
            title: Text(
              'Опрацювати відгук',
              style: TextStyleHelper.instance.title18Bold,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Додайте примітку про опрацювання відгуку:',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: noteController,
                  label: 'Примітка',
                  hintText: 'Відгук опрацьовано...',
                  maxLines: 3,
                  inputType: TextInputType.text,
                  height: 48,
                  labelColor: appThemeColors.primaryBlack,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Скасувати'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final note = noteController.text
                      .trim()
                      .isNotEmpty
                      ? noteController.text.trim()
                      : 'Відгук опрацьовано';

                  final success = await viewModel.processFeedback(
                    feedback.id,
                    note,
                  );

                  Navigator.of(context).pop();

                  if (success) {
                    Constants.showSuccessMessage(context, 'Відгук опрацьовано');
                  } else {
                    Constants.showErrorMessage(
                      context,
                      'Помилка опрацювання відгуку',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appThemeColors.successGreen,
                ),
                child: Text(
                  'Опрацювати',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
