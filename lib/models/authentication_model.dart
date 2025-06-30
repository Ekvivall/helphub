import 'package:helphub/models/user_model.dart';

class AuthenticationModel {
  String email;
  String password;
  bool isLoading;
  bool isPasswordVisible;
  UserRole role;

  AuthenticationModel({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.isPasswordVisible = false,
    this.role = UserRole.volunteer
  });
}
