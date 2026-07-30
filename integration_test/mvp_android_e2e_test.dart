import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chillgo/firebase_options.dart';

import 'support/mvp_test_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android MVP test identity can authenticate against emulators', (
    tester,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);

    final fixture = MvpTestFixture(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    );
    await fixture.signInAs(MvpTestIdentity.bob);

    expect(FirebaseAuth.instance.currentUser?.uid, MvpTestIdentity.bob.uid);
    await fixture.signOut();
  });
}
