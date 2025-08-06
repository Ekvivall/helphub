import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/views/event/event_filters_screen.dart';
import 'package:helphub/views/event/event_map_screen.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:provider/provider.dart';

import '../../models/base_profile_model.dart';
import '../../models/volunteer_model.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/custom_notification_icon_button.dart';
import '../../widgets/events/event_list_item.dart';
import '../../widgets/user_avatar_with_frame.dart';

enum DisplayMode { list, map }

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  DisplayMode _displayMode = DisplayMode.list; // Початковий режим - список
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
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
        child: Consumer<EventViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.user == null) return SizedBox.shrink();
            final BaseProfileModel user = viewModel.user!;
            return Column(
              children: [
                // Кастомний хедер
                _buildHeader(context, viewModel, user),
                const SizedBox(height: 16),
                // Перемикач режимів "Список" / "Мапа"
                _buildDisplayModeToggle(context),
                const SizedBox(height: 16),
                //Основний контент (список подій або карта)
                Expanded(
                  child: _displayMode == DisplayMode.list
                      ? _buildEventList(viewModel)
                      : const EventMapScreen(),
                ),
              ],
            );
          },
        ),
      ),
      // Плаваюча кнопка дії
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.createEventScreen, arguments: '');
        },
        backgroundColor: appThemeColors.blueAccent,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: appThemeColors.primaryWhite, size: 37),
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context,
        0
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EventViewModel viewModel,
    BaseProfileModel user,
  ) {
    final VolunteerModel? volunteer = user is VolunteerModel ? user : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
      color: appThemeColors.appBarBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWithFrame(
            size: 22,
            role: user.role,
            photoUrl: user.photoUrl,
            frame: volunteer?.frame,
            uid: user.uid!,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: CustomInputField(
              hintText: 'Пошук подій...',
              controller: _searchController,
              onChanged: (query) {
                viewModel.setSearchQuery(query);
              },
              borderRadius: 10,
              textColor: appThemeColors.primaryBlack,
              hintTextColor: appThemeColors.textMediumGrey,
              borderColor: appThemeColors.transparent,
              focusedBorderColor: appThemeColors.blueAccent,
              suffixIcon: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return const EventFiltersBottomSheet();
                    },
                  );
                },
                icon: Icon(
                  Icons.filter_list_alt,
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              //TODO
            },
            icon: CustomImageView(
              imagePath: ImageConstant.tournamentIcon,
              height: 24,
              width: 24,
            ),
          ),
          CustomNotificationIconButton(),
        ],
      ),
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
                  _displayMode = DisplayMode.list;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _displayMode == DisplayMode.list
                      ? appThemeColors.blueMixedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Список',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _displayMode == DisplayMode.list
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
                  _displayMode = DisplayMode.map;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _displayMode == DisplayMode.map
                      ? appThemeColors.blueMixedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Мапа',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _displayMode == DisplayMode.map
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

  Widget _buildEventList(EventViewModel viewModel) {
    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: appThemeColors.successGreen),
      );
    }
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.errorRed,
            ),
          ),
        ),
      );
    }
    if (viewModel.filteredEvents.isEmpty) {
      return Center(
        child: Text(
          'Подій не знайдено або вони не відповідають критеріям фільтрації.',
          textAlign: TextAlign.center,
          style: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: viewModel.filteredEvents.length,
      itemBuilder: (context, index) {
        final event = viewModel.filteredEvents[index];
        return EventListItem(
          event: event,
          userCurrentLocation: viewModel.currentUserLocation,
          viewModel: viewModel,
        );
      },
    );
  }
}
