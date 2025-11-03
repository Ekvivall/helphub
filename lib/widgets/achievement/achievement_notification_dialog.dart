import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/achievement_item_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_image_view.dart';

class AchievementNotificationDialog extends StatefulWidget {
  final AchievementModel achievement;

  const AchievementNotificationDialog({super.key, required this.achievement});

  @override
  State<AchievementNotificationDialog> createState() =>
      _AchievementNotificationDialogState();

  static void show(BuildContext context, AchievementModel achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          AchievementNotificationDialog(achievement: achievement),
    );
  }
}

class _AchievementNotificationDialogState
    extends State<AchievementNotificationDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
              appThemeColors.lightGreenColor,
              appThemeColors.successGreen,
              appThemeColors.blueAccent,
              appThemeColors.cyanAccent,
              appThemeColors.orangeAccent,
            ],
          ),
        ),
        //Dialog
        FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: appThemeColors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: appThemeColors.primaryWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: appThemeColors.primaryBlack.withAlpha(51),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            appThemeColors.lightGreenColor,
                            appThemeColors.successGreen,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 48,
                        color: appThemeColors.primaryWhite,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нове досягнення',
                      style: TextStyleHelper.instance.headline24SemiBold
                          .copyWith(color: appThemeColors.primaryBlack),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: appThemeColors.lightGreenColor.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: CustomImageView(
                        imagePath: widget.achievement.iconPath,
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Назва досягнення
                    Text(
                      widget.achievement.title,
                      style: TextStyleHelper.instance.title20Regular.copyWith(
                        color: appThemeColors.primaryBlack,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      widget.achievement.description,
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appThemeColors.lightGreenColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Чудово!',
                          style: TextStyleHelper.instance.title16Bold.copyWith(
                            color: appThemeColors.primaryWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
