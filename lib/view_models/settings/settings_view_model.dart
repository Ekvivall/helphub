import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../../core/services/user_service.dart';
import '../../models/base_profile_model.dart';

class SettingsViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  String? get currentUserId => _currentUserId;
  BaseProfileModel? _user;

  BaseProfileModel? get user => _user;

  SettingsViewModel() {
    _auth.authStateChanges().listen((user) async {
      _currentUserId = user?.uid;
      if(_currentUserId != null) {
        _user = await _userService.fetchUserProfile(_currentUserId);
        notifyListeners();
      }
    });
  }

}
