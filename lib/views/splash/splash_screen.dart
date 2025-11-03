import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/splash/splash_view_model.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SplashViewModel>(context, listen: false).initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Блокуємо стандартний pop
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop(); // Закриваємо додаток
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.9, -0.4),
              end: Alignment(-0.9, 0.4),
              colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //HelpHub logo
              Container(
                margin: EdgeInsets.only(bottom: 32),
                child: CustomImageView(
                  imagePath: ImageConstant.volunteerLogo,
                  height: 177,
                  width: 242,
                  fit: BoxFit.contain,
                ),
              ),

              // Mission statement
              Container(
                constraints: BoxConstraints(maxWidth: 320),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Об\'єднуємо небайдужих заради добрих справ',
                  style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                    color: appThemeColors.primaryWhite,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
