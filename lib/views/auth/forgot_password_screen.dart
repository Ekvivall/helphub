import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../validators/auth_validator.dart';
import '../../view_models/auth/auth_view_model.dart';
import '../../widgets/auth/logo_section.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
                child: Form(
                  key: _formKey,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 100),
                        buildLogoSection(177, 242),
                        _buildTitle(),
                        const SizedBox(height: 20),
                        _buildEmailForm(context, controller),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => controller.handleBackToLogin(context),
                          child: Text(
                            'Назад до входу',
                            style: TextStyleHelper.instance.title16Regular
                                .copyWith(
                                  height: 1.2,
                                  color: appThemeColors.primaryWhite,
                                ),
                          ),
                        ),
                      ],
                    ),
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
      'Відновлення пароля',
      style: TextStyleHelper.instance.headline24SemiBold.copyWith(height: 1.2),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailForm(BuildContext context, AuthViewModel controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.textTransparentBlack,
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Введіть вашу електронну пошту, і ми надішлемо вам інструкції для скидання пароля.',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.textMediumGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Електронна пошта',
            hintText: 'Введіть вашу електронну пошту',
            controller: controller.emailController,
            inputType: TextInputType.emailAddress,
            validator: AuthValidator.validateEmail,
          ),
          const SizedBox(height: 24),
          CustomElevatedButton(
            text: 'Надіслати інструкції',
            isLoading: controller.isLoading,
            onPressed: controller.isLoading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState!.validate()) {
                      controller.handleForgotPassword(context);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
