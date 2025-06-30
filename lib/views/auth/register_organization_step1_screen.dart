import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth/organization_register_view_model.dart';
import 'package:helphub/widgets/auth/footer_link.dart';
import 'package:helphub/widgets/auth/logo_section.dart';
import 'package:provider/provider.dart';

import '../../theme/text_style_helper.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/text_field.dart';

class RegisterOrganizationStep1Screen extends StatelessWidget {
  const RegisterOrganizationStep1Screen({super.key});

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
                      const SizedBox(height: 32),
                      // Кнопка "Назад"
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          onPressed: ()=>Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: appThemeColors.primaryWhite,
                          ),
                        ),
                      ),
                      buildLogoSection(120, 164),
                      _buildWelcomeText(),
                      const SizedBox(height: 20,),
                      _buildRegistrationForm(context, controller),
                      const SizedBox(height: 20,)
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
          AuthTextField(
            label: 'Назва організації',
            hintText: 'Введіть назву організації',
            controller: controller.organizationNameController,
            inputType: TextInputType.text,
            onChanged: (value) => controller.updateOrganizationName(value),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            label: 'Електронна пошта',
            hintText: 'your.email@example.com',
            controller: controller.emailController,
            inputType: TextInputType.emailAddress,
            onChanged: (value) => controller.updateEmail(value),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            label: 'Веб-сайт (необов\'язково)',
            hintText: 'https://yourorganization.org',
            controller: controller.websiteController,
            inputType: TextInputType.url,
            onChanged: (value) => controller.updateWebsite(value),
          ),
          const SizedBox(height: 12),
        CustomDropdown(
          labelText: 'Місто',
          value: controller.selectedCity,
          hintText: 'Оберіть місто',
          items: controller.cities,
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.updateCity(newValue);
            }
          },
          menuMaxHeight: 200,
        ),
          const SizedBox(height: 16),
          CustomElevatedButton(
            text: 'Далі',
            isLoading: controller.isLoading,
            onPressed: controller.isLoading
                ? null
                : () => controller.handleRegistrationStep1(context),
          ),
          const SizedBox(height: 12,),
          buildFooterLink(context),
        ],
      ),
    );
  }
}
