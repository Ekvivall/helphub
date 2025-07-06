import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/models/user_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/widgets/auth/divider.dart';
import 'package:helphub/widgets/auth/google_login_button.dart';
import 'package:helphub/widgets/auth/logo_section.dart';
import 'package:helphub/widgets/auth/role_button.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_helper.dart';
import '../../view_models/auth/auth_view_model.dart';

class RegistrationTypeScreen extends StatelessWidget {
  const RegistrationTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, controller, child) {
        return Scaffold(
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
            child: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildLogoSection(177,242),
                      const SizedBox(height: 24),
                      _buildTitle(),
                      const SizedBox(height: 32),
                      buildRoleButton(
                        context,
                        label: 'Волонтер',
                        iconPath: ImageConstant.volunteerIcon,
                        onTap: () =>
                            controller.selectRole(context, UserRole.volunteer),
                      ),
                      const SizedBox(height: 16),
                      buildRoleButton(
                        context,
                        label: 'Благодійний фонд',
                        iconPath: ImageConstant.foundationIcon,
                        onTap: () =>
                            controller.selectRole(context, UserRole.organization),
                      ),
                      const SizedBox(height: 20),
                      buildDivider(appThemeColors.backgroundLightGrey),
                      const SizedBox(height: 12),
                      buildGoogleSignInButton(context, controller),
                      const SizedBox(height: 12),
                      _buildFooterLink(context, controller),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      'Оберіть вашу роль',
      style: TextStyleHelper.instance.headline24SemiBold.copyWith(height: 1.2),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFooterLink(BuildContext context, AuthViewModel controller) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Вже маєте обліковий запис? ',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              height: 1.2,
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          GestureDetector(
            onTap: () => controller.handleBackToLogin(context),
            child: Text(
              'Увійти',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                height: 1.2,
                color: appThemeColors.primaryWhite,
                decoration: TextDecoration.underline,
                decorationColor: appThemeColors.primaryWhite
              ),
            ),
          ),
        ],
      ),
    );
  }
}
