import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/activity_model.dart';
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

import '../../data/models/raffle_winner_model.dart';
import '../../routes/app_router.dart';
import '../../view_models/profile/profile_view_model.dart';
import '../../widgets/custom_elevated_button.dart';

class FundraisingRaffleScreen extends StatefulWidget {
  final String fundraisingId;

  const FundraisingRaffleScreen({super.key, required this.fundraisingId});

  @override
  State<FundraisingRaffleScreen> createState() =>
      _FundraisingRaffleScreenState();
}

class _FundraisingRaffleScreenState extends State<FundraisingRaffleScreen> {
  final DonationService _donationService = DonationService();
  final FundraisingService _fundraisingService = FundraisingService();

  FundraisingModel? fundraising;
  List<DonationModel> donations = [];
  Map<String, DonorTickets> donorTickets = {};
  bool isLoadingData = true;
  bool isRaffleCompleted = false;
  bool isRaffleInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fundraisingData = await _fundraisingService.getFundraisingById(
        widget.fundraisingId,
      );

      if (fundraisingData == null) {
        throw Exception('Збір не знайдено');
      }

      final donationsList = await _donationService
          .getFundraisingDonations(widget.fundraisingId)
          .first;

      final nonAnonymousDonations = donationsList
          .where((donation) => !donation.isAnonymous)
          .toList();

      final Map<String, DonorTickets> ticketsMap = {};

