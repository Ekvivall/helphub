import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helphub/models/report_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/custom_text_field.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_router.dart';
import '../../view_models/report/report_view_model.dart';

class ViewReportScreen extends StatefulWidget {
  final String reportId;
  final bool
  canLeaveFeedback; // Чи може користувач залишити відгук про організатора

  const ViewReportScreen({
    super.key,
    required this.reportId,
    this.canLeaveFeedback = false,
  });

  @override
  State<ViewReportScreen> createState() => _ViewReportScreenState();
}

class _ViewReportScreenState extends State<ViewReportScreen> {
  bool _isSubmittingFeedback = false;

  // Для відгуку про організатора
  final TextEditingController _feedbackController = TextEditingController();
  int? _selectedRating;
  bool _isAnonymousFeedback = false;
  bool _showFeedbackForm = false;
  bool _hasUserLeftFeedback = false;

  late ReportViewModel _reportViewModel;

  @override
  void initState() {
    super.initState();
    _reportViewModel = Provider.of<ReportViewModel>(context, listen: false);
    _loadReport();
    if (widget.canLeaveFeedback) {
      _checkUserFeedback();
    }
  }

  Future<void> _loadReport() async {
    await _reportViewModel.loadReport(widget.reportId);
  }

  Future<void> _checkUserFeedback() async {
    final hasLeft = await _reportViewModel.hasUserLeftFeedback(widget.reportId);
    setState(() {
      _hasUserLeftFeedback = hasLeft;
    });
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty && _selectedRating == null) {
      Constants.showErrorMessage(
        context,
        'Будь ласка, залиште відгук або оцінку',
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      final error = await _reportViewModel.addOrganizerFeedback(
        widget.reportId,
        _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        _selectedRating,
        _isAnonymousFeedback,
      );

      if (error == null && mounted) {
        Constants.showSuccessMessage(context, 'Відгук успішно додано!');
        setState(() {
          _showFeedbackForm = false;
          _feedbackController.clear();
          _selectedRating = null;
          _isAnonymousFeedback = false;
          _hasUserLeftFeedback = true;
        });
      } else if (error != null && mounted) {
        Constants.showErrorMessage(context, error);
      }
    } catch (e) {
      if (mounted) {
        Constants.showErrorMessage(context, 'Помилка додавання відгуку: $e');
      }
    } finally {
      setState(() {
        _isSubmittingFeedback = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Constants.showErrorMessage(context, 'Не вдалося відкрити файл');
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка при відкритті файлу: $e');
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.contains('/')) {
        return path.split('/').last;
      }
      return 'Документ';
    } catch (e) {
      return 'Документ';
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportViewModel>(
      builder: (context, viewModel, child) {
        final report = viewModel.currentReport;
        final isCurrentUserOrganizer =
            report?.organizerId == viewModel.currentUserId;

        return Scaffold(
          backgroundColor: appThemeColors.blueAccent,
          appBar: AppBar(
            backgroundColor: appThemeColors.appBarBg,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back,
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            title: Text(
              'Звіт про активність',
              style: TextStyleHelper.instance.title20Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              if (isCurrentUserOrganizer)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).pushNamed(
                        AppRoutes.createReportScreen,
                        arguments: {'reportId': widget.reportId},
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Редагувати'),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
            ],
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
            child: viewModel.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: appThemeColors.blueAccent,
                    ),
                  )
                : viewModel.errorMessage != null || report == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: appThemeColors.errorRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            viewModel.errorMessage ?? 'Звіт не знайдено',
                            textAlign: TextAlign.center,
                            style: TextStyleHelper.instance.title16Regular
                                .copyWith(color: appThemeColors.primaryBlack),
                          ),
                          const SizedBox(height: 16),
                          CustomElevatedButton(
                            onPressed: _loadReport,
                            text: 'Спробувати знову',
                            backgroundColor: appThemeColors.blueAccent,
                            textStyle: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.primaryWhite),
                            borderRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок та основна інформація
                        _buildHeaderSection(report),
                        const SizedBox(height: 20),

                        // Опис роботи
                        _buildWorkDescriptionSection(report),
                        const SizedBox(height: 20),

                        // Статистика
                        if (_hasStatistics(report)) ...[
                          _buildStatisticsSection(report),
                          const SizedBox(height: 20),
                        ],

                        // Досягнення
                        if (report.achievements != null &&
                            report.achievements!.isNotEmpty) ...[
                          _buildAchievementsSection(report),
                          const SizedBox(height: 20),
                        ],

                        // Труднощі та рекомендації
                        if (report.difficulties != null &&
                            report.difficulties!.isNotEmpty) ...[
                          _buildDifficultiesSection(report),
                          const SizedBox(height: 20),
                        ],

                        // Фотографії
                        if (report.photoUrls.isNotEmpty) ...[
                          _buildPhotosSection(report),
                          const SizedBox(height: 20),
                        ],

                        // Документи
                        if (report.documentUrls.isNotEmpty) ...[
                          _buildDocumentsSection(report),
                          const SizedBox(height: 20),
                        ],

                        // Відгуки про організатора (від учасників)
                        if (report.organizerFeedback.isNotEmpty) ...[
                          _buildOrganizerFeedbackSection(report),
                          const SizedBox(height: 20),
                        ],

                        // Форма для залишення відгуку (якщо користувач може залишити відгук)
                        if (widget.canLeaveFeedback &&
                            !_hasUserLeftFeedback) ...[
                          _buildFeedbackFormSection(),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getActivityTypeColor(report),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getActivityTypeLabel(report),
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(report.createdAt),
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.activityTitle,
            style: TextStyleHelper.instance.title20Regular.copyWith(
              color: appThemeColors.primaryBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: appThemeColors.textMediumGrey,
              ),
              const SizedBox(width: 4),
              Text(
                'Організатор: ${report.organizerName}',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
            ],
          ),
          if (report.updatedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.update,
                  size: 16,
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Оновлено: ${DateFormat('dd.MM.yyyy HH:mm').format(report.updatedAt!)}',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkDescriptionSection(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Опис виконаної роботи',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.workDescription,
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.primaryBlack,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              if (report.participantsCount != null)
                _buildStatItem(
                  Icons.people,
                  'Учасників',
                  report.participantsCount.toString(),
                  appThemeColors.blueAccent,
                ),
              if (report.fundsRaised != null)
                _buildStatItem(
                  Icons.attach_money,
                  'Зібрано коштів',
                  '${report.fundsRaised!.toStringAsFixed(0)} грн',
                  appThemeColors.successGreen,
                ),
              if (report.tasksCompleted != null)
                _buildStatItem(
                  Icons.check_circle,
                  'Завершено завдань',
                  report.tasksCompleted.toString(),
                  appThemeColors.successGreen,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              Text(
                label,
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: appThemeColors.lightGreenColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Досягнуті результати',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.achievements!,
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.primaryBlack,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultiesSection(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: appThemeColors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Труднощі та рекомендації',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.difficulties!,
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.primaryBlack,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(ReportModel _report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: appThemeColors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Фотографії',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _report.photoUrls.length,
              itemBuilder: (context, index) {
                final photoUrl = _report.photoUrls[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 120,
                  height: 120,
                  child: GestureDetector(
                    onTap: () => Constants.showImageDialog(context, photoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: appThemeColors.backgroundLightGrey,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: appThemeColors.blueAccent,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: appThemeColors.errorRed.withAlpha(77),
                            child: Icon(
                              Icons.broken_image,
                              color: appThemeColors.errorRed,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(ReportModel _report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                color: appThemeColors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Документи',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_report.documentUrls.length, (index) {
            final documentUrl = _report.documentUrls[index];
            final fileName = _getFileNameFromUrl(documentUrl);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _openUrl(documentUrl),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appThemeColors.backgroundLightGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: appThemeColors.textMediumGrey.withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: appThemeColors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyleHelper.instance.title14Regular
                              .copyWith(color: appThemeColors.primaryBlack),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        color: appThemeColors.textMediumGrey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrganizerFeedbackSection(ReportModel _report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.feedback,
                color: appThemeColors.successGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Відгуки про активність',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_report.organizerFeedback.length, (index) {
            final feedback = _report.organizerFeedback[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appThemeColors.successGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appThemeColors.successGreen.withAlpha(77),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feedback.participantName,
                          style: TextStyleHelper.instance.title16Bold.copyWith(
                            color: appThemeColors.primaryBlack,
                          ),
                        ),
                      ),
                      if (feedback.rating != null)
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              Icons.star,
                              size: 16,
                              color: starIndex < feedback.rating!
                                  ? appThemeColors.yellowColor
                                  : appThemeColors.textMediumGrey.withAlpha(77),
                            );
                          }),
                        ),
                    ],
                  ),
                  if (feedback.feedback != null &&
                      feedback.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      feedback.feedback!,
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.primaryBlack,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedbackFormSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_comment,
                color: appThemeColors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Залишити відгук про організатора',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_showFeedbackForm) ...[
            Text(
              'Поділіться своїм досвідом участі в цій активності',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
            const SizedBox(height: 12),
            CustomElevatedButton(
              onPressed: () {
                setState(() {
                  _showFeedbackForm = true;
                });
              },
              text: 'Написати відгук',
              backgroundColor: appThemeColors.blueAccent,
              textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: 8,
              height: 36,
            ),
          ] else ...[
            const SizedBox(height: 12),
            // Рейтинг
            Row(
              children: [
                Text(
                  'Оцінка: ',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                ...List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 28,
                      color:
                          (_selectedRating != null && index < _selectedRating!)
                          ? appThemeColors.yellowColor
                          : appThemeColors.textMediumGrey.withAlpha(77),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                if (_selectedRating != null)
                  Text(
                    '$_selectedRating/5',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Текстовий відгук
            CustomTextField(
              controller: _feedbackController,
              label: 'Ваш відгук',
              hintText: 'Розкажіть про свій досвід участі...',
              labelColor: appThemeColors.primaryBlack,
              inputType: TextInputType.multiline,
              maxLines: 4,
              isRequired: false,
            ),
            const SizedBox(height: 16),
            // Анонімність
            Row(
              children: [
                Checkbox(
                  value: _isAnonymousFeedback,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymousFeedback = value ?? false;
                    });
                  },
                  activeColor: appThemeColors.blueAccent,
                ),
                Expanded(
                  child: Text(
                    'Залишити відгук анонімно',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Кнопки
            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: _isSubmittingFeedback
                        ? null
                        : () {
                            setState(() {
                              _showFeedbackForm = false;
                              _feedbackController.clear();
                              _selectedRating = null;
                              _isAnonymousFeedback = false;
                            });
                          },
                    text: 'Скасувати',
                    backgroundColor: appThemeColors.textMediumGrey,
                    textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    borderRadius: 8,
                    height: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                    isLoading: _isSubmittingFeedback,
                    text: 'Відправити',
                    backgroundColor: appThemeColors.successGreen,
                    textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    borderRadius: 8,
                    height: 36,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getActivityTypeLabel(ReportModel _report) {
    switch (_report.activityType) {
      case ActivityReportType.event:
        return 'ПОДІЯ';
      case ActivityReportType.project:
        return 'ПРОЄКТ';
      case ActivityReportType.fundraising:
        return 'ЗБІР КОШТІВ';
    }
  }

  Color _getActivityTypeColor(ReportModel _report) {
    switch (_report.activityType) {
      case ActivityReportType.event:
        return appThemeColors.blueAccent;
      case ActivityReportType.project:
        return appThemeColors.successGreen;
      case ActivityReportType.fundraising:
        return appThemeColors.lightGreenColor;
    }
  }

  bool _hasStatistics(ReportModel _report) {
    return _report.participantsCount != null ||
        _report.fundsRaised != null ||
        _report.tasksCompleted != null;
  }
}
