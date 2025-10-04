import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:provider/provider.dart';

import '../../view_models/faq/faq_view_model.dart';
import '../../widgets/custom_input_field.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  late FAQViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FAQViewModel();
    _viewModel.startListeningToFAQ();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FAQViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: appThemeColors.blueAccent,
        appBar: AppBar(
          backgroundColor: appThemeColors.appBarBg,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              size: 40,
              color: appThemeColors.primaryWhite,
            ),
          ),
          title: Text(
            'Часті запитання',
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
          child: Consumer<FAQViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  _buildSearchBar(viewModel),
                  if (viewModel.categories.isNotEmpty)
                    _buildCategoryFilter(viewModel),
                  Expanded(child: _buildContent(viewModel)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(FAQViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: CustomInputField(
        hintText: 'Пошук питань...',
        controller: _searchController,
        onChanged: (value) {
          viewModel.search(value);
        },
        borderRadius: 10,
        textColor: appThemeColors.primaryBlack,
        hintTextColor: appThemeColors.textMediumGrey,
        borderColor: appThemeColors.transparent,
        focusedBorderColor: appThemeColors.blueAccent,
        suffixIcon: viewModel.isSearching
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  viewModel.clearSearch();
                },
                icon: Icon(Icons.clear, color: appThemeColors.textMediumGrey),
              )
            : null,
      ),
    );
  }

  Widget _buildCategoryFilter(FAQViewModel viewModel) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.categories.length + 1, // + 1 для кнопки ВСІ
        itemBuilder: (context, index) {
          if (index == 0) {
            // Кнопка Всі
            final isSelected = viewModel.selectedCategory == null;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Всі'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    viewModel.clearCategoryFilter();
                  }
                },
                selectedColor: appThemeColors.lightGreenColor.withAlpha(127),
                backgroundColor: appThemeColors.primaryWhite.withAlpha(200),
                labelStyle: TextStyleHelper.instance.title14Regular.copyWith(
                  color: isSelected
                      ? appThemeColors.primaryBlack
                      : appThemeColors.textMediumGrey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }
          final category = viewModel.categories[index - 1];
          final isSelected = viewModel.selectedCategory == category;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  viewModel.filterByCategory(category);
                } else {
                  viewModel.clearCategoryFilter();
                }
              },
              selectedColor: appThemeColors.lightGreenColor.withAlpha(127),
              backgroundColor: appThemeColors.primaryWhite.withAlpha(200),
              labelStyle: TextStyleHelper.instance.title14Regular.copyWith(
                color: isSelected
                    ? appThemeColors.primaryBlack
                    : appThemeColors.textMediumGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(FAQViewModel viewModel) {
    if (viewModel.isLoading) {
      return _buildLoadingState();
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorState(viewModel);
    }

    if (!viewModel.hasData) {
      return _buildEmptyState();
    }

    if (viewModel.filteredFAQItems.isEmpty) {
      return _buildNoResultsState(viewModel);
    }

    return _buildFAQList(viewModel);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: appThemeColors.primaryWhite.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: appThemeColors.lightGreenColor),
            const SizedBox(height: 16),
            Text(
              'Завантаження FAQ...',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(FAQViewModel viewModel) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: appThemeColors.primaryWhite.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appThemeColors.errorRed.withAlpha(127)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: appThemeColors.errorRed),
            const SizedBox(height: 16),
            Text(
              'Помилка завантаження',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.lightGreenColor,
              ),
              child: Text(
                'Спробувати знову',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: appThemeColors.primaryWhite.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appThemeColors.primaryWhite.withAlpha(125)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: appThemeColors.textMediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'FAQ поки що порожній',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Завантажуємо питання та відповіді...',
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(FAQViewModel viewModel) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: appThemeColors.primaryWhite.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appThemeColors.primaryWhite.withAlpha(125)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: appThemeColors.textMediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Нічого не знайдено',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.isSearching
                  ? 'Спробуйте змінити пошуковий запит "${viewModel.searchQuery}"'
                  : 'У цій категорії питань немає',
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
            if (viewModel.isSearching ||
                viewModel.selectedCategory != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: viewModel.clearAllFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appThemeColors.blueAccent,
                ),
                child: Text(
                  'Очистити фільтри',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList(FAQViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: appThemeColors.lightGreenColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (viewModel.isSearching ||
                viewModel.selectedCategory != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appThemeColors.lightGreenColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appThemeColors.lightGreenColor.withAlpha(127),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: appThemeColors.lightGreenColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Знайдено ${viewModel.totalResultsCount} результатів',
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.lightGreenColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ..._buildCategorySections(viewModel),
            const SizedBox(height: 32,)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategorySections(FAQViewModel viewModel) {
    return viewModel.categorizedItems.entries.map((entry) {
      final category = entry.key;
      final items = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                category,
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: appThemeColors.primaryWhite.withAlpha(230),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: appThemeColors.primaryWhite.withAlpha(125),
                ),
              ),
              child: ExpansionPanelList.radio(
                elevation: 0,
                expandedHeaderPadding: EdgeInsets.zero,
                materialGapSize: 0,
                children: items.map((item) {
                  return ExpansionPanelRadio(
                    value: item.id,
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        title: Text(
                          item.question,
                          style: TextStyleHelper.instance.title16Bold.copyWith(
                            color: appThemeColors.primaryBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                      );
                    },
                    body: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.answer,
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(
                                  color: appThemeColors.textMediumGrey,
                                  height: 1.5,
                                ),
                          ),
                          if (item.tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: item.tags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            appThemeColors.backgroundLightGrey,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyleHelper
                                            .instance
                                            .title13Regular
                                            .copyWith(
                                              color:
                                                  appThemeColors.textMediumGrey,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
