import 'package:flutter/material.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:provider/provider.dart';

import '../../view_models/fundraising/fundraising_view_model.dart';
import '../../widgets/custom_date_range_picker.dart';
import '../../widgets/custom_elevated_button.dart';

class FundraisingFiltersBottomSheet extends StatefulWidget {
  const FundraisingFiltersBottomSheet({super.key});

  @override
  State<StatefulWidget> createState() => _FundraisingFiltersBottomSheetState();
}

class _FundraisingFiltersBottomSheetState
    extends State<FundraisingFiltersBottomSheet> {
  List<CategoryChipModel> _tempSelectedCategories = [];
  DateTime? _tempSelectedStartDate;
  DateTime? _tempSelectedEndDate;
  bool _tempIsUrgentOnly = false;
  double? _tempMinTargetAmount;
  double? _tempMaxTargetAmount;
  Key _datePickerKey = UniqueKey();
  String? _tempSelectedBank;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<FundraisingViewModel>(context, listen: false);
    _tempSelectedCategories = List.from(viewModel.selectedCategories);
    _tempSelectedStartDate = viewModel.selectedStartDate;
    _tempSelectedEndDate = viewModel.selectedEndDate;
    _tempIsUrgentOnly = viewModel.isUrgentOnly;
    _tempMinTargetAmount = viewModel.minTargetAmount;
    _tempMaxTargetAmount = viewModel.maxTargetAmount;
    _tempSelectedBank = viewModel.selectedBank;

    if (_tempMinTargetAmount != null) {
      _minAmountController.text = _tempMinTargetAmount!.toStringAsFixed(0);
    }
    if (_tempMaxTargetAmount != null) {
      _maxAmountController.text = _tempMaxTargetAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FundraisingViewModel>(context);
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Фільтри зборів',
                    style: TextStyleHelper.instance.title20Regular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: appThemeColors.primaryBlack),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Categories Filter
            Text(
              'Категорії',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),

            // Date Range Filter
            Text(
              'Період завершення збору',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            SimpleDateRangePicker(
              key: _datePickerKey,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialStartDate: _tempSelectedStartDate,
              initialEndDate: _tempSelectedEndDate,
              onDateRangeChanged: (start, end) {
                setState(() {
                  _tempSelectedStartDate = start;
                  _tempSelectedEndDate = end;
                });
              },
            ),
            const SizedBox(height: 20),

            // Target Amount Filter
            Text(
              'Цільова сума',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Від (грн)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: appThemeColors.blueAccent,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      _tempMinTargetAmount = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'До (грн)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: appThemeColors.blueAccent,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      _tempMaxTargetAmount = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),const SizedBox(height: 20),
            Text('Банк', style: TextStyleHelper.instance.title16Bold.copyWith(color: appThemeColors.primaryBlack)),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: Text('PrivatBank'),
                  selected: _tempSelectedBank == 'privat',
                  onSelected: (selected) => setState(() => _tempSelectedBank = selected ? 'privat' : null),
                  selectedColor: appThemeColors.blueMixedColor,
                  disabledColor: appThemeColors.blueMixedColor,
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text('Monobank'),
                  selected: _tempSelectedBank == 'mono',
                  onSelected: (selected) => setState(() => _tempSelectedBank = selected ? 'mono' : null),
                  selectedColor: appThemeColors.blueMixedColor,
                  disabledColor: appThemeColors.blueMixedColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Urgent Only Filter
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тільки термінові збори',
                        style: TextStyleHelper.instance.title16Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Показати збори, які позначені як термінові',
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _tempIsUrgentOnly,
                  onChanged: (value) {
                    setState(() {
                      _tempIsUrgentOnly = value;
                    });
                  },
                  activeColor: appThemeColors.blueAccent,
                  inactiveTrackColor: appThemeColors.textMediumGrey,
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
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
      _tempIsUrgentOnly = false;
      _tempMinTargetAmount = null;
      _tempMaxTargetAmount = null;
      _minAmountController.clear();
      _maxAmountController.clear();
      _datePickerKey = UniqueKey();
    });
  }

  void _applyFiltersToViewModel(FundraisingViewModel viewModel) {
    viewModel.setFilters(
      _tempSelectedCategories,
      _tempSelectedStartDate,
      _tempSelectedEndDate,
      _tempIsUrgentOnly,
      _tempMinTargetAmount,
      _tempMaxTargetAmount,
      _tempSelectedBank
    );
  }
}
