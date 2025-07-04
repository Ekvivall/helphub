import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_helper.dart';
import '../../view_models/auth/auth_view_model.dart';

class EventMapScreen extends StatelessWidget{
  const EventMapScreen({super.key});

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
                ),
              ),
            ),
          ),
        );
      },
    );
  }


}