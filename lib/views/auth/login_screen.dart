import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth_view_model.dart';
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
                      SizedBox(height: 118),
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

  Widget _buildLoginForm(BuildContext context, AuthViewModel controller) {
    return Container(
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildFooterLinks(context, controller)],
      ),
    );
  }

  Widget _buildFooterLinks(BuildContext context, AuthViewModel controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          child: Text(
            'Забули пароль?',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              height: 1.2,
            ),
          ),
        ),
        GestureDetector(
          onTap:()=>controller.hangleRegister(context),
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
