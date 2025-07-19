import 'package:file_picker/file_picker.dart';

class AuthValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Електронна пошта не може бути пустою';
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Введіть коректну електронну пошту';
    }
    return null;
  }

  static String? validatePasswordSimple(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Пароль не може бути пустим';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Пароль не може бути пустим';
    } else if (password.length < 8) {
      return 'Пароль повинен містити мінімум 8 символів';
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Пароль повинен містити хоча б одну велику літеру';
    } else if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Пароль повинен містити хоча б одну малу літеру';
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Пароль повинен містити хоча б одну цифру';
    } else if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Пароль повинен містити хоча б один спеціальний символ';
    }
    return null;
  }

  static String? validateOrganizationName(String? name) {
    if (name == null || name.trim().trim().isEmpty) {
      return 'Назва організації не може бути пустою';
    }
    return null;
  }

  static String? validateWebsite(String? website) {
    if (website != null &&
        website.trim().isNotEmpty &&
        !website.startsWith('http://') &&
        !website.startsWith('https://')) {
      return 'Вебсайт має починатися з http:// або https://';
    }
    return null;
  }

  static String? validateSelectedCity(String? city) {
    if (city == null || city.trim().isEmpty) {
      return 'Будь ласка, оберіть місто';
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? confirmPassword,
    String? originalPassword,
  ) {
    if (confirmPassword == null || confirmPassword.trim().isEmpty) {
      return 'Будь ласка, підтвердіть пароль';
    }
    if (confirmPassword != originalPassword) {
      return 'Паролі не співпадають';
    }
    return null;
  }

  static String? validateDocumentSelected(List<PlatformFile>? documents) {
    if (documents == null || documents.isEmpty) {
      return 'Будь ласка, завантажте необхідні документи';
    }
    return null;
  }

  static String? validateAgreementAccepted(bool? isAccepted) {
    if (isAccepted == null || !isAccepted) {
      return 'Ви повинні прйняти умови угоди';
    }
    return null;
  }

  static String? validateFullName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Ім\'я та прізвище не можуть бути пустими';
    }
    // Перевірка на наявність принаймні двох слів
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return 'Будь ласка, введіть Ім\'я Прізвище';
    }
    if (RegExp(r'[0-9]').hasMatch(name)) {
      return 'Ім\'я не повинно містити цифр';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    // "+380 97 123 45 67" стане "380971234567"
    final cleanedValue = value.replaceAll(RegExp(r'\D'), '');

    if (cleanedValue.startsWith('380') && cleanedValue.length == 12) {
      return null;
    }

    return 'Будь ласка, введіть коректний український номер телефону (формат: +380 ХХ ХХХ ХХ ХХ)';
  }
}
