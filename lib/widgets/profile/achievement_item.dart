import 'package:flutter/cupertino.dart';
import 'package:helphub/models/achievement_item_model.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../custom_image_view.dart';

class AchievementItemWidget extends StatelessWidget{
  final AchievementItemModel achievementItemModel;

  const AchievementItemWidget({super.key, required this.achievementItemModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomImageView(
          imagePath: achievementItemModel.imagePath ?? '',
          height: 128,
          width: 96,
          fit: BoxFit.cover,
        ),
        SizedBox(height: 8),
        Text(
          achievementItemModel.title ?? '',
          style: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ],
    );
  }
}