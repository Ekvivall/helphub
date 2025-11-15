import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/level_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';

import '../../theme/text_style_helper.dart';
import '../custom_image_view.dart';

class LevelUpDialog extends StatefulWidget {
  final LevelModel newLevel;
  final int newPoints;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.newPoints,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();

  static void show(BuildContext context, LevelModel newLevel, int newPoints) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          LevelUpDialog(newLevel: newLevel, newPoints: newPoints),
    );
  }
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _confettiController.play();
    _animationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: appThemeColors.transparent,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: [
                appThemeColors.blueAccent,
                appThemeColors.lightGreenColor,
                appThemeColors.successGreen,
                appThemeColors.orangeAccent,
              ],
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: appThemeColors.primaryWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(11),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: appThemeColors.textMediumGrey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    Text(
                      'Вітаємо!',
                      style: TextStyleHelper.instance.headline24SemiBold
                          .copyWith(color: appThemeColors.blueAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Новий рівень!',
                      style: TextStyleHelper.instance.title20Regular.copyWith(
                        color: appThemeColors.primaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            appThemeColors.blueAccent.withAlpha(47),
                            appThemeColors.blueAccent.withAlpha(11),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appThemeColors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        widget.newLevel.title,
                        style: TextStyleHelper.instance.title18Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${widget.newLevel.description}"',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appThemeColors.backgroundLightGrey.withAlpha(11),
                        borderRadius: BorderRadius.circular(47),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: appThemeColors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Твої бали: ${widget.newPoints}',
                            style: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.primaryBlack),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appThemeColors.lightGreenColor.withAlpha(11),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: appThemeColors.lightGreenColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Positioned(
                                top: 10,
                                left: 6,
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor:
                                      appThemeColors.lightGreenColor,
                                  backgroundImage:
                                      AssetImage(widget.newLevel.avatarPath)
                                          as ImageProvider,
                                ),
                              ),
                              CustomImageView(
                                imagePath: widget.newLevel.framePath,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Розблоковано нові рамку та аватар!',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    color: appThemeColors.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CustomElevatedButton(
                            text: 'Переглянути профіль',
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.volunteerProfileScreen);
                            },
                            backgroundColor: appThemeColors.blueAccent,
                            textStyle: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.primaryWhite),
                            borderRadius: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.editUserProfileScreen);
                      },
                      icon: Icon(
                        Icons.edit,
                        color: appThemeColors.textMediumGrey,
                        size: 20,
                      ),
                      label: Text(
                        'Редагувати профіль',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