      for (var donation in nonAnonymousDonations) {
        final ticketPrice = fundraisingData.ticketPrice ?? 100;
        final ticketsForDonation = (donation.amount / ticketPrice).floor();

        if (ticketsForDonation > 0) {
          if (ticketsMap.containsKey(donation.donorId)) {
            ticketsMap[donation.donorId]!.totalAmount += donation.amount;
            ticketsMap[donation.donorId]!.ticketCount += ticketsForDonation;
            ticketsMap[donation.donorId]!.donations.add(donation);
          } else {
            ticketsMap[donation.donorId] = DonorTickets(
              donorId: donation.donorId,
              donorName: donation.donorName ?? 'Користувач',
              totalAmount: donation.amount,
              ticketCount: ticketsForDonation,
              donations: [donation],
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          fundraising = fundraisingData;
          donations = nonAnonymousDonations;
          donorTickets = ticketsMap;
          isLoadingData = false;
          if (fundraisingData.raffleWinners != null &&
              fundraisingData.raffleWinners!.isNotEmpty) {
            isRaffleCompleted = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження даних: ${e.toString()}'),
            backgroundColor: appThemeColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _onCompleteRaffle() async {
    if (fundraising?.prizes == null || fundraising!.prizes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Немає призів для розіграшу'),
          backgroundColor: appThemeColors.errorRed,
        ),
      );
      return;
    }
    setState(() {
      isRaffleInProgress = true;
    });

    try {
      List<String> allTickets = [];
      for (var donorTicket in donorTickets.values) {
        for (int i = 0; i < donorTicket.ticketCount; i++) {
          allTickets.add(donorTicket.donorId);
        }
      }

      if (allTickets.isEmpty) {
        throw Exception('Немає квитків для розіграшу');
      }

      final random = Random();
      final winners = <String>[];
      final Map<String, DonorTickets> winnersMap = {};
      final availableTickets = List<String>.from(allTickets);
      final prizeCount = min(fundraising!.prizes!.length, donorTickets.length);

      for (int i = 0; i < prizeCount; i++) {
        if (availableTickets.isEmpty) break;

        // Затримка для ефекту
        await Future.delayed(const Duration(seconds: 1));

        final winnerIndex = random.nextInt(availableTickets.length);
        final winnerId = availableTickets[winnerIndex];
        final winnerTickets = donorTickets[winnerId]!;

        if (!winners.contains(winnerId)) {
          winners.add(winnerId);
          winnersMap[winnerId] = winnerTickets;
          // Видаляємо всі квитки цього переможця, щоб він не міг виграти двічі
          availableTickets.removeWhere((ticket) => ticket == winnerId);
        }
      }

      final List<RaffleWinnerModel> raffleWinners = winners.asMap().entries.map(
        (entry) {
          final winnerId = entry.value;
          final winnerTickets = donorTickets[winnerId]!;
          final prize = fundraising!.prizes![entry.key];
          return RaffleWinnerModel(
            donorId: winnerTickets.donorId,
            donorName: winnerTickets.donorName,
            prize: prize,
            ticketsWon: winnerTickets.ticketCount,
            timestamp: Timestamp.now(),
          );
        },
      ).toList();

      await _fundraisingService.saveRaffleWinners(
        widget.fundraisingId,
        raffleWinners,
      );

      await _loadData();

      setState(() {
        isRaffleCompleted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Розіграш успішно завершено! Результати збережено.',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
            backgroundColor: appThemeColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка проведення розіграшу: ${e.toString()}'),
            backgroundColor: appThemeColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRaffleInProgress = false;
        });
      }
    }
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
          'Розіграш призів',
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
        child: isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Інформація про збір
                      _buildFundraisingInfo(),
                      const SizedBox(height: 16),

                      // Призи
                      _buildPrizesSection(),
                      const SizedBox(height: 16),

                      // Учасники розіграшу
                      _buildParticipantsSection(),
                      const SizedBox(height: 16),

                      // Кнопка розіграшу або результати
                      if (fundraising?.raffleWinners?.isNotEmpty == true)
                        _buildRaffleResults()
                      else if (isRaffleInProgress)
                        _buildRaffleInProgress()
                      else
                        _buildRaffleButton(),

                      const SizedBox(height: 16),
                      if (isRaffleCompleted) ...[
                        CustomElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.createReportScreen,
                              arguments: {
                                'activity': ActivityModel(
                                  type: ActivityType.fundraiserCreation,
                                  entityId: fundraising!.id!,
                                  title: fundraising!.title!,
                                  description: fundraising!.description,
                                  timestamp: fundraising!.timestamp!,
                                ),
                              },
                            );
                          },
                          backgroundColor: appThemeColors.successGreen,
                          borderRadius: 12,
                          height: 50,
                          text: 'Додати звіт',
                          textStyle: TextStyleHelper.instance.title16Bold
                              .copyWith(color: appThemeColors.primaryWhite),
                        ),
                        const SizedBox(height: 12),
                      ],
                      CustomElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        backgroundColor: appThemeColors.backgroundLightGrey,
                        borderRadius: 12,
                        height: 50,
                        text: 'Назад до профілю',
                        textStyle: TextStyleHelper.instance.title16Bold
                            .copyWith(color: appThemeColors.blueAccent),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFundraisingInfo() {
    return Container(
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
          Text(
            fundraising?.title ?? 'Збір коштів',
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.casino,
                size: 20,
                color: appThemeColors.backgroundLightGrey,
              ),
              const SizedBox(width: 8),
              Text(
                'Ціна квитка: ${NumberFormat('#,###').format(fundraising?.ticketPrice ?? 100)} грн',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrizesSection() {
    return Container(
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
          Text(
            'Призи (${fundraising?.prizes?.length ?? 0})',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          const SizedBox(height: 8),
          if (fundraising?.prizes?.isNotEmpty == true)
            ...fundraising!.prizes!.asMap().entries.map((entry) {
              final index = entry.key;
              final prize = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: appThemeColors.backgroundLightGrey.withAlpha(77),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyleHelper.instance.title13Regular
                              .copyWith(
                                color: appThemeColors.backgroundLightGrey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prize,
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.backgroundLightGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            Text(
              'Призи не вказані',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(178),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final totalTickets = donorTickets.values.fold(
      0,
      (sum, donor) => sum + donor.ticketCount,
    );
    final sortedDonors = donorTickets.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Учасники розіграшу',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
              Text(
                'Всього квитків: $totalTickets',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (donorTickets.isEmpty)
            Center(
              child: Text(
                'Немає учасників розіграшу',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey.withAlpha(178),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedDonors.length,
              separatorBuilder: (context, index) => Divider(
                color: appThemeColors.backgroundLightGrey.withAlpha(77),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final donor = sortedDonors.elementAt(index);
                return _buildParticipantItem(donor);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(DonorTickets donor) {
    return FutureBuilder<BaseProfileModel?>(
      future: Provider.of<ProfileViewModel>(
        context,
        listen: false,
      ).fetchUser(donor.donorId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 0,
          ),
          leading: isLoading
              ? const CircularProgressIndicator()
              : UserAvatarWithFrame(
                  size: 20,
                  role: user?.role!,
                  uid: donor.donorId,
                  photoUrl: user?.photoUrl,
                  frame: user is VolunteerModel ? user.frame : null,
                ),
          title: Text(
            donor.donorName,
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Донатів: ${donor.donations.length}',
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey.withAlpha(178),
                ),
              ),
              Text(
                'Загальна сума: ${NumberFormat('#,###').format(donor.totalAmount)} грн',
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey.withAlpha(178),
                ),
              ),
            ],
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
              '${donor.ticketCount} квитків',
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

  Widget _buildRaffleButton() {
    final canRaffle =
        donorTickets.isNotEmpty && fundraising?.prizes?.isNotEmpty == true;

    return CustomElevatedButton(
      onPressed: canRaffle ? _onCompleteRaffle : null,
      backgroundColor: canRaffle
          ? appThemeColors.errorRed
          : appThemeColors.textMediumGrey,
      borderRadius: 12,
      height: 50,
      text: 'Провести розіграш',
      textStyle: TextStyleHelper.instance.title16Bold.copyWith(
        color: appThemeColors.primaryWhite,
      ),
    );
  }

  Widget _buildRaffleInProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appThemeColors.backgroundLightGrey.withAlpha(77),
        ),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Проводиться розіграш...',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaffleResults() {
    return Container(
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
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: appThemeColors.backgroundLightGrey,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Переможці розіграшу',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (fundraising!.raffleWinners!.isEmpty)
            Text(
              'Переможців не визначено',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(178),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fundraising!.raffleWinners!.length,
              itemBuilder: (context, index) {
                final winner = fundraising!.raffleWinners![index];
                return _buildWinnerItem(winner, index + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWinnerItem(RaffleWinnerModel winner, int place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appThemeColors.lightGreenColor.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appThemeColors.lightGreenColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: appThemeColors.lightGreenColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$place',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.donorName,
                  style: TextStyleHelper.instance.title16Bold.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
                Text(
                  winner.prize,
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonorTickets {
  final String donorId;
  final String donorName;
  double totalAmount;
  int ticketCount;
  final List<DonationModel> donations;

  DonorTickets({
    required this.donorId,
    required this.donorName,
    required this.totalAmount,
    required this.ticketCount,
    required this.donations,
  });
}
