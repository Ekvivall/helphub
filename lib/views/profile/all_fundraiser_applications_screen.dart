import 'package:flutter/material.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/profile/fundraiser_application_item_org_widget.dart';
import 'package:provider/provider.dart';

import '../../core/services/user_service.dart';
import '../../core/utils/constants.dart';
import '../../models/fundraiser_application_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/fundraiser_application/fundraiser_application_view_model.dart';
import '../../widgets/custom_text_field.dart';

class AllFundraiserApplicationsScreen extends StatefulWidget {
  const AllFundraiserApplicationsScreen({super.key});

  @override
  State<AllFundraiserApplicationsScreen> createState() =>
      _AllFundraiserApplicationsScreenState();
}

class _AllFundraiserApplicationsScreenState
    extends State<AllFundraiserApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rejectionReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _approveApplication(String applicationId) async {
    final viewModel = Provider.of<FundraiserApplicationViewModel>(
      context,
      listen: false,
    );
    final result = await viewModel.approveApplication(applicationId);
    if (result == null) {
      Constants.showSuccessMessage(context, 'Заявку схвалено!');
    } else {
      Constants.showErrorMessage(context, result);
    }
  }

  void _showRejectDialog(String applicationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Відхилити заявку',
            style: TextStyleHelper.instance.title18Bold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Вкажіть причину відхилення заявки:',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _rejectionReasonController,
                label: 'Причина відхилення',
                hintText: 'Наприклад: Недостатньо документів...',
                maxLines: 3,
                inputType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
              onPressed: () => _rejectApplication(applicationId),
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.errorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Відхилити',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectApplication(String applicationId) async {
    if (_rejectionReasonController.text.trim().isEmpty) {
      return;
    }

    final viewModel = Provider.of<FundraiserApplicationViewModel>(
      context,
      listen: false,
    );

    final result = await viewModel.rejectApplication(
      applicationId,
      _rejectionReasonController.text.trim(),
    );

    Navigator.of(context).pop();
    _rejectionReasonController.clear();

    if (result == null) {
      Constants.showSuccessMessage(context, 'Заявку відхилено');
    } else {
      Constants.showErrorMessage(context, result);
    }
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
          'Управління заявками',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appThemeColors.backgroundLightGrey,
          unselectedLabelColor: appThemeColors.backgroundLightGrey.withAlpha(
           177,
          ),
          indicatorColor: appThemeColors.backgroundLightGrey,
          labelPadding: EdgeInsets.symmetric(horizontal: 7),
          tabs: const [
            Tab(text: 'Нові'),
            Tab(text: 'Схвалені'),
            Tab(text: 'Активні'),
            Tab(text: 'Виконані'),
            Tab(text: 'Відхилені'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.9, -0.4),
            end: const Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.user == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.backgroundLightGrey,
                ),
              );
            }

            final allApplications =
                viewModel.organizationFundraiserApplications;

            // Фільтруємо заявки за статусами
            final pendingApplications = allApplications
                .where((app) => app.status == FundraisingStatus.pending)
                .toList();
            final approvedApplications = allApplications
                .where((app) => app.status == FundraisingStatus.approved)
                .toList();

            final activeApplications = allApplications
                .where((app) => app.status == FundraisingStatus.active)
                .toList();

            final completedApplications = allApplications
                .where((app) => app.status == FundraisingStatus.completed)
                .toList();

            final rejectedApplications = allApplications
                .where((app) => app.status == FundraisingStatus.rejected)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsList(pendingApplications),
                _buildApplicationsList(approvedApplications),
                _buildApplicationsList(activeApplications),
                _buildApplicationsList(completedApplications),
                _buildApplicationsList(rejectedApplications),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildApplicationsList(List<FundraiserApplicationModel> applications) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: appThemeColors.primaryWhite,
            ),
            const SizedBox(height: 16),
            Text(
              'Немає заявок',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
          ],
        ),
      );
    }

    UserService userService = UserService();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return FundraiserApplicationItemOrg(
          application: application,
          onApprove: (id) => _approveApplication(id),
          onReject: (id) => _showRejectDialog(id),
          applicantUser: userService.fetchUserProfile(application.volunteerId),
        );
      },
    );
  }
}
