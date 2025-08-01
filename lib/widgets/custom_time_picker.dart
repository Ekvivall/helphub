import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../core/utils/constants.dart';
import '../theme/theme_helper.dart';
import 'custom_input_field.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay? time;
  final Function(TimeOfDay?) onTimeChanged;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const CustomTimePicker({
    super.key,
    this.padding,
    this.borderRadius,
    this.time,
    required this.onTimeChanged,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late TextEditingController _timeController;

  final MaskTextInputFormatter _timeMaskFormatter = MaskTextInputFormatter(
    mask: '##:##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  TimeOfDay? _selectedTime;
  String? _timeError;

  @override
  void initState() {
    super.initState();

    _timeController = TextEditingController(
      text: widget.time != null ? Constants.formatTime(widget.time!) : '',
    );
    _selectedTime = widget.time;
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  String? _validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length != 5) {
      return 'Формат: hh:mm';
    }

    final time = Constants.parseTime(value);
    if (time == null || time.hour > 24 || time.minute > 59) {
      return 'Невірний час';
    }
    return null;
  }

  void _onTimeChanged(String value) {
    setState(() {
      _timeError = _validateTime(value);
      _selectedTime = _timeError == null && value.isNotEmpty
          ? Constants.parseTime(value)
          : null;
    });

    widget.onTimeChanged(_selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    return CustomInputField(
      controller: _timeController,
      inputFormatters: [_timeMaskFormatter],
      inputType: TextInputType.number,
      textColor: appThemeColors.primaryBlack,
      showErrorsLive: true,
      errorColor: appThemeColors.errorLight,
      hintText: 'hh:mm',
      prefixIcon: Icon(Icons.access_time),
      validator: _validateTime,
      suffixIcon: _timeController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _timeController.clear();
                _onTimeChanged('');
              },
            )
          : null,
      onChanged: _onTimeChanged,
    );
  }
}
