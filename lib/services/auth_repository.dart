import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_session.dart';

class AuthResult {
  const AuthResult.success(this.session) : errorMessage = null;
  const AuthResult.failure(this.errorMessage) : session = null;

  final UserSession? session;
  final String? errorMessage;

  bool get isSuccess => session != null;
}

class AuthRepository {
  AuthRepository();

  static const databaseUrl =
      'https://targetpoint-c57ff-default-rtdb.europe-west1.firebasedatabase.app/';

  bool _firebaseReady = false;
  bool _googleReady = false;

  bool get firebaseReady => _firebaseReady;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
      _firebaseReady = true;
    } catch (error) {
      debugPrint('Firebase is not configured yet: $error');
      _firebaseReady = false;
    }

    try {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
    } catch (error) {
      debugPrint('Google Sign-In is not configured yet: $error');
      _googleReady = false;
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    if (!_firebaseReady) {
      return const AuthResult.failure(
        'Firebase is not configured yet. Add Firebase options/config files first.',
      );
    }

    if (!_googleReady) {
      return const AuthResult.failure(
        'Google Sign-In is not configured yet for this platform.',
      );
    }

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        return const AuthResult.failure(
          'Google sign-in did not return a user.',
        );
      }

      final session = UserSession(
        id: user.uid,
        displayName: user.displayName ?? googleUser.displayName ?? 'Player',
        email: user.email ?? googleUser.email,
        avatarColorValue: 0xFF0F8B6B,
        isGuest: false,
      );
      await _saveUserProfile(session);
      return AuthResult.success(session);
    } catch (error) {
      return AuthResult.failure('Google sign-in failed: $error');
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleReady) {
        await GoogleSignIn.instance.signOut();
      }
      if (_firebaseReady) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (error) {
      debugPrint('Sign out failed: $error');
    }
  }

  Future<void> followUser({
    required String ownerUserId,
    required FollowedUser followedUser,
  }) async {
    if (!_firebaseReady || ownerUserId == 'guest') {
      return;
    }

    await _db.child('users/$ownerUserId/following/${followedUser.id}').set({
      'displayName': followedUser.displayName,
      'handle': followedUser.handle,
      'followedAt': ServerValue.timestamp,
    });
  }

  Future<void> saveGameSession(
    String gameId,
    Map<String, Object?> payload,
  ) async {
    if (!_firebaseReady) {
      return;
    }

    await _db.child('gameSessions/$gameId/active').update({
      ...payload,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<Map<String, dynamic>?> fetchGameSession(String gameId) async {
    if (!_firebaseReady) {
      return null;
    }

    final snapshot = await _db.child('gameSessions/$gameId/active').get();
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Stream<Map<String, dynamic>?> watchGameSession(String gameId) {
    if (!_firebaseReady) {
      return const Stream.empty();
    }

    return _db.child('gameSessions/$gameId/active').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    });
  }

  Future<void> _saveUserProfile(UserSession session) async {
    if (!_firebaseReady || session.isGuest) {
      return;
    }

    await _db.child('users/${session.id}/profile').update({
      'displayName': session.displayName,
      'email': session.email,
      'updatedAt': ServerValue.timestamp,
    });
  }

  DatabaseReference get _db => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref();
}
