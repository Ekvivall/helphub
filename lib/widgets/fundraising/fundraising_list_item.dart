import 'package:flutter/material.dart';
import 'package:helphub/data/models/fundraising_model.dart';
import 'package:helphub/view_models/fundraising/fundraising_view_model.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';

import '../../core/utils/image_constant.dart';
import '../../routes/app_router.dart';

class FundraisingListItem extends StatefulWidget {
  final FundraisingModel fundraising;
  final FundraisingViewModel viewModel;

  const FundraisingListItem({
    super.key,
    required this.fundraising,
    required this.viewModel,
  });

  @override
  State<FundraisingListItem> createState() => _FundraisingListItemState();
}

class _FundraisingListItemState extends State<FundraisingListItem> {
  bool _isSaved = false;
  bool _isLoadingSave = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    if (widget.fundraising.id != null) {
      final saved = await widget.viewModel.isFundraisingSaved(
        widget.fundraising.id!,
      );
      if (mounted) {
        setState(() {
          _isSaved = saved;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    if (widget.fundraising.id == null || _isLoadingSave) return;

    setState(() {
      _isLoadingSave = true;
    });

    final error = await widget.viewModel.toggleSaveFundraising(
      widget.fundraising.id!,
      _isSaved,
    );

    if (mounted) {
      setState(() {
        _isLoadingSave = false;
        if (error == null) {
          _isSaved = !_isSaved;
        }
      });

      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fundraising = widget.fundraising;
    final progress =
        fundraising.targetAmount != null && fundraising.targetAmount! > 0
        ? (fundraising.currentAmount ?? 0) / fundraising.targetAmount!
        : 0.0;

    final daysRemaining = _calculateDaysRemaining();

    return Container(
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and urgent badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: fundraising.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: fundraising.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: appThemeColors.textMediumGrey.withAlpha(77),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: appThemeColors.blueAccent,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: appThemeColors.textMediumGrey.withAlpha(77),
                            child: Icon(
                              Icons.image_not_supported,
                              color: appThemeColors.textMediumGrey,
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          color: appThemeColors.textMediumGrey.withAlpha(77),
                          child: Icon(
                            Icons.volunteer_activism,
                            color: appThemeColors.textMediumGrey,
                            size: 48,
                          ),
                        ),
                ),
              ),
              // Urgent badge
              if (fundraising.isUrgent == true)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appThemeColors.errorRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ТЕРМІНОВО',
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.primaryWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (fundraising.hasRaffle == true)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appThemeColors.cyanAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Є РОЗІГРАШ',
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.primaryWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              // Save button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleSave,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appThemeColors.primaryWhite.withAlpha(230),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: appThemeColors.primaryBlack.withAlpha(25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingSave
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: appThemeColors.blueAccent,
                            ),
                          )
                        : Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: _isSaved
                                ? appThemeColors.blueAccent
                                : appThemeColors.textMediumGrey,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and organization
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fundraising.title ?? 'Без назви',
                            style: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.primaryBlack),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fundraising.organizationName ??
                                'Невідома організація',
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(
                                  color: appThemeColors.blueAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (fundraising.privatBankCard?.isNotEmpty ?? false) ...[
                      Image.asset(ImageConstant.privatLogo, height: 20),
                      const SizedBox(width: 8),
                    ],
                    if (fundraising.monoBankCard?.isNotEmpty ?? false) ...[
                      Image.asset(ImageConstant.monoLogo, height: 20),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                if (fundraising.description != null) ...[
                  Text(
                    fundraising.description!,
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Categories
                if (fundraising.categories != null &&
                    fundraising.categories!.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: fundraising.categories!.map((category) {
                      return CategoryChipWidget(chip: category);
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Progress bar and amounts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Зібрано: ${_formatAmount(fundraising.currentAmount ?? 0)} грн',
                          style: TextStyleHelper.instance.title14Regular
                              .copyWith(
                                color: appThemeColors.primaryBlack,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: TextStyleHelper.instance.title14Regular
                              .copyWith(
                                color: appThemeColors.blueAccent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: appThemeColors.textMediumGrey.withAlpha(
                        77,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0
                            ? appThemeColors.successGreen
                            : appThemeColors.blueAccent,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ціль: ${_formatAmount(fundraising.targetAmount ?? 0)} грн',
                          style: TextStyleHelper.instance.title14Regular
                              .copyWith(color: appThemeColors.textMediumGrey),
                        ),
                        if (daysRemaining != null)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: daysRemaining > 7
                                    ? appThemeColors.textMediumGrey
                                    : appThemeColors.errorRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDaysRemaining(daysRemaining),
                                style: TextStyleHelper.instance.title13Regular
                                    .copyWith(
                                      color: daysRemaining > 7
                                          ? appThemeColors.textMediumGrey
                                          : appThemeColors.errorRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.fundraisingDetailScreen,
                            arguments: fundraising.id,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appThemeColors.blueAccent,
                          foregroundColor: appThemeColors.primaryWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Переглянути',
                          style: TextStyleHelper.instance.title14Regular
                              .copyWith(
                                color: appThemeColors.primaryWhite,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                              AppRoutes.donationScreen, arguments: fundraising);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: appThemeColors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: appThemeColors.blueAccent,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volunteer_activism,
                              size: 16,
                              color: appThemeColors.blueAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Допомогти',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    color: appThemeColors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _calculateDaysRemaining() {
    if (widget.fundraising.endDate == null) return null;
    final now = DateTime.now();
    final endDate = widget.fundraising.endDate!;
    final difference = endDate.difference(now);
    return difference.inDays;
  }

  String _formatDaysRemaining(int days) {
    if (days < 0) return 'Завершено';
    if (days == 0) return 'Останній день';
    if (days == 1) return '1 день';
    if (days < 5) return '$days дні';
    return '$days днів';
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}М';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}К';
    }
    return amount.toStringAsFixed(0);
  }
}
