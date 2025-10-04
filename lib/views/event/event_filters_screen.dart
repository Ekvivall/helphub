import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/category_chip_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_date_range_picker.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/profile/category_chip_widget.dart';

class EventFiltersBottomSheet extends StatefulWidget {
  const EventFiltersBottomSheet({super.key});

  @override
  State<StatefulWidget> createState() => _EventFiltersBottomSheetState();
}

class _EventFiltersBottomSheetState extends State<EventFiltersBottomSheet> {
  List<CategoryChipModel> _tempSelectedCategories = [];
  DateTime? _tempSelectedStartDate;
  DateTime? _tempSelectedEndDate;
  double? _tempSearchRadius;
  Key _datePickerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<EventViewModel>(context, listen: false);
    _tempSelectedCategories = List.from(viewModel.selectedCategories);
    _tempSelectedStartDate = viewModel.selectedStartDate;
    _tempSelectedEndDate = viewModel.selectedEndDate;
    _tempSearchRadius = viewModel.searchRadius;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<EventViewModel>(context);
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
              'Фільтри подій',
              style: TextStyleHelper.instance.title20Regular.copyWith(
                fontWeight: FontWeight.w700,
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Категорії',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            Text(
              'Дата',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: () {
                      _clearFiltersLocally();
                      viewModel.clearFilters();
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

          ],
        ),
      ),
    );
  }

  void _clearFiltersLocally() {
    setState(() {
      _tempSelectedCategories = [];
      _tempSelectedStartDate = null;
      _tempSelectedEndDate = null;
      _tempSearchRadius = null;
      _datePickerKey = UniqueKey();
    });
  }

  void _applyFiltersToViewModel(EventViewModel viewModel) {
    viewModel.setFilters(
      _tempSelectedCategories,
      null,
      null,
      _tempSearchRadius,
      _tempSelectedStartDate,
      _tempSelectedEndDate,
    );
  }
}
