import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../core/utils/constants.dart';
import '../theme/theme_helper.dart';
import 'custom_input_field.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? date;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime?) onDateChanged;
  final String dateLabel;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  final Color? errorColor;

  const CustomDatePicker({
    super.key,
    this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    this.dateLabel = 'Оберіть дату',
    this.padding,
    this.borderRadius, this.errorColor,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late TextEditingController _dateController;

  // Маска для дати у форматі дд.мм.рррр
  final MaskTextInputFormatter _dateMaskFormatter = MaskTextInputFormatter(
    mask: '##.##.####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  DateTime? _selectedDate;
  String? _dateError;

  @override
  void initState() {
    super.initState();

    _dateController = TextEditingController(
      text: widget.date != null ? Constants.formatDate(widget.date!) : '',
    );
    _selectedDate = widget.date;
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length != 10) {
      return 'Формат: дд.мм.рррр';
    }

    final date = Constants.parseDate(value);
    if (date == null) {
      return 'Невірна дата';
    }
    if (date.isBefore(widget.firstDate.subtract(Duration(days: 1))) || date.isAfter(widget.lastDate)) {
      return 'Дата поза допустимим діапазоном';
    }
    return null;
  }

  void _onDateChanged(String value) {
    setState(() {
      _dateError = _validateDate(value);
      _selectedDate = _dateError == null && value.isNotEmpty
          ? Constants.parseDate(value)
          : null;
    });

    widget.onDateChanged(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return CustomInputField(
      controller: _dateController,
      inputFormatters: [_dateMaskFormatter],
      inputType: TextInputType.number,
      textColor: appThemeColors.primaryBlack,
      showErrorsLive: true,
      errorColor: widget.errorColor ??appThemeColors.errorLight,
      hintText: 'дд.мм.рррр',
      prefixIcon: Icon(Icons.calendar_today),
      validator: _validateDate,

      suffixIcon: _dateController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _dateController.clear();
                _onDateChanged('');
              },
            )
          : null,
      onChanged: _onDateChanged,
    );
  }
}
