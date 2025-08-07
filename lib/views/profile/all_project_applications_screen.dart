import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/profile/project_application_item.dart';
import 'package:provider/provider.dart';

class AllProjectApplicationsScreen extends StatefulWidget {
  const AllProjectApplicationsScreen({super.key});

  @override
  State<AllProjectApplicationsScreen> createState() =>
      _AllProjectApplicationsScreenState();
}

class _AllProjectApplicationsScreenState
    extends State<AllProjectApplicationsScreen> {

  @override
  void initState() {
    super.initState();
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
          'Мої заявки на проєкти',
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
            begin: Alignment(0.9, -0.4),
            end: Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.volunteerProjectApplications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.volunteerProjectApplications.isEmpty) {
              return Center(
                child: Text(
                  'Ви ще не подавали заявок на проєкти.',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              itemCount: viewModel.volunteerProjectApplications.length,
              itemBuilder: (context, index) {
                final app = viewModel.volunteerProjectApplications[index];
                final project = viewModel.projectsData[app.projectId];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ProjectApplicationItem(
                    application: app,
                    project: project,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}