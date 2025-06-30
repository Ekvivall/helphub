import 'package:flutter/cupertino.dart';
import 'package:helphub/routes/app_router.dart';

class SplashViewModel extends ChangeNotifier{
  BuildContext? _context;
  void initialize(BuildContext context){
    _context = context;
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Future.delayed(Duration(seconds: 3), (){
      if(_context != null){
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