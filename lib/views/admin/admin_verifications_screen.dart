import 'package:flutter/material.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/utils/constants.dart';
import '../../data/models/organization_verification_model.dart';
import '../../theme/text_style_helper.dart';
import '../../view_models/admin/admin_view_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() =>
      _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  final TextEditingController _rejectionReasonController =
  TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

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
          'Перевірка фондів',
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
            if (viewModel.isLoadingVerifications) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.backgroundLightGrey,
                ),
              );
            }

            if (viewModel.pendingVerifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 64,
                      color: appThemeColors.backgroundLightGrey.withAlpha(150),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Немає заявок на перевірку',
                      style: TextStyleHelper.instance.title18Bold.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Всі фонди вже перевірені',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey.withAlpha(
                          150,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.pendingVerifications.length,
              itemBuilder: (context, index) {
                final verification = viewModel.pendingVerifications[index];
                return _buildVerificationCard(verification, viewModel);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerificationCard(OrganizationVerificationModel verification,
      AdminViewModel viewModel,) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок з фото та назвою
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                UserAvatarWithFrame(size: 32,
                    role: UserRole.organization,
                    photoUrl: verification.organizationPhotoUrl,
                    uid: verification.organizationId),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification.organizationName,
                        style: TextStyleHelper.instance.title16Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Подано ${timeago.format(
                            verification.submittedAt, locale: 'uk')}',
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: appThemeColors.grey200, height: 1),

          // Контактна інформація
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Контактна інформація',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    fontWeight: FontWeight.w700,
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 16,
                      color: appThemeColors.textMediumGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      verification.email,
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                  ],
                ),
                if (verification.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: appThemeColors.textMediumGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        verification.phoneNumber!,
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Документи
          if (verification.documents.isNotEmpty) ...[
            Divider(color: appThemeColors.grey200, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Документи (${verification.documents.length})',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...verification.documents.map((docUrl) {
                    final fileName = Constants.getFileNameFromUrl(docUrl);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => Constants.openDocument(context, docUrl),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appThemeColors.blueMixedColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Constants.getDocumentIcon(fileName),
                                color: appThemeColors.blueAccent,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: TextStyleHelper.instance.title13Regular
                                      .copyWith(
                                    color: appThemeColors.primaryBlack,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: appThemeColors.blueAccent,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Кнопки дій
          Divider(color: appThemeColors.grey200, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    text: 'Відхилити',
                    onPressed: () =>
                        _showRejectionDialog(context, verification, viewModel),
                    backgroundColor: appThemeColors.errorRed.withAlpha(200),
                    textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryWhite,
                      fontWeight: FontWeight.w700,
                    ),
                    borderRadius: 12,
                    height: 44,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomElevatedButton(
                    text: 'Підтвердити',
                    onPressed: () =>
                        _approveOrganization(context, verification, viewModel),
                    backgroundColor: appThemeColors.successGreen,
                    textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryWhite,
                      fontWeight: FontWeight.w700,
                    ),
                    borderRadius: 12,
                    height: 44,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(BuildContext context,
      OrganizationVerificationModel verification,
      AdminViewModel viewModel,) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: appThemeColors.primaryWhite,
            title: Text(
              'Відхилити заявку',
              style: TextStyleHelper.instance.title18Bold,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Вкажіть причину відхилення заявки від "${verification
                      .organizationName}":',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _rejectionReasonController,
                  label: 'Причина відхилення',
                  hintText: 'Наприклад: Недостатньо документів...',
                  maxLines: 4,
                  inputType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) {
                      return 'Будь ласка, вкажіть причину відхилення';
                    }
                    return null;
                  },
                  height: 48,
                  labelColor: appThemeColors.primaryBlack,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _rejectionReasonController.clear();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Скасувати',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_rejectionReasonController.text
                      .trim()
                      .isEmpty) {
                    return;
                  }

                  final success = await viewModel.rejectOrganization(
                    verification.organizationId,
                    _rejectionReasonController.text.trim(),
                  );

                  Navigator.of(context).pop();
                  _rejectionReasonController.clear();

                  if (success) {
                    Constants.showSuccessMessage(context, 'Заявку відхилено');
                  } else {
                    Constants.showErrorMessage(
                      context,
                      'Помилка відхилення заявки',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appThemeColors.errorRed,
                ),
                child: Text(
                  'Відхилити',
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

  void _approveOrganization(BuildContext context,
      OrganizationVerificationModel verification,
      AdminViewModel viewModel,) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: appThemeColors.primaryWhite,
            title: Text(
              'Підтвердити фонд',
              style: TextStyleHelper.instance.title18Bold,
            ),
            content: Text(
              'Ви дійсно хочете підтвердити фонд "${verification
                  .organizationName}"?',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Скасувати'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await viewModel.approveOrganization(
                    verification.organizationId,
                  );

                  Navigator.of(context).pop();

                  if (success) {
                    Constants.showSuccessMessage(
                      context,
                      'Фонд успішно підтверджено!',
                    );
                  } else {
                    Constants.showErrorMessage(
                      context,
                      'Помилка підтвердження фонду',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appThemeColors.successGreen,
                ),
                child: Text(
                  'Підтвердити',
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
