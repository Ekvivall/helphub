import 'package:flutter/material.dart';

import '../core/utils/image_constant.dart';
import 'custom_image_view.dart';

class CustomTournamentIconButton extends StatelessWidget {
  const CustomTournamentIconButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        //TODO
      },
      icon: CustomImageView(
        imagePath: ImageConstant.tournamentIcon,
        height: 24,
        width: 24,
      ),
    );
  }
}