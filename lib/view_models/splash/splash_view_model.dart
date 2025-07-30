import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:helphub/routes/app_router.dart';


class SplashViewModel extends ChangeNotifier {
  BuildContext? _context;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void initialize(BuildContext context) {
    _context = context;
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Future.delayed(Duration(seconds: 3), () async {
      if (_context == null) return;

      final user = _auth.currentUser;

      if (user != null) {
        // Користувач авторизований, намагаємося отримати його роль з Firestore
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            Navigator.of(
              _context!,
            ).pushReplacementNamed(AppRoutes.eventListScreen);
          } else {
            Navigator.of(_context!).pushReplacementNamed(AppRoutes.loginScreen);
          }
        } catch (e) {
          Navigator.of(_context!).pushReplacementNamed(AppRoutes.loginScreen);
        }
      } else {
        Navigator.of(_context!).pushReplacementNamed(AppRoutes.loginScreen);
      }
    });
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }
}
