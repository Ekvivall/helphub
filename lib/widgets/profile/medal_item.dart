import 'package:flutter/material.dart';
import 'package:helphub/data/models/medal_item_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_image_view.dart';

class MedalItemWidget extends StatelessWidget {
  final MedalItemModel medalItemModel;

  const MedalItemWidget({super.key, required this.medalItemModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CustomImageView(
            imagePath: medalItemModel.imagePath ?? '',
            height: 80,
            width: 80,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 8,),
          Text(medalItemModel.title ?? '',
            style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.backgroundLightGrey),)
        ],
      ),
    );
  }
}
