import 'package:helphub/data/models/base_profile_model.dart';


extension UserRoleStringExtension on String{
  UserRole? toUserRole(){
    try{
      return UserRole.values.firstWhere((e)=>e.toString().split('.').last == this);
    } catch(e){
      return null;
    }
  }
}
