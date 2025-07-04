import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helphub/validators/auth_validator.dart';

void main() {
  group('AuthValidator', () {
    // Тести для validateEmail
    group('validateEmail', () {
      test('повинен повернути null для коректної електронної пошти', () {
        expect(AuthValidator.validateEmail('test@example.com'), null);
      });

      test('повинен повернути повідомлення про помилку для порожньої електронної пошти', () {
        expect(AuthValidator.validateEmail(''), 'Електронна пошта не може бути пустою');
        expect(AuthValidator.validateEmail(null), 'Електронна пошта не може бути пустою');
        expect(AuthValidator.validateEmail('   '), 'Електронна пошта не може бути пустою');
      });

      test('повинен повернути повідомлення про помилку для некоректної електронної пошти', () {
        expect(AuthValidator.validateEmail('invalid-email'), 'Введіть коректну електронну пошту');
        expect(AuthValidator.validateEmail('test@.com'), 'Введіть коректну електронну пошту');
        expect(AuthValidator.validateEmail('test@example'), 'Введіть коректну електронну пошту');
        expect(AuthValidator.validateEmail('test@example.'), 'Введіть коректну електронну пошту');
      });
    });

    // Тести для validatePassword
    group('validatePassword', () {
      test('повинен повернути null для коректного пароля', () {
        expect(AuthValidator.validatePassword('StrongP@ss1'), null);
        expect(AuthValidator.validatePassword('Another!Password2024'), null);
      });

      test('повинен повернути повідомлення про помилку для порожнього пароля', () {
        expect(AuthValidator.validatePassword(''), 'Пароль не може бути пустим');
        expect(AuthValidator.validatePassword(null), 'Пароль не може бути пустим');
        expect(AuthValidator.validatePassword('   '), 'Пароль не може бути пустим');
      });

      test('повинен повернути повідомлення про помилку, якщо пароль менше 8 символів', () {
        expect(AuthValidator.validatePassword('Short1!'), 'Пароль повинен містити мінімум 8 символів');
      });

      test('повинен повернути повідомлення про помилку, якщо немає великих літер', () {
        expect(AuthValidator.validatePassword('nopassword1!'), 'Пароль повинен містити хоча б одну велику літеру');
      });

      test('повинен повернути повідомлення про помилку, якщо немає малих літер', () {
        expect(AuthValidator.validatePassword('NOPASSWORD1!'), 'Пароль повинен містити хоча б одну малу літеру');
      });

      test('повинен повернути повідомлення про помилку, якщо немає цифр', () {
        expect(AuthValidator.validatePassword('NoDigits!'), 'Пароль повинен містити хоча б одну цифру');
      });

      test('повинен повернути повідомлення про помилку, якщо немає спеціальних символів', () {
        expect(AuthValidator.validatePassword('NoSpecial123'), 'Пароль повинен містити хоча б один спеціальний символ');
      });
    });

    // Тести для validateFullName
    group('validateFullName', () {
      test('повинен повернути null для коректного повного імені', () {
        expect(AuthValidator.validateFullName('Іван Петренко'), null);
        expect(AuthValidator.validateFullName('Марія Іваненко-Коваль'), null);
      });

      test('повинен повернути повідомлення про помилку для порожнього імені', () {
        expect(AuthValidator.validateFullName(''), 'Ім\'я та прізвище не можуть бути пустими');
        expect(AuthValidator.validateFullName(null), 'Ім\'я та прізвище не можуть бути пустими');
        expect(AuthValidator.validateFullName('   '), 'Ім\'я та прізвище не можуть бути пустими');
      });

      test('повинен повернути повідомлення про помилку, якщо ім\'я містить лише одне слово', () {
        expect(AuthValidator.validateFullName('Іван'), 'Будь ласка, введіть Ім\'я Прізвище');
      });

      test('повинен повернути повідомлення про помилку, якщо ім\'я містить цифри', () {
        expect(AuthValidator.validateFullName('Іван 123'), 'Ім\'я не повинно містити цифр');
      });
    });

    // Тести для validateOrganizationName
    group('validateOrganizationName', () {
      test('повинен повернути null для коректної назви організації', () {
        expect(AuthValidator.validateOrganizationName('Моя Організація'), null);
      });

      test('повинен повернути повідомлення про помилку для порожньої назви', () {
        expect(AuthValidator.validateOrganizationName(''), 'Назва організації не може бути пустою');
        expect(AuthValidator.validateOrganizationName(null), 'Назва організації не може бути пустою');
      });
    });

    // Тести для validateWebsite
    group('validateWebsite', () {
      test('повинен повернути null для коректного вебсайту', () {
        expect(AuthValidator.validateWebsite('https://example.com'), null);
        expect(AuthValidator.validateWebsite('http://www.test.org'), null);
      });

      test('повинен повернути повідомлення про помилку для некоректного формату вебсайту', () {
        expect(AuthValidator.validateWebsite('example.com'), 'Вебсайт має починатися з http:// або https://');
        expect(AuthValidator.validateWebsite('ftp://example.com'), 'Вебсайт має починатися з http:// або https://');
      });
    });

    // Тести для validateSelectedCity
    group('validateSelectedCity', () {
      test('повинен повернути null для обраного міста', () {
        expect(AuthValidator.validateSelectedCity('Київ'), null);
      });

      test('повинен повернути повідомлення про помилку для необраного міста', () {
        expect(AuthValidator.validateSelectedCity(null), 'Будь ласка, оберіть місто');
        expect(AuthValidator.validateSelectedCity(''), 'Будь ласка, оберіть місто');
      });
    });

    // Тести для validateConfirmPassword
    group('validateConfirmPassword', () {
      test('повинен повернути null, якщо паролі співпадають', () {
        expect(AuthValidator.validateConfirmPassword('Password123!', 'Password123!'), null);
      });

      test('повинен повернути повідомлення про помилку для порожнього підтвердження', () {
        expect(AuthValidator.validateConfirmPassword('', 'Password123!'), 'Будь ласка, підтвердіть пароль');
        expect(AuthValidator.validateConfirmPassword(null, 'Password123!'), 'Будь ласка, підтвердіть пароль');
      });

      test('повинен повернути повідомлення про помилку, якщо паролі не співпадають', () {
        expect(AuthValidator.validateConfirmPassword('WrongPass123!', 'Password123!'), 'Паролі не співпадають');
      });
    });

    // Тести для validateDocumentSelected
    group('validateDocumentSelected', () {
      test('повинен повернути null, якщо документи обрано', () {
        List<PlatformFile> objects = [PlatformFile(name: '', size: 2)];
        expect(AuthValidator.validateDocumentSelected(objects), null);
      });

      test('повинен повернути повідомлення про помилку, якщо документи не обрано', () {
        expect(AuthValidator.validateDocumentSelected(null), 'Будь ласка, завантажте необхідні документи');
        expect(AuthValidator.validateDocumentSelected([]), 'Будь ласка, завантажте необхідні документи');
      });
    });

    // Тести для validateAgreementAccepted
    group('validateAgreementAccepted', () {
      test('повинен повернути null, якщо угода прийнята', () {
        expect(AuthValidator.validateAgreementAccepted(true), null);
      });

      test('повинен повернути повідомлення про помилку, якщо угода не прийнята', () {
        expect(AuthValidator.validateAgreementAccepted(false), 'Ви повинні прйняти умови угоди');
        expect(AuthValidator.validateAgreementAccepted(null), 'Ви повинні прйняти умови угоди');
      });
    });
  });
}