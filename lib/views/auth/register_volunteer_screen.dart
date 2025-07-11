import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/validators/auth_validator.dart';
import 'package:helphub/widgets/auth/logo_section.dart';
import 'package:helphub/widgets/custom_checkbox.dart';
import 'package:helphub/widgets/custom_dropdown.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/auth/volunteer_register_view_model.dart';
import '../../widgets/auth/footer_link.dart';
import '../../widgets/custom_text_field.dart';

class RegisterVolunteerScreen extends StatefulWidget {
  const RegisterVolunteerScreen({super.key});

  @override
  State<RegisterVolunteerScreen> createState() =>
      _RegisterVolunteerScreenState();
}

class _RegisterVolunteerScreenState extends State<RegisterVolunteerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<VolunteerRegisterViewModel>(
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
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        buildLogoSection(120, 164),
                        _buildWelcomeText(),
                        const SizedBox(height: 14),
                        _buildRegistrationForm(context, controller),
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

  Widget _buildWelcomeText() {
    return Text(
      'Реєстрація',
      style: TextStyleHelper.instance.headline24SemiBold.copyWith(height: 1.2),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRegistrationForm(
    BuildContext context,
    VolunteerRegisterViewModel controller,
  ) {
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
          CustomTextField(
            label: 'Ім\'я та прізвище',
            hintText: 'Введіть ваше ім\'я та прізвище',
            controller: controller.fullNameController,
            inputType: TextInputType.name,
            validator: AuthValidator.validateFullName,
            showErrorsLive: controller.showValidationErrors,
          ),
          const SizedBox(height: 7),
          CustomTextField(
            label: 'Електронна пошта',
            hintText: 'your.email@example.com',
            controller: controller.emailController,
            inputType: TextInputType.emailAddress,
            validator: AuthValidator.validateEmail,
            showErrorsLive: controller.showValidationErrors,
          ),
          const SizedBox(height: 7),
          CustomDropdown(
            labelText: 'Місто',
            value: controller.selectedCity,
            hintText: 'Оберіть місто',
            items: Constants.cities,
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.updateCity(newValue);
              }
            },
            menuMaxHeight: 200,
            validator: AuthValidator.validateSelectedCity,
            showErrorsLive: controller.showValidationErrors,
          ),
          const SizedBox(height: 7),
          CustomTextField(
            label: 'Пароль',
            hintText: 'Введіть пароль',
            isPassword: true,
            controller: controller.passwordController,
            inputType: TextInputType.text,
            validator: AuthValidator.validatePassword,
            showErrorsLive: controller.showValidationErrors,
          ),
          const SizedBox(height: 7),
          CustomTextField(
            label: 'Підтвердження паролю',
            hintText: 'Підтвердіть пароль',
            isPassword: true,
            controller: controller.confirmPasswordController,
            inputType: TextInputType.text,
            validator: (value) => AuthValidator.validateConfirmPassword(
              value,
              controller.passwordController.text,
            ),
            showErrorsLive: controller.showValidationErrors,
          ),
          const SizedBox(height: 12),
          CustomCheckboxWithText(
            initialValue: controller.isAgreementAccepted,
            crossAxisAlignment: CrossAxisAlignment.center,
            onChanged: (newValue) {
              controller.updateAgreement(newValue ?? false);
            },
            text:
                'Я погоджуюсь з умовами використання та політикою конфіденційності',
            validator: AuthValidator.validateAgreementAccepted,
            showErrorsLive: controller.showValidationErrors,
          ),
          const SizedBox(height: 8),
          CustomElevatedButton(
            text: 'Зареєструватися',
            isLoading: controller.isLoading,
            onPressed: controller.isLoading
                ? null
                : () => controller.handleRegistration(context, _formKey),
          ),
          const SizedBox(height: 7),
          buildFooterLink(context),
        ],
      ),
    );
  }
}
