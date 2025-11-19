import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/medal_model.dart';
import 'package:helphub/widgets/profile/medal_item.dart';

import '../../data/services/tournament_service.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

class AllMedalsScreen extends StatelessWidget {
  const AllMedalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final tournamentService = TournamentService();
    final targetUserId = auth.currentUser?.uid;
    if (targetUserId == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.9, -0.4),
            end: Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: appThemeColors.lightGreenColor,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Мої медалі',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.9, -0.4),
            end: const Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: StreamBuilder<List<MedalModel>>(
          stream: tournamentService.getUserMedals(targetUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.blueTransparent,
                ),
              );
            }
            final medals = snapshot.data!;
            medals.sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
            if (medals.isEmpty) {
              return Center(
                child: Text(
                  'У вас поки немає моделей',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final medal = medals[index];
                return MedalItemWidget(medalItemModel: medal);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: medals.length,
            );
          },
        ),
      ),
    );
  }
}
