import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helphub/data/services/faq_service.dart';
import 'package:helphub/data/models/faq_item_model.dart';

class FAQViewModel extends ChangeNotifier {
  final FAQService _faqService = FAQService();

  List<FAQItemModel> _allFAQItems = [];
  List<FAQItemModel> _filteredFAQItems = [];
  final Map<String, List<FAQItemModel>> _categorizedItems = {};
  List<String> _categories = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  StreamSubscription<List<FAQItemModel>>? _faqSubscription;

  //Getters
  List<FAQItemModel> get allFAQItems => _allFAQItems;

  List<FAQItemModel> get filteredFAQItems => _filteredFAQItems;

  Map<String, List<FAQItemModel>> get categorizedItems => _categorizedItems;

  List<String> get categories => _categories;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  String? get selectedCategory => _selectedCategory;

  bool get hasData => _allFAQItems.isNotEmpty;

  bool get isSearching => _searchQuery.isNotEmpty;

  int get totalResultsCount => _filteredFAQItems.length;

  FAQViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadFAQData();
  }

  Future<void> loadFAQData() async {
    try {
      _setLoading(true);
      _clearError();
      final faqItems = await _faqService.getFAQItems();
      _updateFAQItems(faqItems);
    } catch (e) {
      _setError('ПОмилка завантаження FAQ: $e');
    } finally {
      _setLoading(false);
    }
  }

  void startListeningToFAQ() {
    _faqSubscription?.cancel();
    _faqSubscription = _faqService.getFAQItemsStream().listen(
      (faqItems) {
        _updateFAQItems(faqItems);
        if (_isLoading) {
          _setLoading(false);
        }
      },
      onError: (error) {
        _setError('Помилка завантаження FAQ: $error');
        _setLoading(false);
      },
    );
  }

  void _updateFAQItems(List<FAQItemModel> items) {
    _allFAQItems = items;
    _buildCategories();
    _applyFilters();
    notifyListeners();
  }

  void _buildCategories() {
    final categorySet = <String>{};
    for (final item in _allFAQItems) {
      categorySet.add(item.category);
    }
    _categories = categorySet.toList()..sort();
  }

  void _applyFilters() {
    List<FAQItemModel> filtered = _allFAQItems;

    // Фільтр по категорії
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Фільтр по пошуковому запиту
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.question.toLowerCase().contains(query) ||
            item.answer.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }
    _filteredFAQItems = filtered;
    _categorizeFAQItems();
  }

  void _categorizeFAQItems() {
    _categorizedItems.clear();
    for (final item in _filteredFAQItems) {
      if (!_categorizedItems.containsKey(item.category)) {
        _categorizedItems[item.category] = [];
      }
      _categorizedItems[item.category]!.add(item);
    }

    // Сортування категорій та елементів в ній
    for (final category in _categorizedItems.keys) {
      _categorizedItems[category]!.sort((a, b) => a.order.compareTo(b.order));
    }
  }

  void search(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategory = null;
    _applyFilters();
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _applyFilters();
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadFAQData();
  }

  FAQItemModel? getFAQItemById(String id) {
    try {
      return _allFAQItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<FAQItemModel> getFAQItemsByCategory(String category) {
    return _allFAQItems.where((item) => item.category == category).toList();
  }
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _faqSubscription?.cancel();
    super.dispose();
  }
}
