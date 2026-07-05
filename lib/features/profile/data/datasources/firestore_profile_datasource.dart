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

    // Required fields – treat incomplete documents as missing profiles
    // rather than crashing on null casts.
    final username = data['username'] as String?;
    final displayName = data['displayName'] as String?;
    final createdAtRaw = data['createdAt'] as String?;
    if (username == null || displayName == null || createdAtRaw == null) {
      return null;
    }

    return UserProfile(
      id: uid,
      username: username,
      displayName: displayName,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: DateTime.parse(createdAtRaw),
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    final lowercaseUsername = username.trim().toLowerCase();
    if (lowercaseUsername.isEmpty ||
        lowercaseUsername.contains(RegExp(r'\s'))) {
      return false;
    }
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
    final lowercaseUsername = username.trim().toLowerCase();
    if (lowercaseUsername.isEmpty ||
        lowercaseUsername.contains(RegExp(r'\s'))) {
      throw ArgumentError('Username cannot contain spaces or be empty');
    }
    final usernameDocRef = firestore
        .collection('usernames')
        .doc(lowercaseUsername);
    final userDocRef = firestore.collection('users').doc(uid);

    await firestore.runTransaction((transaction) async {
      final usernameSnapshot = await transaction.get(usernameDocRef);
      if (usernameSnapshot.exists) {
        throw Exception('Username is already taken');
      }

      // Guard against overwriting an existing profile for the same uid.
      // Without this read, a second createProfile call with a different
      // username would silently overwrite the user document and leave the
      // original username reservation in /usernames orphaned.
      final userSnapshot = await transaction.get(userDocRef);
      if (userSnapshot.exists) {
        throw Exception('Profile already exists for this user');
      }

      transaction.set(usernameDocRef, {'uid': uid});
      transaction.set(userDocRef, {
        'username': lowercaseUsername,
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
