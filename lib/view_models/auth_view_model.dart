import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../routes/app_router.dart';

class AuthViewModel extends ChangeNotifier {
  void hangleRegister(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.registerTypeScreen);
  }
}
