import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/validators/auth_validator.dart';
import 'package:helphub/view_models/auth/organization_register_view_model.dart';
import 'package:helphub/widgets/auth/footer_link.dart';
import 'package:helphub/widgets/auth/logo_section.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../theme/text_style_helper.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterOrganizationStep1Screen extends StatefulWidget {
  const RegisterOrganizationStep1Screen({super.key});

  @override
  State<RegisterOrganizationStep1Screen> createState() =>
      _RegisterOrganizationStep1ScreenState();
}

class _RegisterOrganizationStep1ScreenState
    extends State<RegisterOrganizationStep1Screen> {
  final GlobalKey<FormState> _formKeyStep1 = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationRegisterViewModel>(
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
                  key: _formKeyStep1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        // Кнопка "Назад"
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back,
                              color: appThemeColors.primaryWhite,
                            ),
                          ),
                        ),
                        buildLogoSection(120, 164),
                        _buildWelcomeText(),
                        const SizedBox(height: 14),
                        _buildRegistrationForm(context, controller),
                        const SizedBox(height: 20),
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
    OrganizationRegisterViewModel controller,
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
            label: 'Назва організації',
            hintText: 'Введіть назву організації',
            controller: controller.organizationNameController,
            inputType: TextInputType.text,
            validator: AuthValidator.validateOrganizationName,
            showErrorsLive: controller.showValidationErrors,
            errorColor: appThemeColors.errorRed,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Електронна пошта',
            hintText: 'your.email@example.com',
            controller: controller.emailController,
            inputType: TextInputType.emailAddress,
            validator: AuthValidator.validateEmail,
            showErrorsLive: controller.showValidationErrors,
            errorColor: appThemeColors.errorRed,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Веб-сайт (необов\'язково)',
            hintText: 'https://yourorganization.org',
            controller: controller.websiteController,
            inputType: TextInputType.url,
            validator: AuthValidator.validateWebsite,
            showErrorsLive: controller.showValidationErrors,
            isRequired: false,
            errorColor: appThemeColors.errorRed,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          CustomElevatedButton(
            text: 'Далі',
            isLoading: controller.isLoading,
            onPressed: controller.isLoading
                ? null
                : () => controller.handleRegistrationStep1(context, _formKeyStep1),
          ),
          const SizedBox(height: 12),
          buildFooterLink(context),
        ],
      ),
    );
  }
}
