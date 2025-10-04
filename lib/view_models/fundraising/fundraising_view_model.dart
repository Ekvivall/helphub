import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

import '../../data/services/activity_service.dart';
import '../../data/services/category_service.dart';
import '../../data/services/fundraising_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/base_profile_model.dart';
import '../../data/models/category_chip_model.dart';
import '../../data/models/fundraising_model.dart';
import '../../data/models/organization_model.dart';

class FundraisingViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FundraisingService _fundraisingService = FundraisingService();
  final CategoryService _categoryService = CategoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityService _activityService = ActivityService();
  final UserService _userService = UserService();

  StreamSubscription<List<FundraisingModel>>? _fundraisingsSubscription;
  List<FundraisingModel> _allFundraisings = [];
  List<FundraisingModel> _filteredFundraisings = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Фільтри
  List<CategoryChipModel> _availableCategories = [];
  List<CategoryChipModel> _selectedCategories = [];
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _searchQuery = '';
  bool _isUrgentOnly = false;
  double? _minTargetAmount;
  double? _maxTargetAmount;
  String? _selectedBank;

  File? _pickedImageFile;
  List<File> _pickedDocuments = [];
  bool _isUploadingFiles = false;

  String? _currentAuthUserId;
  BaseProfileModel? _user;

  // Getters
  List<FundraisingModel> get filteredFundraisings => _filteredFundraisings;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<CategoryChipModel> get availableCategories => _availableCategories;

  List<CategoryChipModel> get selectedCategories => _selectedCategories;

  DateTime? get selectedStartDate => _selectedStartDate;

  DateTime? get selectedEndDate => _selectedEndDate;

  bool get isUrgentOnly => _isUrgentOnly;

  double? get minTargetAmount => _minTargetAmount;

  double? get maxTargetAmount => _maxTargetAmount;

  File? get pickedImageFile => _pickedImageFile;

  List<File> get pickedDocuments => _pickedDocuments;

  bool get isUploadingFiles => _isUploadingFiles;

  String? get selectedBank => _selectedBank;

  String? get currentAuthUserId => _currentAuthUserId;

  BaseProfileModel? get user => _user;

  FundraisingModel? _currentFundraising;

  FundraisingModel? get currentFundraising => _currentFundraising;

  FundraisingViewModel() {
    _auth.authStateChanges().listen((user) async {
      _currentAuthUserId = user?.uid;
      _user = await _userService.fetchUserProfile(currentAuthUserId);
      _listenToFundraisings();
    });
    _loadAvailableCategories();
  }


  Future<void> _loadAvailableCategories() async {
    try {
      _availableCategories = await _categoryService.fetchCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading available categories: $e');
    }
  }

  void _listenToFundraisings() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _fundraisingsSubscription?.cancel();
    _fundraisingsSubscription = _fundraisingService
        .getFundraisingsStream()
        .listen(
          (fundraisings) {
            _allFundraisings = fundraisings
              ..sort((a, b) {
                // Пріоритет для термінових зборів
                final isAUrgent = a.isUrgent ?? false;
                final isBUrgent = b.isUrgent ?? false;

                if (isAUrgent && !isBUrgent) {
                  return -1;
                }
                if (!isAUrgent && isBUrgent) {
                  return 1;
                }

                // сортуємо за часом (новіші перші)
                final aTimestamp = a.timestamp ?? DateTime(1970);
                final bTimestamp = b.timestamp ?? DateTime(1970);

                return bTimestamp.compareTo(aTimestamp);
              });
            _isLoading = false;
            _applyFilters();
          },
          onError: (error) {
            _errorMessage = 'Помилка завантаження зборів: $error';
            _isLoading = false;
            _allFundraisings = [];
            _filteredFundraisings = [];
            notifyListeners();
          },
        );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setFilters(
    List<CategoryChipModel> categories,
    DateTime? startDate,
    DateTime? endDate,
    bool isUrgentOnly,
    double? minAmount,
    double? maxAmount,
    String? selectedBank,
  ) {
    _selectedCategories = categories;
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    _isUrgentOnly = isUrgentOnly;
    _minTargetAmount = minAmount;
    _maxTargetAmount = maxAmount;
    _selectedBank = selectedBank;
    _applyFilters();
  }

  void clearFilters() {
    _selectedCategories = [];
    _selectedStartDate = null;
    _selectedEndDate = null;
    _searchQuery = '';
    _isUrgentOnly = false;
    _minTargetAmount = null;
    _maxTargetAmount = null;
    _selectedBank = null;
    _applyFilters();
  }

  void _applyFilters() {
    List<FundraisingModel> tempFundraisings = List.from(_allFundraisings);

    // Фільтрація за пошуковим запитом
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      tempFundraisings = tempFundraisings.where((fundraising) {
        return (fundraising.title?.toLowerCase().contains(queryLower) ??
                false) ||
            (fundraising.description?.toLowerCase().contains(queryLower) ??
                false) ||
            (fundraising.organizationName?.toLowerCase().contains(queryLower) ??
                false);
      }).toList();
    }

    // Фільтрація за категоріями
    if (_selectedCategories.isNotEmpty) {
      tempFundraisings = tempFundraisings.where((fundraising) {
        return fundraising.categories?.any(
              (fundraisingCategory) => _selectedCategories.any(
                (selectedCategory) =>
                    selectedCategory.title == fundraisingCategory.title,
              ),
            ) ??
            false;
      }).toList();
    }

    // Фільтрація за датою завершення
    if (_selectedStartDate != null || _selectedEndDate != null) {
      tempFundraisings = tempFundraisings.where((fundraising) {
        final fundraisingEndDate = fundraising.endDate;
        if (fundraisingEndDate == null) return false;

        final startDate = _selectedStartDate ?? DateTime(1970);
        final endDate = _selectedEndDate ?? DateTime(2100);

        // Перевіряємо, чи дата завершення збору потрапляє у вибраний діапазон
        return (fundraisingEndDate.isAtSameMomentAs(startDate) ||
                fundraisingEndDate.isAfter(startDate)) &&
            (fundraisingEndDate.isBefore(endDate.add(const Duration(days: 1))));
      }).toList();
    }

    // Фільтрація за терміновістю
    if (_isUrgentOnly) {
      tempFundraisings = tempFundraisings.where((fundraising) {
        return fundraising.isUrgent == true;
      }).toList();
    }

    // Фільтрація за сумою
    if (_minTargetAmount != null || _maxTargetAmount != null) {
      tempFundraisings = tempFundraisings.where((fundraising) {
        final targetAmount = fundraising.targetAmount;
        if (targetAmount == null) return false;
        bool matchesMin =
            _minTargetAmount == null || targetAmount >= _minTargetAmount!;
        bool matchesMax =
            _maxTargetAmount == null || targetAmount <= _maxTargetAmount!;
        return matchesMin && matchesMax;
      }).toList();
    }

    if (_selectedBank != null) {
      tempFundraisings = tempFundraisings.where((f) {
        if (_selectedBank == 'privat') {
          return f.privatBankCard?.isNotEmpty ?? false;
        }
        if (_selectedBank == 'mono') return f.monoBankCard?.isNotEmpty ?? false;
        return false;
      }).toList();
    }

    _filteredFundraisings = tempFundraisings;
    notifyListeners();
  }

  void setPickedImageFile(File? file) {
    _pickedImageFile = file;
    notifyListeners();
  }

  void setPickedDocuments(List<File> file) {
    _pickedDocuments = file;
    notifyListeners();
  }

  void clearPickedFiles() {
    _pickedImageFile = null;
    _pickedDocuments.clear();
    notifyListeners();
  }

  Future<String?> uploadFundraisingImage() async {
    if (_pickedImageFile == null) return null;
    _isUploadingFiles = true;
    notifyListeners();
    try {
      final String fileName =
          'fundraisings/images/${DateTime.now().millisecondsSinceEpoch}_${p.basename(_pickedImageFile!.path)}';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(_pickedImageFile!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _errorMessage = 'Помилка завантаження зображення: $e';
      return null;
    } finally {
      _isUploadingFiles = false;
      notifyListeners();
    }
  }

  Future<List<String>> uploadFundraisingDocuments() async {
    if (_pickedDocuments.isEmpty) return [];
    _isUploadingFiles = true;
    notifyListeners();
    try {
      List<String> documentUrls = [];
      for (int i = 0; i < _pickedDocuments.length; i++) {
        final file = _pickedDocuments[i];
        final String fileName =
            'fundraisings/documents/${DateTime.now().millisecondsSinceEpoch}_$i${p.extension(file.path)}';
        final Reference storageRef = FirebaseStorage.instance.ref().child(
          fileName,
        );
        final UploadTask uploadTask = storageRef.putFile(File(file.path));
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        documentUrls.add(downloadUrl);
      }
      return documentUrls;
    } catch (e) {
      _errorMessage = 'Помилка завантаження документів: $e';
      return [];
    } finally {
      _isUploadingFiles = false;
      notifyListeners();
    }
  }

  Future<String?> createFundraising({
    required String title,
    required String description,
    required double targetAmount,
    required List<CategoryChipModel> categories,
    required DateTime startDate,
    required DateTime endDate,
    String? privatBankCard,
    String? monoBankCard,
    required bool isUrgent,
    List<String>? relatedApplicationIds,
    required bool hasRaffle,
    double? ticketPrice,
    List<String>? prizes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    String? imageUrl;
    List<String> documentUrls = [];
    if (_pickedImageFile != null) {
      imageUrl = await uploadFundraisingImage();
      if (imageUrl == null) {
        _isLoading = false;
        notifyListeners();
        return 'Не вдалося завантажити зображення збору.';
      }
    }

    if (_pickedDocuments.isNotEmpty) {
      documentUrls = await uploadFundraisingDocuments();
      if (documentUrls.length != _pickedDocuments.length) {
        _isLoading = false;
        notifyListeners();
        return 'Не вдалося завантажити всі документи.';
      }
    }
    if ((privatBankCard == null || privatBankCard.isEmpty) &&
        (monoBankCard == null || monoBankCard.isEmpty)) {
      return 'Будь ласка, вкажіть картку хоча б одного банку.';
    }
    try {
      if (_user == null || _user is! OrganizationModel) {
        return 'Тільки фонди можуть створювати збори.';
      }

      final newFundraisingRef = FirebaseFirestore.instance
          .collection('fundraisings')
          .doc();

      final newFundraising = FundraisingModel(
        id: newFundraisingRef.id,
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        categories: categories,
        organizationId: _currentAuthUserId!,
        organizationName:
            (_user as OrganizationModel).organizationName ?? 'Фонд',
        startDate: startDate,
        endDate: endDate,
        timestamp: DateTime.now(),
        documentUrls: documentUrls,
        photoUrl: imageUrl,
        donorIds: [],
        privatBankCard: privatBankCard,
        monoBankCard: monoBankCard,
        isUrgent: isUrgent,
        relatedApplicationIds: relatedApplicationIds ?? [],
        hasRaffle: hasRaffle,
        ticketPrice: ticketPrice,
        prizes: prizes,
      );

      await newFundraisingRef.set(newFundraising.toMap());

      final userRef = _firestore.collection('users').doc(_currentAuthUserId!);
      await userRef.update({'fundraisingsCount': FieldValue.increment(1)});

      final activity = ActivityModel(
        type: ActivityType.fundraiserCreation,
        entityId: newFundraising.id!,
        title: newFundraising.title!,
        description: newFundraising.description,
        timestamp: DateTime.now(),
      );
      await _activityService.logActivity(currentAuthUserId!, activity);

      clearPickedFiles();
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Помилка при створенні збору: $e';
      _isLoading = false;
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<String?> completeFundraising(String fundraisingId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _fundraisingService.completeFundraising(fundraisingId);

      _isLoading = false;
      notifyListeners();
      return null; // Успіх
    } catch (e) {
      _errorMessage = 'Помилка при завершенні збору: $e';
      _isLoading = false;
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<bool> isFundraisingSaved(String fundraisingId) async {
    if (_currentAuthUserId == null) return false;
    try {
      return await _fundraisingService.isFundraisingSaved(
        _currentAuthUserId!,
        fundraisingId,
      );
    } catch (e) {
      return false;
    }
  }

  Future<String?> toggleSaveFundraising(
    String fundraisingId,
    bool isSaved,
  ) async {
    if (_currentAuthUserId == null) return 'Користувач не авторизований';

    try {
      if (isSaved) {
        await _fundraisingService.unsaveFundraiser(
          _currentAuthUserId!,
          fundraisingId,
        );
      } else {
        await _fundraisingService.saveFundraiser(
          _currentAuthUserId!,
          fundraisingId,
        );
      }
      return null; // Успіх
    } catch (e) {
      return 'Помилка при збереженні: $e';
    }
  }

  void listenToOrganizationFundraisings(String organizationId) {
    _fundraisingsSubscription?.cancel();
    _fundraisingsSubscription = _fundraisingService
        .getOrganizationFundraisingsStream(organizationId)
        .listen(
          (fundraisings) {
            _allFundraisings = fundraisings;
            _isLoading = false;
            _applyFilters();
          },
          onError: (error) {
            _errorMessage = 'Помилка завантаження зборів: $error';
            _isLoading = false;
            _allFundraisings = [];
            _filteredFundraisings = [];
            notifyListeners();
          },
        );
  }

  // fundraising_view_model.dart

  Future<String?> updateFundraising({
    required String fundraisingId,
    required String title,
    required String description,
    required double targetAmount,
    required List<CategoryChipModel> categories,
    required DateTime startDate,
    required DateTime endDate,
    String? privatBankCard,
    String? monoBankCard,
    required bool isUrgent,
    required bool hasRaffle,
    double? ticketPrice,
    List<String>? prizes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Перевірка наявності хоча б однієї картки
      if ((privatBankCard == null || privatBankCard.isEmpty) &&
          (monoBankCard == null || monoBankCard.isEmpty)) {
        return 'Будь ласка, вкажіть картку хоча б одного банку.';
      }

      // Логіка завантаження нових файлів, якщо вони були змінені
      String? imageUrl = _currentFundraising?.photoUrl;
      if (_pickedImageFile != null) {
        imageUrl = await uploadFundraisingImage();
        if (imageUrl == null) {
          _isLoading = false;
          notifyListeners();
          return 'Не вдалося завантажити нове зображення.';
        }
      }

      List<String> documentUrls = _currentFundraising?.documentUrls ?? [];
      if (_pickedDocuments.isNotEmpty) {
        final newUrls = await uploadFundraisingDocuments();
        if (newUrls.isEmpty && _pickedDocuments.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          return 'Не вдалося завантажити нові документи.';
        }
        documentUrls.addAll(newUrls);
      }

      final updatedFundraising = FundraisingModel(
        id: fundraisingId,
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: _currentFundraising!.currentAmount,
        donorIds: _currentFundraising!.donorIds,
        organizationId: _currentFundraising!.organizationId,
        organizationName: _currentFundraising!.organizationName,
        timestamp: _currentFundraising!.timestamp,
        // Оновлювані поля
        categories: categories,
        startDate: startDate,
        endDate: endDate,
        privatBankCard: privatBankCard,
        monoBankCard: monoBankCard,
        isUrgent: isUrgent,
        relatedApplicationIds: _currentFundraising!.relatedApplicationIds,
        photoUrl: imageUrl,
        documentUrls: documentUrls,
        hasRaffle: hasRaffle,
        ticketPrice: ticketPrice,
        prizes: prizes,
      );

      await _fundraisingService.updateFundraising(updatedFundraising);

      clearPickedFiles();
      _isLoading = false;
      notifyListeners();
      return null; // Успіх
    } catch (e) {
      _errorMessage = 'Помилка при оновленні збору: $e';
      _isLoading = false;
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<void> loadFundraisingDetails(String fundraisingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentFundraising = await _fundraisingService.getFundraisingById(
        fundraisingId,
      );
      if (_currentFundraising == null) {
        _errorMessage = 'Збір не знайдено.';
      }
    } catch (e) {
      _errorMessage = 'Помилка завантаження збору: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Stream<FundraisingModel?> getFundraisingStreamById(String fundraisingId) {
    return _fundraisingService.getFundraisingStream(fundraisingId);
  }

  @override
  void dispose() {
    _fundraisingsSubscription?.cancel();
    _currentFundraising = null;
    super.dispose();
  }
}
