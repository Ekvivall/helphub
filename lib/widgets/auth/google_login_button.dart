import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth/auth_view_model.dart';
import 'package:helphub/widgets/custom_image_view.dart';

Widget buildGoogleSignInButton(
    BuildContext context,
    AuthViewModel controller,
    ) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: () => controller.handleGoogleSignIn(context),
      style: OutlinedButton.styleFrom(
        backgroundColor: appThemeColors.backgroundLightGrey,
        side: BorderSide(color: appThemeColors.blueAccent, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(
            imagePath: ImageConstant.googleIcon,
            height: 46,
            width: 46,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 12),
          Text(
            'Увійти з Google',
            style: TextStyleHelper.instance.title16ExtraBold.copyWith(
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}
