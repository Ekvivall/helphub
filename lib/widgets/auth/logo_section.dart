import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/widgets/custom_image_view.dart';

Widget buildLogoSection(double height, double width) {
  return CustomImageView(
    imagePath: ImageConstant.volunteerLogo,
    height: height,
    width: width,
    fit: BoxFit.contain,
  );
}