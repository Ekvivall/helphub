import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/models/fundraising_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/fundraising/fundraising_view_model.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class FundraisingDetailScreen extends StatefulWidget {
  final String fundraisingId;

  const FundraisingDetailScreen({super.key, required this.fundraisingId});

  @override
  State<FundraisingDetailScreen> createState() =>
      _FundraisingDetailScreenState();
}

class _FundraisingDetailScreenState extends State<FundraisingDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _isLoadingSave = false;
  bool _showFullDescription = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkSavedStatus;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedStatus() async {
    final viewModel = Provider.of<FundraisingViewModel>(context, listen: false);
    final saved = await viewModel.isFundraisingSaved(widget.fundraisingId);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleSave() async {
    if (_isLoadingSave) return;

    setState(() {
      _isLoadingSave = true;
    });

    final viewModel = Provider.of<FundraisingViewModel>(context, listen: false);
    final error = await viewModel.toggleSaveFundraising(
      widget.fundraisingId,
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
        Constants.showErrorMessage(context, error);
      } else {
        Constants.showSuccessMessage(
          context,
          _isSaved ? 'Збір збережено' : 'Збір видалено зі збережених',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FundraisingViewModel>(
      builder: (context, viewModel, child) {
        final fundraising = viewModel.filteredFundraisings
            .where((f) => f.id == widget.fundraisingId)
            .firstOrNull;

        if (fundraising == null) {
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
            ),
            body: Center(
              child: Text(
                'Збір не знайдено',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: appThemeColors.backgroundLightGrey,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.9, -0.4),
                end: Alignment(-0.9, 0.4),
                colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(fundraising),
                SliverToBoxAdapter(
                  child: _buildContent(fundraising, viewModel),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomActionBar(fundraising),
        );
      },
    );
  }

  Widget _buildSliverAppBar(FundraisingModel fundraising) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: appThemeColors.appBarBg,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: appThemeColors.primaryWhite.withAlpha(230),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: appThemeColors.primaryBlack),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appThemeColors.primaryWhite.withAlpha(230),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _shareContent,
            icon: Icon(Icons.share, color: appThemeColors.primaryBlack),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appThemeColors.primaryWhite.withAlpha(230),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _toggleSave,
            icon: _isLoadingSave
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appThemeColors.blueAccent,
                    ),
                  )
                : Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved
                        ? appThemeColors.blueAccent
                        : appThemeColors.primaryBlack,
                  ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (fundraising.photoUrl != null)
              CachedNetworkImage(
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
                    size: 64,
                  ),
                ),
              )
            else
              Container(
                color: appThemeColors.textMediumGrey.withAlpha(77),
                child: Icon(
                  Icons.volunteer_activism,
                  color: appThemeColors.textMediumGrey,
                  size: 64,
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    appThemeColors.primaryBlack.withAlpha(128),
                  ],
                ),
              ),
            ),
            // Urgent badge
            if (fundraising.isUrgent == true)
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: appThemeColors.errorRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'ТЕРМІНОВО',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (fundraising.hasRaffle == true)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: appThemeColors.cyanAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Є РОЗІГРАШ',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _shareContent() {
    final fundraising =
        Provider.of<FundraisingViewModel>(context, listen: false)
            .filteredFundraisings
            .where((f) => f.id == widget.fundraisingId)
            .firstOrNull;

    if (fundraising != null) {
      Share.share(
        'Допоможіть збору "${fundraising.title}" від ${fundraising.organizationName}\n\n'
        'Зібрано: ${Constants.formatAmount(fundraising.currentAmount ?? 0)} ₴\n'
        'Ціль: ${Constants.formatAmount(fundraising.targetAmount ?? 0)} ₴\n\n'
        '${fundraising.description ?? ""}\n\n'
        'Переглянути збір у додатку HelpHub',
        subject: 'Збір коштів: ${fundraising.title}',
      );
    }
  }

  Widget _buildContent(
    FundraisingModel fundraising,
    FundraisingViewModel viewModel,
  ) {
    final progress =
        fundraising.targetAmount != null && fundraising.targetAmount! > 0
        ? (fundraising.currentAmount ?? 0) / fundraising.targetAmount!
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main info section
        Container(
          color: appThemeColors.primaryWhite,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fundraising.title ?? 'Без назви',
                style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.organizationProfileScreen,
                  arguments: fundraising.organizationId,
                ),
                child: Text(
                  fundraising.organizationName ?? 'Невідома організація',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildProgressSection(fundraising, progress),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tabs section
        Container(
          color: appThemeColors.primaryWhite,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: appThemeColors.blueAccent,
                unselectedLabelColor: appThemeColors.textMediumGrey,
                indicatorColor: appThemeColors.blueAccent,
                labelStyle: TextStyleHelper.instance.title14Regular.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Опис'),
                  Tab(text: 'Деталі'),
                  Tab(text: 'Документи'),
                ],
              ),
              Container(
                height: 378,
                padding: const EdgeInsets.all(20),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDescriptionTab(fundraising),
                    _buildDetailsTab(fundraising),
                    _buildDocumentsTab(fundraising),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(FundraisingModel fundraising, double progress) {
    final daysRemaining = Constants.calculateDaysRemaining(fundraising.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Зібрано',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
                Text(
                  '${Constants.formatAmount(fundraising.currentAmount ?? 0)} ₴',
                  style: TextStyleHelper.instance.title20Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Ціль',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
                Text(
                  '${Constants.formatAmount(fundraising.targetAmount ?? 0)} ₴',
                  style: TextStyleHelper.instance.title20Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: appThemeColors.textMediumGrey.withAlpha(77),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0
                ? appThemeColors.successGreen
                : appThemeColors.blueAccent,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(1)}% зібрано',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (daysRemaining != null)
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: daysRemaining > 7
                        ? appThemeColors.textMediumGrey
                        : appThemeColors.errorRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Constants.formatDaysRemaining(daysRemaining),
                    style: TextStyleHelper.instance.title14Regular.copyWith(
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
    );
  }

  Widget _buildDescriptionTab(FundraisingModel fundraising) {
    final description = fundraising.description ?? 'Опис відсутній';
    final shouldTruncate = description.length > 300;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shouldTruncate && !_showFullDescription
                ? '${description.substring(0, 300)}...'
                : description,
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.primaryBlack,
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
          if (shouldTruncate) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _showFullDescription = !_showFullDescription;
                });
              },
              child: Text(
                _showFullDescription ? 'Показати менше' : 'Показати більше',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (fundraising.categories != null &&
              fundraising.categories!.isNotEmpty) ...[
            Text(
              'Категорії:',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fundraising.categories!.map((category) {
                return CategoryChipWidget(chip: category);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(FundraisingModel fundraising) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Організація:',
            fundraising.organizationName ?? 'Невідома організація',
          ),
          _buildDetailRow(
            'Початок збору:',
            fundraising.startDate != null
                ? Constants.formatDate(fundraising.startDate!)
                : 'Не вказано',
          ),
          _buildDetailRow(
            'Завершення збору:',
            fundraising.endDate != null
                ? Constants.formatDate(fundraising.endDate!)
                : 'Не вказано',
          ),
          _buildDetailRow(
            'Дата створення:',
            fundraising.timestamp != null
                ? Constants.formatDate(fundraising.timestamp!)
                : 'Не вказано',
          ),
          _buildDetailRow(
            'Кількість донатерів:',
            '${fundraising.donorIds?.length ?? 0}',
          ),
          if (fundraising.relatedApplicationIds != null &&
              fundraising.relatedApplicationIds!.isNotEmpty)
            _buildDetailRow(
              'Пов\'язані заявки:',
              '${fundraising.relatedApplicationIds!.length}',
            ),
          if (fundraising.hasRaffle == true) ...[
            Text(
              'Інформація про розіграш:',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            if (fundraising.ticketPrice != null)
              _buildDetailRow(
                'Вартість квитка:',
                '${fundraising.ticketPrice!.toStringAsFixed(2)} грн',
              ),
            if (fundraising.prizes != null && fundraising.prizes!.isNotEmpty)
              _buildPrizesList(fundraising.prizes!),
            const SizedBox(height: 16),
          ],
          Text(
            'Реквізити для допомоги:',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          if (fundraising.privatBankCard?.isNotEmpty ?? false)
            _buildBankInfoRow(
              context,
              'PrivatBank',
              ImageConstant.privatLogo,
              fundraising.privatBankCard!,
            ),
          if (fundraising.monoBankCard?.isNotEmpty ?? false)
            _buildBankInfoRow(
              context,
              'Monobank',
              ImageConstant.monoLogo,
              fundraising.monoBankCard!,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(FundraisingModel fundraising) {
    if (fundraising.documentUrls == null || fundraising.documentUrls!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: appThemeColors.textMediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Документи відсутні',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: fundraising.documentUrls!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final documentUrl = fundraising.documentUrls![index];
        final fileName = Constants.getFileNameFromUrl(documentUrl);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appThemeColors.backgroundLightGrey.withAlpha(77),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appThemeColors.textMediumGrey.withAlpha(77),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Constants.getDocumentIcon(fileName),
                color: appThemeColors.blueAccent,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Документ ${index + 1}',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.primaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Constants.openDocument(context, documentUrl),
                icon: Icon(Icons.open_in_new, color: appThemeColors.blueAccent),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankInfoRow(
    BuildContext context,
    String bankName,
    String logoAsset,
    String cardNumber,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Image.asset(logoAsset, height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cardNumber,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                fontFamily: 'monospace',
                color: appThemeColors.primaryBlack,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Constants.copyToClipboard(context, cardNumber),
            icon: Icon(Icons.copy, size: 20, color: appThemeColors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(FundraisingModel fundraising) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.donationScreen, arguments: fundraising);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.blueAccent,
                foregroundColor: appThemeColors.primaryWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volunteer_activism,
                    color: appThemeColors.primaryWhite,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Допомогти',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _shareContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: appThemeColors.backgroundLightGrey,
              foregroundColor: appThemeColors.blueAccent,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Icon(Icons.share, color: appThemeColors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizesList(List<String> prizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Призи:', ''),
        ...prizes
            .map(
              (prize) => Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: appThemeColors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prize,
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            ,
      ],
    );
  }
}
