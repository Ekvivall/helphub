import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';

import '../../data/models/base_profile_model.dart';
import '../../data/services/tournament_service.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/user_avatar_with_frame.dart';

class TournamentLeaderboardScreen extends StatefulWidget {
  const TournamentLeaderboardScreen({super.key});

  @override
  State<TournamentLeaderboardScreen> createState() =>
      _TournamentLeaderboardScreenState();
}

class _TournamentLeaderboardScreenState
    extends State<TournamentLeaderboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TournamentService _tournamentService = TournamentService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
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
          'Турнірна таблиця',
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
        child: Column(
          children: [
            _buildSeasonInfo(),
            _buildTopThree(currentUserId),
            Expanded(child: _buildLeaderboard(currentUserId)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonInfo() {
    final seasonEnd = _tournamentService.getSeasonEndDate();
    final daysLeft = seasonEnd.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: appThemeColors.goldColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сезон ${_tournamentService.getCurrentSeasonId()}',
                  style: TextStyleHelper.instance.title16Bold,
                ),
                const SizedBox(height: 4),
                Text(
                  'Закінчується через: $daysLeft ${_getDaysWord(daysLeft)}',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree(String currentUserId) {
    return StreamBuilder<List<TournamentUser>>(
      stream: _tournamentService.getUserGroupLeaderboard(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final users = snapshot.data!;
        final top3 = users.take(3).toList();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (top3.length > 1) Expanded(child: _buildTopUser(top3[1], 2)),
              if (top3.isNotEmpty)
                Expanded(flex: 1, child: _buildTopUser(top3[0], 1)),
              if (top3.length > 2) Expanded(child: _buildTopUser(top3[2], 3)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopUser(TournamentUser user, int place) {
    final isFirst = place == 1;
    final height = isFirst ? 140.0 : 110.0;
    final double avatarSize = isFirst ? 30 : 20;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$place',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.primaryWhite,
            fontSize: isFirst ? 36 : 28,
            shadows: [Shadow(color: Colors.black.withAlpha(50), blurRadius: 4)],
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _getMedalColor(place).withAlpha(200),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
              color: appThemeColors.primaryWhite.withAlpha(100),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              UserAvatarWithFrame(
                size: avatarSize,
                role: UserRole.volunteer,
                photoUrl: user.photoUrl,
                frame: user.frame,
                uid: user.uid,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: appThemeColors.primaryWhite.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${user.seasonPoints}',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(String userId) {
    return StreamBuilder<List<TournamentUser>>(
      stream: _tournamentService.getUserGroupLeaderboard(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: appThemeColors.lightGreenColor,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Турнірна таблиця ще не сформована',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          );
        }
        final users = snapshot.data!;
        final listUsers = users.skip(3).toList();
        if (listUsers.isEmpty && listUsers.isNotEmpty) {
          return const SizedBox(height: 20);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listUsers.length,
          itemBuilder: (context, index) {
            final user = listUsers[index];
            final place = index + 4;
            final isCurrentUser = user.uid == userId;
            final isTop10 = place <= 10;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? appThemeColors.lightGreenColor.withAlpha(51)
                    : appThemeColors.primaryWhite.withAlpha(250),
                borderRadius: BorderRadius.circular(12),
                border: isTop10
                    ? Border.all(
                        color: appThemeColors.goldColor.withAlpha(128),
                        width: 1,
                      )
                    : null,
                boxShadow: isCurrentUser
                    ? [
                        BoxShadow(
                          color: appThemeColors.lightGreenColor.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$place',
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.instance.title16Bold.copyWith(
                          color: isTop10
                              ? appThemeColors.goldColor
                              : appThemeColors.textMediumGrey,
                          fontSize: isTop10 ? 18 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    UserAvatarWithFrame(
                      size: 20,
                      role: UserRole.volunteer,
                      photoUrl: user.photoUrl,
                      frame: user.frame,
                      uid: user.uid,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: TextStyleHelper.instance.title16Regular.copyWith(
                          color: appThemeColors.primaryBlack,
                          fontWeight: isCurrentUser
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: appThemeColors.backgroundLightGrey.withAlpha(
                          128,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${user.seasonPoints}',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          fontWeight: FontWeight.bold,
                          color: appThemeColors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDaysWord(int days) {
    final lastDigit = days % 10;
    final lastTwoDigits = days % 100;
    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return 'днів';
    }
    if (lastDigit == 1) {
      return 'день';
    }
    if (lastDigit >= 2 && lastDigit <= 4) {
      return 'дні';
    }
    return 'днів';
  }

  Color _getMedalColor(int place) {
    switch (place) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return appThemeColors.backgroundLightGrey;
    }
  }
}
