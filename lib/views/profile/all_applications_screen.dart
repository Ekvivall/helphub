import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/profile/fundraiser_application_item_widget.dart';
import 'package:helphub/widgets/profile/project_application_item.dart';
import 'package:provider/provider.dart';

enum ApplicationFilter { all, projects, fundraisers }

class AllApplicationsScreen extends StatefulWidget {
  const AllApplicationsScreen({super.key});

  @override
  State<AllApplicationsScreen> createState() => _AllApplicationsScreenState();
}

class _AllApplicationsScreenState extends State<AllApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Мої заявки',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appThemeColors.backgroundLightGrey,
          unselectedLabelColor: appThemeColors.backgroundLightGrey.withAlpha(150),
          indicatorColor: appThemeColors.lightGreenColor,
          labelStyle: TextStyleHelper.instance.title14Regular.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyleHelper.instance.title14Regular,
          tabs: const [
            Tab(text: 'Всі'),
            Tab(text: 'Проєкти'),
            Tab(text: 'Збори'),
          ],
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
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildAllApplications(viewModel),
                _buildProjectApplications(viewModel),
                _buildFundraiserApplications(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAllApplications(ProfileViewModel viewModel) {
    // Створюємо об'єднаний список з позначенням типу
    List<ApplicationItem> allItems = [];

    // Додаємо заявки на проєкти
    for (var app in viewModel.volunteerProjectApplications) {
      final project = viewModel.projectsData[app.projectId];
      allItems.add(ApplicationItem.project(app, project));
    }

    // Додаємо заявки на збори
    for (var app in viewModel.volunteerFundraiserApplications) {
      allItems.add(ApplicationItem.fundraiser(app));
    }

    // Сортуємо за часом (найновіші спочатку)
    allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (viewModel.isLoading && allItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: appThemeColors.backgroundLightGrey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'Ви ще не подавали заявок',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Заявки на проєкти та збори з\'являться тут',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: item.isProject
              ? ProjectApplicationItem(
            application: item.projectApplication!,
            project: item.project,
          )
              : FundraiserApplicationItem(
            application: item.fundraiserApplication!,
          ),
        );
      },
    );
  }

  Widget _buildProjectApplications(ProfileViewModel viewModel) {
    if (viewModel.isLoading && viewModel.volunteerProjectApplications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (viewModel.volunteerProjectApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: appThemeColors.backgroundLightGrey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'Немає заявок на проєкти',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ваші заявки на участь у проєктах з\'являться тут',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.volunteerProjectApplications.length,
      itemBuilder: (context, index) {
        final app = viewModel.volunteerProjectApplications[index];
        final project = viewModel.projectsData[app.projectId];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProjectApplicationItem(
            application: app,
            project: project,
          ),
        );
      },
    );
  }

  Widget _buildFundraiserApplications(ProfileViewModel viewModel) {
    if (viewModel.isLoading && viewModel.volunteerFundraiserApplications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (viewModel.volunteerFundraiserApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 80,
              color: appThemeColors.backgroundLightGrey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'Немає заявок на збори',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ваші заявки на збір коштів з\'являться тут',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.volunteerFundraiserApplications.length,
      itemBuilder: (context, index) {
        final app = viewModel.volunteerFundraiserApplications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FundraiserApplicationItem(application: app),
        );
      },
    );
  }
}

class ApplicationItem {
  final bool isProject;
  final dynamic projectApplication;
  final dynamic fundraiserApplication;
  final dynamic project;
  final DateTime timestamp;

  ApplicationItem.project(this.projectApplication, this.project)
      : isProject = true,
        fundraiserApplication = null,
        timestamp = projectApplication.timestamp.toDate();

  ApplicationItem.fundraiser(this.fundraiserApplication)
      : isProject = false,
        projectApplication = null,
        project = null,
        timestamp = fundraiserApplication.timestamp.toDate();
}