import 'package:helphub/models/base_profile_model.dart';
/*
UserRole? userRoleFromString(String? roleString) {
  if (roleString == null) return null;
  try {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == roleString,
    );
  } catch (e) {
    return null;
  }
}*/

extension UserRoleStringExtension on String{
  UserRole? toUserRole(){
    try{
      return UserRole.values.firstWhere((e)=>e.toString().split('.').last == this);
    } catch(e){
      return null;
    }
  }
}
