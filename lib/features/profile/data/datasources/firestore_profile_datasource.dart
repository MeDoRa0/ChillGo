import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../authentication/domain/entities/user_profile.dart';

class FirestoreProfileDatasource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FirestoreProfileDatasource({required this.firestore, required this.storage});

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return UserProfile(
      id: uid,
      username: data['username'] as String,
      displayName: data['displayName'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    final lowercaseUsername = username.toLowerCase().trim();
    final doc = await firestore
        .collection('usernames')
        .doc(lowercaseUsername)
        .get();
    return !doc.exists;
  }

  Future<void> createProfile({
    required String uid,
    required String username,
    required String displayName,
    String? avatarUrl,
  }) async {
    final lowercaseUsername = username.toLowerCase().trim();
    final usernameDocRef = firestore
        .collection('usernames')
        .doc(lowercaseUsername);
    final userDocRef = firestore.collection('users').doc(uid);

    await firestore.runTransaction((transaction) async {
      final usernameSnapshot = await transaction.get(usernameDocRef);
      if (usernameSnapshot.exists) {
        throw Exception('Username is already taken');
      }

      transaction.set(usernameDocRef, {'uid': uid});
      transaction.set(userDocRef, {
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (updates.isNotEmpty) {
      await firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    final contentType = fileExtension.toLowerCase() == 'png'
        ? 'image/png'
        : 'image/jpeg';
    final ref = storage.ref().child('avatars/$uid');
    final uploadTask = await ref.putData(
      Uint8List.fromList(imageBytes),
      SettableMetadata(contentType: contentType),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}
