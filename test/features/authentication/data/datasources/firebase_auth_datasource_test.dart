import 'package:chillgo/features/authentication/data/datasources/firebase_auth_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth firebaseAuth;
  late MockGoogleSignIn googleSignIn;
  late FirebaseAuthDatasource datasource;

  setUp(() {
    firebaseAuth = MockFirebaseAuth();
    googleSignIn = MockGoogleSignIn();
    datasource = FirebaseAuthDatasource(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
    );
  });

  group('FirebaseAuthDatasource.refreshCurrentUserToken', () {
    test('throws when current user reload fails', () async {
      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(
        () => user.reload(),
      ).thenThrow(FirebaseAuthException(code: 'user-token-expired'));

      await expectLater(
        datasource.refreshCurrentUserToken(),
        throwsA(isA<FirebaseAuthException>()),
      );
      verify(() => user.reload()).called(1);
      verifyNever(() => user.getIdToken(any()));
    });

    test('throws when forced token refresh fails', () async {
      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.reload()).thenAnswer((_) async {});
      when(
        () => user.getIdToken(true),
      ).thenThrow(FirebaseAuthException(code: 'invalid-user-token'));

      await expectLater(
        datasource.refreshCurrentUserToken(),
        throwsA(isA<FirebaseAuthException>()),
      );
      verify(() => user.reload()).called(1);
      verify(() => user.getIdToken(true)).called(1);
    });

    test('returns null only when no current user is signed in', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);

      final user = await datasource.refreshCurrentUserToken();

      expect(user, isNull);
    });
  });
}
