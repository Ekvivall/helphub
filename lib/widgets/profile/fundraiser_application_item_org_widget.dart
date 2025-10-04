import 'package:flutter/material.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/fundraiser_application_model.dart';
import '../../data/models/volunteer_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../custom_elevated_button.dart';
import '../user_avatar_with_frame.dart';

class FundraiserApplicationItemOrg extends StatelessWidget {
  final FundraiserApplicationModel application;
  final Future<BaseProfileModel?> applicantUser;
  final Function(String) onApprove;
  final Function(String) onReject;

  const FundraiserApplicationItemOrg({
    super.key,
    required this.application,
    required this.onApprove,
    required this.onReject,
    required this.applicantUser,
  });

  Color _getStatusColor(FundraisingStatus status) {
    switch (status) {
      case FundraisingStatus.pending:
        return appThemeColors.blueAccent;
      case FundraisingStatus.active:
        return appThemeColors.orangeAccent;
      case FundraisingStatus.completed:
        return appThemeColors.primaryBlack.withAlpha(150);
      case FundraisingStatus.rejected:
        return appThemeColors.errorRed;
      case FundraisingStatus.approved:
        return appThemeColors.successGreen;
    }
  }

  String _getStatusDisplayName(FundraisingStatus status) {
    switch (status) {
      case FundraisingStatus.pending:
        return 'На розгляді';
      case FundraisingStatus.active:
        return 'В процесі';
      case FundraisingStatus.completed:
        return 'Виконано';
      case FundraisingStatus.rejected:
        return 'Відхилено';
      case FundraisingStatus.approved:
        return 'Схвалено';
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.title,
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(application.status).withAlpha(14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(application.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusDisplayName(application.status),
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: _getStatusColor(application.status),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              application.description,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 12),
            if (application.categories.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: application.categories.map((category) {
                  return CategoryChipWidget(chip: category, isSelected: false);
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Text(
                  '${application.requiredAmount.toStringAsFixed(0)} грн',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.blueAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat(
                    'dd.MM.yyyy',
                  ).format(application.deadline.toDate()),
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ],
            ),
            if (application.status == FundraisingStatus.rejected &&
                application.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(77)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Причина відхилення:',
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.rejectionReason!,
                      style: TextStyleHelper.instance.title13Regular,
                    ),
                  ],
                ),
              ),
            ],
            if (application.supportingDocuments != null &&
                application.supportingDocuments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Документи',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(
                  application.supportingDocuments!.length,
                  (index) {
                    final fileUrl = application.supportingDocuments![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: appThemeColors.blueMixedColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: appThemeColors.primaryBlack,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Документ №${index+1}',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(color: appThemeColors.primaryBlack),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _launchURL(fileUrl),
                            icon: Icon(
                              Icons.download,
                              color: appThemeColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (application.status == FundraisingStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomElevatedButton(
                      onPressed: () => onApprove(application.id),
                      text: 'Схвалити',
                      backgroundColor: Colors.green,
                      textStyle: TextStyleHelper.instance.title14Regular
                          .copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      borderRadius: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomElevatedButton(
                      onPressed: () => onReject(application.id),
                      text: 'Відхилити',
                      backgroundColor: Colors.red,
                      textStyle: TextStyleHelper.instance.title14Regular
                          .copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      borderRadius: 8,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FutureBuilder<BaseProfileModel?>(
              future: applicantUser,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Text(
                    'Інформація про автора недоступна',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.errorRed,
                    ),
                  );
                }
                final user = snapshot.data!;
                return Row(
                  children: [
                    UserAvatarWithFrame(
                      size: 25,
                      role: user.role,
                      photoUrl: user.photoUrl,
                      frame: (user is VolunteerModel) ? user.frame : null,
                      uid: user.uid!,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user is VolunteerModel
                              ? (user).fullName ??
                                    (user).displayName ??
                                    'Волонтер'
                              : 'Невідомий користувач',
                          style: TextStyleHelper.instance.title18Bold,
                        ),
                        Text(
                          '${user.projectsCount ?? 0} організованих проєктів',
                          style: TextStyleHelper.instance.title14Regular,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appThemeColors.backgroundLightGrey.withAlpha(14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.contact_mail,
                    size: 16,
                    color: appThemeColors.textMediumGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    application.contactInfo,
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
    );
  }
}
