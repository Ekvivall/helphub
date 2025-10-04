import 'package:flutter/material.dart';
import 'package:helphub/data/services/donation_service.dart';
import 'package:helphub/data/services/fundraising_service.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/data/models/donation_model.dart';
import 'package:helphub/data/models/fundraising_model.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../view_models/profile/profile_view_model.dart';

class FundraisingDonationsScreen extends StatefulWidget {
  final String fundraisingId;

  const FundraisingDonationsScreen({super.key, required this.fundraisingId});

  @override
  State<FundraisingDonationsScreen> createState() =>
      _FundraisingDonationsScreenState();
}

class _FundraisingDonationsScreenState
    extends State<FundraisingDonationsScreen> {
  final DonationService _donationService = DonationService();
  final FundraisingService _fundraisingService = FundraisingService();
  FundraisingModel? fundraising;
  Map<String, dynamic>? donationStats;
  List<DonationModel> donations = [];
  bool isLoadingStats = true;
  bool isLoadingFundraising = true;
  bool isLoadingDonations = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadDonations();
  }

  Future<void> _loadData() async {
    try {
      final fundraisingData = await _fundraisingService.getFundraisingById(
        widget.fundraisingId,
      );
      final stats = await _donationService.getFundraisingDonationStats(
        widget.fundraisingId,
      );

      if (mounted) {
        setState(() {
          fundraising = fundraisingData;
          donationStats = stats;
          isLoadingStats = false;
          isLoadingFundraising = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingStats = false;
          isLoadingFundraising = false;
        });
      }
    }
  }

  void _loadDonations() {
    _donationService.getFundraisingDonations(widget.fundraisingId).listen(
          (donationList) {
        if (mounted) {
          setState(() {
            donations = donationList;
            isLoadingDonations = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isLoadingDonations = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Список донатів',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.9, -0.4),
            end: const Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Заголовок збору та статистика
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appThemeColors.primaryWhite.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appThemeColors.backgroundLightGrey.withAlpha(77),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoadingFundraising)
                      const Center(child: CircularProgressIndicator())
                    else if (fundraising != null) ...[
                      Text(
                        fundraising!.title ?? 'Збір коштів',
                        style: TextStyleHelper.instance.title18Bold.copyWith(
                          color: appThemeColors.backgroundLightGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Статистика
                    if (isLoadingStats)
                      const Center(child: CircularProgressIndicator())
                    else if (donationStats != null) ...[
                      Row(
                        children: [
                          _buildStatCard(
                            'Всього зібрано',
                            '${NumberFormat('# ###').format(donationStats!['totalAmount'] ?? 0)} грн',
                            Icons.attach_money,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Кількість донатів',
                            '${donationStats!['donationCount'] ?? 0}',
                            Icons.volunteer_activism,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatCard(
                            'Унікальних донатерів',
                            '${donationStats!['uniqueDonorsCount'] ?? 0}',
                            Icons.people,
                          ),
                          const SizedBox(width: 12),
                          if (fundraising?.targetAmount != null)
                            _buildStatCard(
                              'Прогрес',
                              '${((donationStats!['totalAmount'] ?? 0) / fundraising!.targetAmount! * 100).toStringAsFixed(1)}%',
                              Icons.trending_up,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Список донатів
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: appThemeColors.primaryWhite.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appThemeColors.backgroundLightGrey.withAlpha(77),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Донати',
                        style: TextStyleHelper.instance.title16Bold.copyWith(
                          color: appThemeColors.backgroundLightGrey,
                        ),
                      ),
                    ),
                    if (isLoadingDonations)
                      const Padding(
                        padding: EdgeInsets.all(50),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (donations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volunteer_activism_outlined,
                              size: 64,
                              color: appThemeColors.backgroundLightGrey
                                  .withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Поки що немає донатів',
                              style: TextStyleHelper
                                  .instance
                                  .title16Regular
                                  .copyWith(
                                color: appThemeColors
                                    .backgroundLightGrey
                                    .withAlpha(178),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: donations.length,
                        separatorBuilder: (context, index) => Divider(
                          color: appThemeColors.backgroundLightGrey
                              .withAlpha(77),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final donation = donations[index];
                          return _buildDonationItem(donation);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appThemeColors.backgroundLightGrey.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: appThemeColors.backgroundLightGrey.withAlpha(77),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: appThemeColors.backgroundLightGrey),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(178),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationItem(DonationModel donation) {
    if (donation.isAnonymous) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        leading: CircleAvatar(
          backgroundColor: appThemeColors.backgroundLightGrey.withAlpha(77),
          child: Icon(
            Icons.visibility_off,
            color: appThemeColors.backgroundLightGrey,
            size: 20,
          ),
        ),
        title: Text(
          'Анонім',
          style: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('dd.MM.yyyy HH:mm').format(donation.timestamp),
          style: TextStyleHelper.instance.title13Regular.copyWith(
            color: appThemeColors.backgroundLightGrey.withAlpha(178),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: appThemeColors.backgroundLightGrey.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: appThemeColors.backgroundLightGrey.withAlpha(77),
            ),
          ),
          child: Text(
            '${NumberFormat('#,###').format(donation.amount)} грн',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return FutureBuilder<BaseProfileModel?>(
      future: Provider.of<ProfileViewModel>(
        context,
        listen: false,
      ).fetchUser(donation.donorId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          leading: isLoading
              ? const CircularProgressIndicator()
              : UserAvatarWithFrame(
            size: 20,
            role: user?.role!,
            uid: donation.donorId,
            photoUrl: user?.photoUrl,
            frame: user is VolunteerModel ? user.frame : null,
          ),
          title: Text(
            donation.donorName.toString(),
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            DateFormat('dd.MM.yyyy HH:mm').format(donation.timestamp),
            style: TextStyleHelper.instance.title13Regular.copyWith(
              color: appThemeColors.backgroundLightGrey.withAlpha(178),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: appThemeColors.backgroundLightGrey.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appThemeColors.backgroundLightGrey.withAlpha(77),
              ),
            ),
            child: Text(
              '${NumberFormat('#,###').format(donation.amount)} грн',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}