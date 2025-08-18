
import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/fundraising/fundraising_view_model.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/custom_input_field.dart';
import 'package:helphub/widgets/profile/saved_fundraising_item.dart';
import 'package:provider/provider.dart';
import '../../theme/text_style_helper.dart';

class AllSavedFundraisersScreen extends StatefulWidget {
  const AllSavedFundraisersScreen({super.key});

  @override
  State<AllSavedFundraisersScreen> createState() =>
      _AllSavedFundraisersScreenState();
}

class _AllSavedFundraisersScreenState extends State<AllSavedFundraisersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<FundraisingViewModel>(context, listen: false);
      viewModel.clearFilters();
      _searchController.addListener(() {
        viewModel.setSearchQuery(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () {
            Provider.of<FundraisingViewModel>(context, listen: false).setSearchQuery('');
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Усі збережені збори',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomInputField(
                controller: _searchController,
                hintText: 'Пошук серед збережених...',
                prefixIcon: Icon(
                  Icons.search,
                  color: appThemeColors.textMediumGrey,
                ),
                borderRadius: 24,
              ),
            ),
            Expanded(
              child: Consumer<ProfileViewModel>(
                builder: (context, viewModel, child) {
                  final sourceList = viewModel.savedFundraiser;
                  final filteredList = sourceList.where((f) {
                    final query = _searchController.text.toLowerCase();
                    if (query.isEmpty) return true;
                    return (f.title?.toLowerCase().contains(query) ?? false) ||
                        (f.description?.toLowerCase().contains(query) ?? false);
                  }).toList();

                  if (viewModel.isLoading && sourceList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (sourceList.isEmpty) {
                    return Center(
                      child: Text(
                        'Ви ще не зберегли жодного збору.',
                        style: TextStyleHelper.instance.title16Regular.copyWith(
                          color: appThemeColors.backgroundLightGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (filteredList.isEmpty && _searchController.text.isNotEmpty) {
                    return Center(
                      child: Text(
                        'Зборів за запитом "${_searchController.text}" не знайдено',
                        style: TextStyleHelper.instance.title16Regular.copyWith(
                          color: appThemeColors.backgroundLightGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final fundraising = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SavedFundraisingItem(
                          fundraising: fundraising,
                        ),
                      );
                    },
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