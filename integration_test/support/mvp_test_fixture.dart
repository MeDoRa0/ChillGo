import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Creates deterministic emulator identities and document payloads for MVP tests.
class MvpTestFixture {
  MvpTestFixture(this._auth, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> signInAs(MvpTestIdentity identity) async {
    await _auth.signInWithEmailAndPassword(
      email: identity.email,
      password: identity.password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> seedProfile(MvpTestIdentity identity) {
    return _firestore.collection('users').doc(identity.uid).set({
      'username': identity.username,
      'displayName': identity.displayName,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 7, 30)),
    });
  }

  Map<String, Object> outing({
    required String crewId,
    required String creatorId,
    String status = 'planning',
  }) => {
    'crewId': crewId,
    'title': 'Release test outing',
    'description': 'Deterministic MVP validation data.',
    'scheduledAt': Timestamp.fromDate(DateTime.utc(2026, 8, 1, 12)),
    'locationText': 'Test location',
    'status': status,
    'createdByUserId': creatorId,
    'createdAt': Timestamp.fromDate(DateTime.utc(2026, 7, 30)),
    'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 7, 30)),
    'agreementRoundSequence': 0,
  };
}

class MvpTestIdentity {
  const MvpTestIdentity({
    required this.uid,
    required this.username,
    required this.email,
    required this.password,
  });

  final String uid;
  final String username;
  final String email;
  final String password;

  String get displayName => username[0].toUpperCase() + username.substring(1);

  static const alice = MvpTestIdentity(
    uid: 'android-alice',
    username: 'alice',
    email: 'alice@android.test',
    password: 'Android-T101-pass',
  );
  static const bob = MvpTestIdentity(
    uid: 'android-bob',
    username: 'bob',
    email: 'bob@android.test',
    password: 'Android-T101-pass',
  );
  static const outsider = MvpTestIdentity(
    uid: 'android-outsider',
    username: 'outsider',
    email: 'outsider@android.test',
    password: 'Android-T101-pass',
  );
}
