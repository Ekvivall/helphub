import 'package:flutter/material.dart';
import 'package:helphub/data/models/category_chip_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:provider/provider.dart';

import '../../view_models/project/project_view_model.dart';
import '../../widgets/custom_date_range_picker.dart';
import '../../widgets/custom_elevated_button.dart';

class ProjectFiltersBottomSheet extends StatefulWidget {
  const ProjectFiltersBottomSheet({super.key});

  @override
  State<StatefulWidget> createState() => _ProjectFiltersBottomSheetState();
}

class _ProjectFiltersBottomSheetState extends State<ProjectFiltersBottomSheet> {
  List<CategoryChipModel> _tempSelectedCategories = [];
  List<String> _tempSelectedSkills = [];
  DateTime? _tempSelectedStartDate;
  DateTime? _tempSelectedEndDate;
  double? _tempSearchRadius;
  bool _tempIsOnlyFriends = false;
  bool _tempIsOnlyOpen = false;
  Key _datePickerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<ProjectViewModel>(context, listen: false);
    _tempSelectedCategories = List.from(viewModel.selectedCategories);
    _tempSelectedSkills = List.from(viewModel.selectedSkills);
    _tempSelectedStartDate = viewModel.selectedStartDate;
    _tempSelectedEndDate = viewModel.selectedEndDate;
    _tempSearchRadius = viewModel.searchRadius;
    _tempIsOnlyFriends = viewModel.isOnlyFriends;
    _tempIsOnlyOpen = viewModel.isOnlyOpen;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProjectViewModel>(context);
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: appThemeColors.backgroundLightGrey,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фільтри проєктів',
              style: TextStyleHelper.instance.title20Regular.copyWith(
                fontWeight: FontWeight.w700,
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Категорії',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: viewModel.availableCategories.map((category) {
                final isSelected = _tempSelectedCategories.any(
                      (element) => element.title == category.title,
                );
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (!isSelected) {
                        _tempSelectedCategories.add(category);
                      } else {
                        _tempSelectedCategories.removeWhere(
                              (element) => element.title == category.title,
                        );
                      }
                    });
                  },
                  child: CategoryChipWidget(
                    chip: category,
                    isSelected: isSelected,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Навички',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: viewModel.availableSkills.map((skill) {
                final bool isSelected = _tempSelectedSkills.contains(
                  skill.title,
                );
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _tempSelectedSkills.remove(skill.title);
                      } else {
                        _tempSelectedSkills.add(skill.title!);
                      }
                    });
                  },
                  child: Chip(
                    padding: const EdgeInsets.all(1),
                    label: Text(skill.title!),
                    backgroundColor: isSelected
                        ? appThemeColors.blueAccent
                        : appThemeColors.textMediumGrey,
                    labelStyle: TextStyleHelper.instance.title14Regular
                        .copyWith(
                      color: isSelected
                          ? appThemeColors.primaryWhite
                          : appThemeColors.textLightColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Дата',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 5),
            SimpleDateRangePicker(
              key: _datePickerKey,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
              initialStartDate: _tempSelectedStartDate,
              initialEndDate: _tempSelectedEndDate,
              onDateRangeChanged: (start, end) {
                setState(() {
                  _tempSelectedStartDate = start;
                  _tempSelectedEndDate = end;
                });
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Відстань від поточної локації',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            if (viewModel.currentUserLocation == null && !viewModel.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Для використання фільтра за відстанню, будь ласка, надайте доступ до геопозиції у налаштуваннях додатку.',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.errorRed,
                  ),
                ),
              ),
            const SizedBox(height: 5),
            if (viewModel.currentUserLocation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: _tempSearchRadius ?? 0,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_tempSearchRadius?.round() ?? 0} км',
                    onChanged: (value) {
                      setState(() {
                        _tempSearchRadius = value;
                      });
                    },
                    activeColor: appThemeColors.blueAccent,
                    inactiveColor: appThemeColors.grey400,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Радіус: ${_tempSearchRadius?.round() ?? 0} км',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.primaryBlack,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Тільки для друзів',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                ),
                Switch(
                  value: _tempIsOnlyFriends,
                  onChanged: (value) {
                    setState(() {
                      _tempIsOnlyFriends = value;
                    });
                  },
                  activeColor: appThemeColors.blueAccent,
                  inactiveTrackColor: appThemeColors.blueAccent,
                  inactiveThumbColor: appThemeColors.appBarBg,
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Тільки відкриті проєкти',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                ),
                Switch(
                  value: _tempIsOnlyOpen,
                  onChanged: (value) {
                    setState(() {
                      _tempIsOnlyOpen = value;
                    });
                  },
                  activeColor: appThemeColors.blueAccent,
                  inactiveTrackColor: appThemeColors.blueAccent,
                  inactiveThumbColor: appThemeColors.appBarBg,
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: () {
                      _clearFiltersLocally();
                      viewModel.clearFilters();
                      Navigator.pop(context);
                    },
                    text: 'Очистити',
                    backgroundColor: appThemeColors.textMediumGrey,
                    borderRadius: 10,
                    textStyle: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: () {
                      _applyFiltersToViewModel(viewModel);
                      Navigator.pop(context);
                    },
                    text: 'Застосувати',
                    backgroundColor: appThemeColors.blueAccent,
                    borderRadius: 10,
                    textStyle: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _clearFiltersLocally() {
    setState(() {
      _tempSelectedCategories = [];
      _tempSelectedSkills = [];
      _tempSelectedStartDate = null;
      _tempSelectedEndDate = null;
      _tempSearchRadius = null;
      _tempIsOnlyFriends = false;
      _tempIsOnlyOpen = false;
      _datePickerKey = UniqueKey();
    });
  }

  void _applyFiltersToViewModel(ProjectViewModel viewModel) {
    viewModel.setFilters(
      _tempSelectedCategories,
      _tempSelectedSkills,
      _tempSearchRadius,
      _tempSelectedStartDate,
      _tempSelectedEndDate,
      _tempIsOnlyFriends,
      _tempIsOnlyOpen,
    );
  }
}