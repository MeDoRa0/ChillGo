import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  FirebaseAuthDatasource({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  User? get currentUser => firebaseAuth.currentUser;

  Future<User?> refreshCurrentUserToken() async {
    var user = firebaseAuth.currentUser;
    if (user == null) return null;

    await user.reload();
    user = firebaseAuth.currentUser;
    if (user == null) return null;

    await user.getIdToken(true);
    return user;
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled');
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final credentialResult = await firebaseAuth.signInWithCredential(
      credential,
    );
    try {
      await firebaseAuth.currentUser?.reload();
    } catch (e, stack) {
      debugPrint(
        '[ChillGo] Post-Google-sign-in user reload failed: $e\n$stack',
      );
    }
    try {
      await firebaseAuth.currentUser?.getIdToken(true);
    } catch (e, stack) {
      debugPrint(
        '[ChillGo] Post-Google-sign-in token refresh failed: $e\n$stack',
      );
    }
    return credentialResult;
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final sha256Nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256Nonce,
    );

    final OAuthCredential credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
    final credentialResult = await firebaseAuth.signInWithCredential(
      credential,
    );
    await firebaseAuth.currentUser?.reload();
    await firebaseAuth.currentUser?.getIdToken(true);
    return credentialResult;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
    } catch (_) {
      // Google sign-out is best-effort; proceed to Firebase sign-out regardless.
    } finally {
      await firebaseAuth.signOut();
    }
  }
}
