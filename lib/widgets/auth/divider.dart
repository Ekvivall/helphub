
import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';

Widget buildDivider(Color color) {
  return Center(
    child: Text(
      '-АБО-',
      style: TextStyleHelper.instance.title16Bold.copyWith(height: 1.2, color: color),
    ),
  );
}