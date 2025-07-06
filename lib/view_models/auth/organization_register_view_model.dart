import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/user_model.dart';
import 'package:helphub/routes/app_router.dart';

import '../../core/utils/constants.dart';

class OrganizationRegisterViewModel extends ChangeNotifier {
  final TextEditingController organizationNameController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? _selectedCity;

  String? get selectedCity => _selectedCity;

  List<PlatformFile> _selectedDocuments = [];

  List<PlatformFile> get selectedDocuments => _selectedDocuments;
  bool _isAgreementAccepted = false;

  bool get isAgreementAccepted => _isAgreementAccepted;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _showValidationErrors = false;

  bool get showValidationErrors => _showValidationErrors;

  @override
  void dispose() {
    organizationNameController.dispose();
    emailController.dispose();
    websiteController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void updateCity(String newValue) {
    _selectedCity = newValue;
    notifyListeners();
  }

  void updateSelectedDocuments(List<PlatformFile> files) {
    _selectedDocuments = files;
    notifyListeners();
  }

  Future<void> pickDocument() async {
    _isLoading = true;
    notifyListeners();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'xlsx'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        _selectedDocuments = result.files;
      } else {
        _selectedDocuments = [];
      }
    } catch (e) {
      _selectedDocuments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateAgreement(bool value) {
    _isAgreementAccepted = value;
    notifyListeners();
  }

  Future<void> handleRegistrationStep1(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) {
      _showValidationErrors = true;
      notifyListeners();
      return;
    }
    _showValidationErrors = false;
    notifyListeners();
    Navigator.of(context).pushNamed(AppRoutes.registerOrganizationStep2Screen);
  }

  Future<void> handleRegistrationStep2(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) {
      _showValidationErrors = true;
      notifyListeners();
      return;
    }
    _showValidationErrors = false;
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Створення користувача в FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      User? user = userCredential.user;
      if (user != null) {
        // 2. Завантаження документів у Firebase Storage
        List<String> documentUrls = [];
        if (_selectedDocuments.isNotEmpty) {
          Constants.showSuccessMessage(context, 'Завантаження документів...');
          for (PlatformFile file in _selectedDocuments) {
            try {
              //Створення унікального шляху для файлу в Storage
              final String filePath =
                  'users/${user.uid}/documents/${DateTime.now().microsecondsSinceEpoch}_${file.name}';
              final Reference storageRef = FirebaseStorage.instance.ref().child(
                filePath,
              );
              UploadTask uploadTask;
              if (file.bytes != null) {
                uploadTask = storageRef.putData(file.bytes!);
              } else if (file.path != null) {
                uploadTask = storageRef.putFile(File(file.path!));
              } else {
                throw Exception('Немає даних файлу для завантаження.');
              }
              final TaskSnapshot snapshot = await uploadTask.whenComplete(
                () {},
              );
              final String downloadUrl = await snapshot.ref.getDownloadURL();
              documentUrls.add(downloadUrl);
            } catch (storageError) {
              Constants.showErrorMessage(
                context,
                'Помилка завантаження файлу ${file.name}: ${storageError.toString()}',
              );
            }
          }
        }
        // 3. Збереження інформації про організацію до Firestore
        UserModel newOrganization = UserModel(
          uid: user.uid,
          email: emailController.text.trim(),
          role: UserRole.organization,
          organizationName: organizationNameController.text.trim(),
          website: websiteController.text.trim(),
          city: _selectedCity,
          documents: documentUrls,
          isVerification: false,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newOrganization.toMap(), SetOptions(merge: true));
        Constants.showSuccessMessage(
          context,
          'Благодійний фонд успішно зареєстрований!',
        );
        Navigator.of(context).pushNamed(AppRoutes.eventMapScreen);
      } else {
        Constants.showErrorMessage(
          context,
          'Помилка реєстрації: Користувача не створено',
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Помилка реєстрації: ${e.message}';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Ця електронна пошта вже використовується';
      }
      Constants.showErrorMessage(context, errorMessage);
    } catch (e) {
      Constants.showErrorMessage(
        context,
        'Помилка реєстрації: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
