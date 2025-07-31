import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_input_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../core/utils/constants.dart';

class SimpleDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  final String startDateLabel;
  final String endDateLabel;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const SimpleDateRangePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateRangeChanged,
    this.startDateLabel = 'Початкова дата',
    this.endDateLabel = 'Кінцева дата',
    this.padding,
    this.borderRadius,
  });

  @override
  State<SimpleDateRangePicker> createState() => _SimpleDateRangePickerState();
}

class _SimpleDateRangePickerState extends State<SimpleDateRangePicker> {
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  // Маска для дати у форматі дд.мм.рррр
  final MaskTextInputFormatter _dateMaskFormatter = MaskTextInputFormatter(
    mask: '##.##.####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _startDateError;
  String? _endDateError;

  @override
  void initState() {
    super.initState();

    _startDateController = TextEditingController(
      text: widget.initialStartDate != null
          ? Constants.formatDate(widget.initialStartDate!)
          : '',
    );

    _endDateController = TextEditingController(
      text: widget.initialEndDate != null
          ? Constants.formatDate(widget.initialEndDate!)
          : '',
    );

    _selectedStartDate = widget.initialStartDate;
    _selectedEndDate = widget.initialEndDate;
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String dateString) {
    if (dateString.length != 10) return null;

    try {
      final parts = dateString.split('.');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final date = DateTime(year, month, day);

      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }

      return date;
    } catch (e) {
      return null;
    }
  }

  String? _validateStartDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length != 10) {
      return 'Формат: дд.мм.рррр';
    }

    final date = _parseDate(value);
    if (date == null) {
      return 'Невірна дата';
    }

    if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) {
      return 'Дата поза допустимим діапазоном';
    }
    if (_selectedEndDate != null && date.isAfter(_selectedEndDate!)) {
      return 'Початкова дата не може бути пізніше кінцевої';
    }

    return null;
  }

  String? _validateEndDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length != 10) {
      return 'Формат: дд.мм.рррр';
    }

    final date = _parseDate(value);
    if (date == null) {
      return 'Невірна дата';
    }

    if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) {
      return 'Дата поза допустимим діапазоном';
    }
    if (_selectedStartDate != null && date.isBefore(_selectedStartDate!)) {
      return 'Кінцева дата не може бути раніше початкової';
    }

    return null;
  }

  void _onStartDateChanged(String value) {
    setState(() {
      _startDateError = _validateStartDate(value);
      _selectedStartDate = _startDateError == null && value.isNotEmpty
          ? _parseDate(value)
          : null;
    });

    widget.onDateRangeChanged(_selectedStartDate, _selectedEndDate);
  }

  void _onEndDateChanged(String value) {
    setState(() {
      _endDateError = _validateEndDate(value);
      _selectedEndDate = _endDateError == null && value.isNotEmpty
          ? _parseDate(value)
          : null;
    });

    widget.onDateRangeChanged(_selectedStartDate, _selectedEndDate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Початкова дата
        CustomInputField(
          controller: _startDateController,
          inputFormatters: [_dateMaskFormatter],
          inputType: TextInputType.number,
          labelText: widget.startDateLabel,
          textColor: appThemeColors.primaryBlack,
          showErrorsLive: true,
          errorColor: appThemeColors.errorRed,
          hintText: 'дд.мм.рррр',
          prefixIcon: Icon(Icons.calendar_today),
          validator: _validateStartDate,
          suffixIcon: _startDateController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _startDateController.clear();
                    _onStartDateChanged('');
                  },
                )
              : null,
          onChanged: _onStartDateChanged,
        ),

        SizedBox(height: 16),

        // Кінцева дата
        CustomInputField(
          controller: _endDateController,
          inputFormatters: [_dateMaskFormatter],
          inputType: TextInputType.number,
          labelText: widget.endDateLabel,
          textColor: appThemeColors.primaryBlack,
          showErrorsLive: true,
          errorColor: appThemeColors.errorRed,
          hintText: 'дд.мм.рррр',
          prefixIcon: Icon(Icons.calendar_today),
          validator: _validateEndDate,
          suffixIcon: _endDateController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _endDateController.clear();
              _onEndDateChanged('');
            },
          )
              : null,
          onChanged: _onEndDateChanged,
        ),

        SizedBox(height: 12),

      ],
    );
  }
}
