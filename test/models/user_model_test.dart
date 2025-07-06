import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/user_model.dart';

void main() {
  group('UserModel', () {
    // Тестові дані для волонтера
    final volunteerUserMap = {
      'uid': 'volunteer123',
      'email': 'volunteer@example.com',
      'role': 'volunteer',
      'fullName': 'Іван Волонтер',
      'city': 'Київ',
      'createdAt': Timestamp.now(),
      'lastSignInAt': Timestamp.now(),
    };

    final volunteerUserModel = UserModel(
      uid: 'volunteer123',
      email: 'volunteer@example.com',
      role: UserRole.volunteer,
      fullName: 'Іван Волонтер',
      city: 'Київ',
      createdAt: (volunteerUserMap['createdAt'] as Timestamp).toDate(),
      lastSignInAt: (volunteerUserMap['lastSignInAt'] as Timestamp).toDate(),
    );

    // Тестові дані для організації
    final organizationUserMap = {
      'uid': 'org456',
      'email': 'organization@example.com',
      'role': 'organization',
      'organizationName': 'Благодійний Фонд "Надія"',
      'website': 'https://www.hope.org',
      'city': 'Львів',
      'documents': ['http://doc1.url', 'http://doc2.url'],
      'isVerification': true,
      'createdAt': Timestamp.now(),
      'lastSignInAt': Timestamp.now(),
    };

    final organizationUserModel = UserModel(
      uid: 'org456',
      email: 'organization@example.com',
      role: UserRole.organization,
      organizationName: 'Благодійний Фонд "Надія"',
      website: 'https://www.hope.org',
      city: 'Львів',
      documents: ['http://doc1.url', 'http://doc2.url'],
      isVerification: true,
      createdAt: (organizationUserMap['createdAt'] as Timestamp).toDate(),
      lastSignInAt: (organizationUserMap['lastSignInAt'] as Timestamp).toDate(),
    );

    // Тестові дані для користувача Google Sign-In
    final googleUserMap = {
      'uid': 'google789',
      'email': 'google@example.com',
      'role': 'volunteer',
      'displayName': 'Google User',
      'photoUrl': 'https://photo.url/google.jpg',
      'createdAt': Timestamp.now(),
      'lastSignInAt': Timestamp.now(),
    };

    final googleUserModel = UserModel(
      uid: 'google789',
      email: 'google@example.com',
      role: UserRole.volunteer,
      displayName: 'Google User',
      photoUrl: 'https://photo.url/google.jpg',
      createdAt: (googleUserMap['createdAt'] as Timestamp).toDate(),
      lastSignInAt: (googleUserMap['lastSignInAt'] as Timestamp).toDate(),
    );

    test('UserModel.fromMap() should correctly parse volunteer data', () {
      final user = UserModel.fromMap(volunteerUserMap);

      expect(user.uid, volunteerUserModel.uid);
      expect(user.email, volunteerUserModel.email);
      expect(user.role, volunteerUserModel.role);
      expect(user.fullName, volunteerUserModel.fullName);
      expect(user.city, volunteerUserModel.city);
      expect(
        user.createdAt!.millisecondsSinceEpoch,
        closeTo(volunteerUserModel.createdAt!.millisecondsSinceEpoch, 1000),
      );
      expect(
        user.lastSignInAt!.millisecondsSinceEpoch,
        closeTo(volunteerUserModel.lastSignInAt!.millisecondsSinceEpoch, 1000),
      );

      expect(user.organizationName, isNull);
      expect(user.website, isNull);
      expect(user.documents, isNull);
      expect(user.isVerification, isNull);
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    test('UserModel.toMap() should correctly convert volunteer data', () {
      final map = volunteerUserModel.toMap();

      expect(map['uid'], volunteerUserMap['uid']);
      expect(map['email'], volunteerUserMap['email']);
      expect(map['role'], 'volunteer');
      expect(map['fullName'], volunteerUserMap['fullName']);
      expect(map['city'], volunteerUserMap['city']);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['lastSignInAt'], isA<Timestamp>());

      expect(map['organizationName'], isNull);
      expect(map['website'], isNull);
      expect(map['documents'], isNull);
      expect(map['isVerification'], isNull);
      expect(map['displayName'], isNull);
      expect(map['photoUrl'], isNull);
    });

    test('UserModel.fromMap() should correctly parse organization data', () {
      final user = UserModel.fromMap(organizationUserMap);

      expect(user.uid, organizationUserModel.uid);
      expect(user.email, organizationUserModel.email);
      expect(user.role, organizationUserModel.role);
      expect(user.organizationName, organizationUserModel.organizationName);
      expect(user.website, organizationUserModel.website);
      expect(user.city, organizationUserModel.city);
      expect(user.documents, organizationUserModel.documents);
      expect(user.isVerification, organizationUserModel.isVerification);
      expect(
        user.createdAt!.millisecondsSinceEpoch,
        closeTo(organizationUserModel.createdAt!.millisecondsSinceEpoch, 1000),
      );
      expect(
        user.lastSignInAt!.millisecondsSinceEpoch,
        closeTo(
          organizationUserModel.lastSignInAt!.millisecondsSinceEpoch,
          1000,
        ),
      );

      expect(user.fullName, isNull);
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    test('UserModel.toMap() should correctly convert organization data', () {
      final map = organizationUserModel.toMap();

      expect(map['uid'], organizationUserMap['uid']);
      expect(map['email'], organizationUserMap['email']);
      expect(map['role'], 'organization');
      expect(map['organizationName'], organizationUserMap['organizationName']);
      expect(map['website'], organizationUserMap['website']);
      expect(map['city'], organizationUserMap['city']);
      expect(map['documents'], organizationUserMap['documents']);
      expect(map['isVerification'], organizationUserMap['isVerification']);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['lastSignInAt'], isA<Timestamp>());

      expect(map['fullName'], isNull);
      expect(map['displayName'], isNull);
      expect(map['photoUrl'], isNull);
    });

    test('UserModel.fromMap() should correctly parse Google user data', () {
      final user = UserModel.fromMap(googleUserMap);

      expect(user.uid, googleUserModel.uid);
      expect(user.email, googleUserModel.email);
      expect(user.role, googleUserModel.role);
      expect(user.displayName, googleUserModel.displayName);
      expect(user.photoUrl, googleUserModel.photoUrl);
      expect(
        user.createdAt!.millisecondsSinceEpoch,
        closeTo(googleUserModel.createdAt!.millisecondsSinceEpoch, 1000),
      );
      expect(
        user.lastSignInAt!.millisecondsSinceEpoch,
        closeTo(googleUserModel.lastSignInAt!.millisecondsSinceEpoch, 1000),
      );

      expect(user.fullName, isNull);
      expect(user.organizationName, isNull);
      expect(user.website, isNull);
      expect(user.documents, isNull);
      expect(user.isVerification, isNull);
      expect(user.city, isNull);
    });

    test('UserModel.toMap() should correctly convert Google user data', () {
      final map = googleUserModel.toMap();

      expect(map['uid'], googleUserMap['uid']);
      expect(map['email'], googleUserMap['email']);
      expect(map['role'], 'volunteer');
      expect(map['displayName'], googleUserMap['displayName']);
      expect(map['photoUrl'], googleUserMap['photoUrl']);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['lastSignInAt'], isA<Timestamp>());

      expect(map['fullName'], isNull);
      expect(map['organizationName'], isNull);
      expect(map['website'], isNull);
      expect(map['documents'], isNull);
      expect(map['isVerification'], isNull);
      expect(map['city'], isNull);
    });

    test('UserModel equality should work correctly', () {
      final user1 = UserModel(
        uid: '1',
        email: 'test@example.com',
        role: UserRole.volunteer,
        fullName: 'Test User',
      );
      final user2 = UserModel(
        uid: '1',
        email: 'test@example.com',
        role: UserRole.volunteer,
        fullName: 'Test User',
      );
      final user3 = UserModel(
        uid: '2',
        email: 'test2@example.com',
        role: UserRole.organization,
        organizationName: 'Test Org',
      );

      expect(user1, user2);
      expect(user1.hashCode, user2.hashCode);
      expect(user1, isNot(user3));
      expect(user1.hashCode, isNot(user3.hashCode));
    });

    test(
      'UserModel.copyWith() should create a new instance with updated values',
      () {
        final originalUser = UserModel(
          uid: '1',
          email: 'test@example.com',
          role: UserRole.volunteer,
          fullName: 'Original Name',
        );
        final updatedUser = originalUser.copyWith(
          fullName: 'Updated Name',
          city: 'Нове Місто',
        );

        expect(updatedUser.uid, originalUser.uid);
        expect(
          updatedUser.email,
          originalUser.email,
        );
        expect(updatedUser.fullName, 'Updated Name'); // Ім'я оновлено
        expect(updatedUser.city, 'Нове Місто'); // Місто оновлено
        expect(updatedUser.role, originalUser.role); // Роль залишається тією ж

        expect(
          originalUser.fullName,
          'Original Name',
        ); // Оригінальний об'єкт не змінився
      },
    );

    test('UserRole enum conversion to and from string', () {
      expect(UserRole.volunteer.toString().split('.').last, 'volunteer');
      expect(UserRole.organization.toString().split('.').last, 'organization');

      // Тест приватної функції _stringToUserRole через fromMap
      final volunteerMap = {'role': 'volunteer', 'email': 'a@b.com'};
      expect(UserModel.fromMap(volunteerMap).role, UserRole.volunteer);

      final organizationMap = {'role': 'organization', 'email': 'a@b.com'};
      expect(UserModel.fromMap(organizationMap).role, UserRole.organization);
    });
  });
}
