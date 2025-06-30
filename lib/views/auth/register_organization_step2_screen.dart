import 'package:flutter/material.dart';
import 'package:helphub/widgets/custom_document_upload_field.dart';
import 'package:provider/provider.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/auth/organization_register_view_model.dart';
import '../../widgets/auth/logo_section.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/text_field.dart';

class RegisterOrganizationStep2Screen extends StatelessWidget {
  const RegisterOrganizationStep2Screen({super.key});

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
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _buildRegistrationForm(context, controller),
                      const SizedBox(height: 20),
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
          CustomDocumentUploadField(
            label: 'Документи для верифікації',
            description:
                'Завантажте документи, що підтверджують легальний статус вашої організації',
            onTap: controller.pickDocument,
            fileNames: controller.selectedDocuments.map((e)=>e.name).toList(),
            isLoading: controller.isLoading,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            label: 'Пароль',
            hintText: 'Введіть пароль',
            isPassword: true,
            controller: controller.passwordController,
            inputType: TextInputType.text,
            onChanged: (value) => controller.updatePassword(value),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            label: 'Підтвердження паролю',
            hintText: 'Підтвердіть пароль',
            isPassword: true,
            controller: controller.confirmPasswordController,
            inputType: TextInputType.text,
            onChanged: (value) => controller.updateConfirmPassword(value),
          ),
          const SizedBox(height: 16),
          CustomCheckboxWithText(
            value: controller.isAgreementAccepted,
            crossAxisAlignment: CrossAxisAlignment.center,
            onChanged: (newValue) {
              controller.updateAgreement(newValue ?? false);
            },
            text:
                'Я підтверджую, що маю право представляти організацію та погоджуюсь з умовами використання',
          ),
          const SizedBox(height: 16),
          CustomElevatedButton(
            text: 'Зареєструватися',
            isLoading: controller.isLoading,
            onPressed: controller.isLoading
                ? null
                : () => controller.handleRegistrationStep2(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
