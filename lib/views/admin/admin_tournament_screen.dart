import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/admin/admin_view_model.dart';
import '../../widgets/custom_elevated_button.dart';

class AdminTournamentScreen extends StatefulWidget {
  const AdminTournamentScreen({super.key});

  @override
  State<AdminTournamentScreen> createState() => _AdminTournamentScreenState();
}

class _AdminTournamentScreenState extends State<AdminTournamentScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedSeasonId;
  File? _goldMedalImage;
  File? _silverMedalImage;
  File? _bronzeMedalImage;
  String? _goldMedalUrl;
  String? _silverMedalUrl;
  String? _bronzeMedalUrl;

  bool _isLoadingData = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _generateCurrentSeasonId();
    _fetchSeasonMedals();
  }

  void _generateCurrentSeasonId() {
    final now = DateTime.now();
    _selectedSeasonId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchSeasonMedals() async {
    if (_selectedSeasonId == null) return;

    setState(() {
      _isLoadingData = true;
      _goldMedalUrl = null;
      _silverMedalUrl = null;
      _bronzeMedalUrl = null;
      _goldMedalImage = null;
      _silverMedalImage = null;
      _bronzeMedalImage = null;
    });

    Future<String?> getMedalUrl(String type) async {
      try {
        final path = 'medals/$_selectedSeasonId/$type.png';
        final ref = FirebaseStorage.instance.ref().child(path);
        return await ref.getDownloadURL();
      } catch (e) {
        return null;
      }
    }

    final results = await Future.wait([
      getMedalUrl('gold'),
      getMedalUrl('silver'),
      getMedalUrl('bronze'),
    ]);

    if (mounted) {
      setState(() {
        _goldMedalUrl = results[0];
        _silverMedalUrl = results[1];
        _bronzeMedalUrl = results[2];
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Турнірні сезони',
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
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: _isLoadingData
            ? Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.primaryWhite,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeasonSelector(),
                    if (_isPastSeason)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appThemeColors.errorLight.withAlpha(150),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: appThemeColors.errorLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: appThemeColors.errorLight,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Цей сезон завершено. Редагування медалей недоступне.',
                                  style: TextStyle(
                                    color: appThemeColors.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildMedalUploadSection(),
                    const SizedBox(height: 24),
                    _buildUploadButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSeasonSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: appThemeColors.blueAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Оберіть сезон',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: appThemeColors.blueMixedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appThemeColors.blueAccent.withAlpha(85),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSeasonId(_selectedSeasonId!),
                  style: TextStyleHelper.instance.title16Bold.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: Icon(
                        Icons.chevron_left,
                        color: appThemeColors.blueAccent,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: Icon(
                        Icons.chevron_right,
                        color: appThemeColors.blueAccent,
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

  String _formatSeasonId(String seasonId) {
    final parts = seasonId.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    final monthNames = [
      'Січень',
      'Лютий',
      'Березень',
      'Квітень',
      'Травень',
      'Червень',
      'Липень',
      'Серпень',
      'Вересень',
      'Жовтень',
      'Листопад',
      'Грудень',
    ];
    return '${monthNames[month - 1]} $year';
  }

  void _previousMonth() {
    final parts = _selectedSeasonId!.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    if (month == 1) {
      _selectedSeasonId = '${year - 1}-12';
    } else {
      _selectedSeasonId = '$year-${(month - 1).toString().padLeft(2, '0')}';
    }
    setState(() {
      _fetchSeasonMedals();
    });
  }

  void _nextMonth() {
    final parts = _selectedSeasonId!.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    if (month == 12) {
      _selectedSeasonId = '${year + 1}-01';
    } else {
      _selectedSeasonId = '$year-${(month + 1).toString().padLeft(2, '0')}';
    }
    setState(() {
      _fetchSeasonMedals();
    });
  }

  Widget _buildMedalUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: appThemeColors.goldColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Медалі сезону',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMedalUploadCard(
            'Золота медаль',
            'Для 1 місця (1 волонтер)',
            appThemeColors.goldColor,
            _goldMedalImage,
            _goldMedalUrl,
            () => _pickMedalImage('gold'),
            () => _removeMedalImage('gold'),
          ),
          const SizedBox(height: 12),
          _buildMedalUploadCard(
            'Срібна медаль',
            'Для 2-3 місць (2 волонтери)',
            Colors.grey.shade400,
            _silverMedalImage,
            _silverMedalUrl,
            () => _pickMedalImage('silver'),
            () => _removeMedalImage('silver'),
          ),
          const SizedBox(height: 12),
          _buildMedalUploadCard(
            'Бронзова медаль',
            'Для 4-10 місць (7 волонтерів)',
            Colors.brown.shade400,
            _bronzeMedalImage,
            _bronzeMedalUrl,
            () => _pickMedalImage('bronze'),
            () => _removeMedalImage('bronze'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalUploadCard(
    String title,
    String description,
    Color color,
    File? imageFile,
    String? imageUrl,
    VoidCallback onPick,
    VoidCallback onRemove,
  ) {
    final bool hasContent = imageFile != null || imageUrl != null;
    final bool isReadOnly = _isPastSeason;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.emoji_events, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.primaryBlack,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isReadOnly)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.lock, color: appThemeColors.textMediumGrey),
                ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: appThemeColors.primaryWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageFile != null
                      ? Image.file(imageFile, fit: BoxFit.contain)
                      : Image.network(imageUrl!, fit: BoxFit.contain),
                ),
              ),
            ),
            if (!isReadOnly) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomElevatedButton(
                    text: 'Змінити',
                    onPressed: onPick,
                    backgroundColor: color,
                    textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryWhite,
                      fontWeight: FontWeight.w700,
                    ),
                    borderRadius: 8,
                    width: 120,
                    height: 36,
                  ),
                  if (imageFile != null) ...[
                    const SizedBox(width: 12),
                    CustomElevatedButton(
                      text: 'Скасувати',
                      onPressed: onRemove,
                      backgroundColor: appThemeColors.errorRed.withAlpha(200),
                      textStyle: TextStyleHelper.instance.title14Regular
                          .copyWith(
                            color: appThemeColors.primaryWhite,
                            fontWeight: FontWeight.w700,
                          ),
                      borderRadius: 8,
                      width: 120,
                      height: 36,
                    ),
                  ],
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            if (!isReadOnly)
              Center(
                child: CustomElevatedButton(
                  text: 'Завантажити',
                  onPressed: onPick,
                  backgroundColor: color,
                  textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  borderRadius: 8,
                  width: 200,
                  height: 44,
                ),
              )
            else
              // Текст для архівних сезонів без медалей
              Center(
                child: Text(
                  'Медаль не була завантажена',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickMedalImage(String medalType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          switch (medalType) {
            case 'gold':
              _goldMedalImage = File(image.path);
              break;
            case 'silver':
              _silverMedalImage = File(image.path);
              break;
            case 'bronze':
              _bronzeMedalImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка вибору зображення: $e');
    }
  }

  void _removeMedalImage(String medalType) {
    setState(() {
      switch (medalType) {
        case 'gold':
          _goldMedalImage = null;
          break;
        case 'silver':
          _silverMedalImage = null;
          break;
        case 'bronze':
          _bronzeMedalImage = null;
          break;
      }
    });
  }

  bool get _isPastSeason {
    if (_selectedSeasonId == null) return false;
    final parts = _selectedSeasonId!.split('-');
    final selectedYear = int.parse(parts[0]);
    final selectedMonth = int.parse(parts[1]);
    final now = DateTime.now();
    if (selectedYear < now.year) return true;
    if (selectedYear == now.year && selectedMonth < now.month) return true;
    return false;
  }

  Widget _buildUploadButton() {
    if (_isPastSeason) return const SizedBox.shrink();
    final bool canUpload =
        _goldMedalImage != null ||
        _silverMedalImage != null ||
        _bronzeMedalImage != null;

    return CustomElevatedButton(
      text: _isUploading ? 'Завантаження...' : 'Зберегти медалі',
      onPressed: canUpload && !_isUploading ? _uploadMedals : null,
      backgroundColor: canUpload
          ? appThemeColors.successGreen
          : appThemeColors.textMediumGrey,
      textStyle: TextStyleHelper.instance.title16Bold.copyWith(
        color: appThemeColors.primaryWhite,
      ),
      borderRadius: 12,
      height: 56,
      width: double.infinity,
    );
  }

  Future<void> _uploadMedals() async {
    if (_selectedSeasonId == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final viewModel = Provider.of<AdminViewModel>(context, listen: false);
      bool allSuccess = true;

      if (_goldMedalImage != null) {
        final success = await viewModel.addMedalToSeason(
          _selectedSeasonId!,
          'gold',
          _goldMedalImage!.path,
        );
        if (!success) allSuccess = false;
      }

      if (_silverMedalImage != null) {
        final success = await viewModel.addMedalToSeason(
          _selectedSeasonId!,
          'silver',
          _silverMedalImage!.path,
        );
        if (!success) allSuccess = false;
      }

      if (_bronzeMedalImage != null) {
        final success = await viewModel.addMedalToSeason(
          _selectedSeasonId!,
          'bronze',
          _bronzeMedalImage!.path,
        );
        if (!success) allSuccess = false;
      }

      if (allSuccess) {
        Constants.showSuccessMessage(context, 'Медалі успішно завантажено!');
        _fetchSeasonMedals();
      } else {
        Constants.showErrorMessage(
          context,
          'Помилка завантаження деяких медалей',
        );
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка завантаження медалей: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
