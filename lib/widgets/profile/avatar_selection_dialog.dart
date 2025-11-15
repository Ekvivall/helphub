import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';

class AvatarSelectionDialog extends StatelessWidget {
  final ProfileViewModel viewModel;
  final VolunteerModel volunteer;

  const AvatarSelectionDialog({
    super.key,
    required this.viewModel,
    required this.volunteer,
  });

  @override
  Widget build(BuildContext context) {
    final int currentLevel = volunteer.currentLevel ?? 0;
    final List<String> unlockedAvatars = Constants.allLevels
        .where((level) => level.level <= currentLevel)
        .map((level) => level.avatarPath)
        .toList();

    return Dialog(
      backgroundColor: appThemeColors.primaryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Виберіть аватар',
                  style: TextStyleHelper.instance.title18Bold,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: unlockedAvatars.length,
                itemBuilder: (context, index) {
                  final avatarPath = unlockedAvatars[index];
                  final isSelected = volunteer.photoUrl == avatarPath;
                  return GestureDetector(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      await viewModel.updateProfileAvatar(avatarPath);
                      navigator.pop();
                      Constants.showSuccessMessage(
                        messenger.context,
                        'Аватар успішно змінено!',
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? appThemeColors.successGreen
                              : appThemeColors.grey200,
                          width: isSelected ? 3 : 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              avatarPath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: appThemeColors.successGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: appThemeColors.primaryWhite,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}