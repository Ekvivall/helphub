import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth/auth_view_model.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/text_field.dart';
import 'package:helphub/widgets/auth/divider.dart';
import 'package:helphub/widgets/auth/google_login_button.dart';
import 'package:helphub/widgets/auth/logo_section.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 400),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(height: 106),
                      buildLogoSection(177, 242),
                      _buildWelcomeText(),
                      SizedBox(height: 44),
                      _buildLoginForm(context, controller),
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

  Widget _buildWelcomeText() {
    return Text(
      'Раді вас бачити знову!',
      style: TextStyleHelper.instance.headline24SemiBold.copyWith(height: 1.2),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthViewModel controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.textTransparentBlack,
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            label: 'Електронна пошта',
            hintText: 'Введіть електронну пошту',
            controller: controller.emailController,
            inputType: TextInputType.emailAddress,
            onChanged: (value) => controller.updateEmail(value),
          ),
          SizedBox(height: 12),
          AuthTextField(
            label: 'Пароль',
            hintText: 'Введіть пароль',
            controller: controller.passwordController,
            inputType: TextInputType.text,
            isPassword: true,
            onChanged: (value) => controller.updatePassword(value),
          ),
          SizedBox(height: 12),
          CustomElevatedButton(
            text: 'Увійти',
            isLoading: controller.isLoading,
            onPressed: controller.isLoading
                ? null
                : () => controller.handleLogin(context),
          ),
          SizedBox(height: 12),
          buildDivider(appThemeColors.blueAccent),
          SizedBox(height: 12),
          buildGoogleSignInButton(context, controller),
          SizedBox(height: 12),
          _buildFooterLinks(context, controller),
        ],
      ),
    );
  }

  Widget _buildFooterLinks(BuildContext context, AuthViewModel controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => controller.handleForgotPassword(context),
          child: Text(
            'Забули пароль?',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              height: 1.2,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => controller.handleRegister(context),
          child: Text(
            'Зареєструватися',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
