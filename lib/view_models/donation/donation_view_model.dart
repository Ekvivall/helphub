import 'package:flutter/cupertino.dart';
import 'package:helphub/data/services/donation_service.dart';
import 'package:helphub/data/models/donation_model.dart';
import 'package:helphub/data/models/organization_model.dart';
import 'package:helphub/data/models/volunteer_model.dart';

import '../../data/services/activity_service.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/base_profile_model.dart';
import '../../data/models/fundraising_model.dart';

class DonationViewModel extends ChangeNotifier {
  final DonationService _donationService = DonationService();
  final ActivityService _activityService = ActivityService();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<bool> makeDonation({
    required double amount,
    required String fundraisingId,
    required BaseProfileModel donor,
    required bool isAnonymous,
    required FundraisingModel fundraising
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newDonation = DonationModel(fundraisingId: fundraisingId,
          donorId: donor.uid!,
          donorName: isAnonymous
              ? 'Анонімний донатер'
              : (donor is VolunteerModel ? donor.fullName ??
              donor.displayName ?? 'Волонтер' : donor is OrganizationModel
              ? donor.organizationName ?? 'Фонд'
              : 'Невідомий користувач'),
          amount: amount,
          timestamp: DateTime.now(),
          isAnonymous: isAnonymous
      );
      await _donationService.addDonation(newDonation);
      final activity = ActivityModel(
        type: ActivityType.fundraiserDonation,
        entityId: fundraisingId,
        title: fundraising.title!,
        description: fundraising.description,
        timestamp: DateTime.now(),
      );
      await _activityService.logActivity(donor.uid!, activity);
      return true;
    } catch(e){
      _errorMessage = 'Помилка під час надсилання донату: $e';
      return false;
    } finally{
      _isLoading = false;
      notifyListeners();
    }
  }
}
