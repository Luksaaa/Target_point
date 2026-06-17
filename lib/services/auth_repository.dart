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

  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _webMessagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
  );
  static const _webProjectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
  );
  static const _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
  );
  static const _webStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
  );
  static const _webMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
  );
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  bool _firebaseReady = false;
  bool _googleReady = false;

  bool get firebaseReady => _firebaseReady;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          if (!_hasWebFirebaseConfig) {
            throw StateError(
              'Missing Firebase web config. Build with FIREBASE_WEB_* dart defines.',
            );
          }
          await Firebase.initializeApp(options: _webFirebaseOptions);
        } else {
          await Firebase.initializeApp();
        }
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

    if (kIsWeb) {
      _googleReady = _firebaseReady;
    } else {
      try {
        await GoogleSignIn.instance.initialize(
          clientId: _googleWebClientId.isNotEmpty ? _googleWebClientId : null,
        );
        _googleReady = true;
      } catch (error) {
        debugPrint('Google Sign-In is not configured yet: $error');
        _googleReady = false;
      }
    }
  }

  bool get _hasWebFirebaseConfig {
    return _webApiKey.isNotEmpty &&
        _webAppId.isNotEmpty &&
        _webMessagingSenderId.isNotEmpty &&
        _webProjectId.isNotEmpty &&
        _webAuthDomain.isNotEmpty;
  }

  FirebaseOptions get _webFirebaseOptions {
    return const FirebaseOptions(
      apiKey: _webApiKey,
      appId: _webAppId,
      messagingSenderId: _webMessagingSenderId,
      projectId: _webProjectId,
      authDomain: _webAuthDomain,
      databaseURL: databaseUrl,
      storageBucket: _webStorageBucket,
      measurementId: _webMeasurementId,
    );
  }

  UserSession? currentSession() {
    if (!_firebaseReady) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    return UserSession(
      id: user.uid,
      displayName: user.displayName ?? 'Player',
      email: user.email,
      avatarColorValue: 0xFF0F8B6B,
      isGuest: false,
      photoUrl: user.photoURL,
    );
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
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(
          provider,
        );
        final user = userCredential.user;
        if (user == null) {
          return const AuthResult.failure(
            'Google sign-in did not return a user.',
          );
        }

        final session = UserSession(
          id: user.uid,
          displayName: user.displayName ?? 'Player',
          email: user.email,
          avatarColorValue: 0xFF0F8B6B,
          isGuest: false,
          photoUrl: user.photoURL,
        );
        await saveUserProfile(session);
        return AuthResult.success(session);
      }

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
        photoUrl: user.photoURL,
      );
      await saveUserProfile(session);
      return AuthResult.success(session);
    } catch (error) {
      final message = error.toString();
      if (message.contains('invalid_request') ||
          message.contains('redirect_uri_mismatch') ||
          message.contains('disallowed_useragent')) {
        return const AuthResult.failure(
          'Google OAuth is misconfigured. Check Firebase Auth Google provider, authorized domains, and OAuth redirect URI.',
        );
      }
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

    await _db.child('users/${followedUser.id}/followers/$ownerUserId').set({
      'displayName': ownerUserId,
      'followedAt': ServerValue.timestamp,
    });
  }

  Future<void> saveSession(
    String sessionId,
    Map<String, Object?> payload,
  ) async {
    if (!_firebaseReady) {
      return;
    }

    await _db.child('sessions/$sessionId').update({
      ...payload,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<Map<String, dynamic>?> fetchSession(String sessionId) async {
    if (!_firebaseReady) {
      return null;
    }

    final snapshot = await _db.child('sessions/$sessionId').get();
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchSportGroupName(
    String sportId,
    String normalizedName,
  ) async {
    if (!_firebaseReady) {
      return null;
    }

    final snapshot = await _db
        .child('sportGroupNames/$sportId/$normalizedName')
        .get();
    final value = snapshot.value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Stream<Map<String, dynamic>?> watchSession(String sessionId) {
    if (!_firebaseReady) {
      return const Stream.empty();
    }

    return _db.child('sessions/$sessionId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    });
  }

  Future<void> saveGameSession(
    String gameId,
    Map<String, Object?> payload,
  ) async {
    await saveSession('$gameId-active', payload);
  }

  Future<Map<String, dynamic>?> fetchGameSession(String gameId) {
    return fetchSession('$gameId-active');
  }

  Stream<Map<String, dynamic>?> watchGameSession(String gameId) {
    return watchSession('$gameId-active');
  }

  Future<void> addUserSession({
    required String userId,
    required String sessionId,
    required String sportId,
    required String sessionName,
    required String role,
    String? groupCode,
  }) async {
    if (!_firebaseReady || userId == 'guest') {
      return;
    }

    await _db.child('userSessions/$userId/$sessionId').update({
      'sessionId': sessionId,
      'groupCode': groupCode,
      'sportId': sportId,
      'sessionName': sessionName,
      'role': role,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<Map<String, dynamic>?> fetchLatestUserSessionForSport({
    required String userId,
    required String sportId,
  }) async {
    if (!_firebaseReady || userId == 'guest') {
      return null;
    }

    final snapshot = await _db.child('userSessions/$userId').get();
    final value = snapshot.value;
    if (value is! Map) {
      return null;
    }

    final sessions =
        Map<String, dynamic>.from(value).values
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .where((entry) => entry['sportId'] == sportId)
            .toList()
          ..sort((a, b) {
            final aUpdated = _intFromValue(a['updatedAt']);
            final bUpdated = _intFromValue(b['updatedAt']);
            return bUpdated.compareTo(aUpdated);
          });

    return sessions.isEmpty ? null : sessions.first;
  }

  Future<List<Map<String, dynamic>>> fetchUserSessionsForSport({
    required String userId,
    required String sportId,
  }) async {
    if (!_firebaseReady || userId == 'guest') {
      return const [];
    }

    final snapshot = await _db.child('userSessions/$userId').get();
    final value = snapshot.value;
    if (value is! Map) {
      return const [];
    }

    final sessions =
        Map<String, dynamic>.from(value).values
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .where((entry) => entry['sportId'] == sportId)
            .toList()
          ..sort((a, b) {
            final aUpdated = _intFromValue(a['updatedAt']);
            final bUpdated = _intFromValue(b['updatedAt']);
            return bUpdated.compareTo(aUpdated);
          });

    return sessions;
  }

  Future<void> reserveSportGroupName({
    required String sportId,
    required String normalizedName,
    required String sessionId,
    required String ownerUserId,
  }) async {
    if (!_firebaseReady || ownerUserId == 'guest') {
      return;
    }

    await _db.child('sportGroupNames/$sportId/$normalizedName').set({
      'sessionId': sessionId,
      'ownerUserId': ownerUserId,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> removeUserSession({
    required String userId,
    required String sessionId,
  }) async {
    if (!_firebaseReady || userId == 'guest') {
      return;
    }

    await _db.child('userSessions/$userId/$sessionId').remove();
  }

  Future<void> addSessionMember({
    required String sessionId,
    required UserSession user,
    required String role,
  }) async {
    if (!_firebaseReady || user.isGuest) {
      return;
    }

    await _db.child('sessions/$sessionId/members/${user.id}').update({
      'role': role,
      'displayName': user.displayName,
      'photoUrl': _databaseSafePhotoUrl(user.photoUrl),
      'joinedAt': ServerValue.timestamp,
    });
  }

  Future<void> saveUserProfile(UserSession session) async {
    if (!_firebaseReady || session.isGuest) {
      return;
    }

    await _db.child('users/${session.id}/profile').update({
      'displayName': session.displayName,
      'email': session.email,
      'avatarColorValue': session.avatarColorValue,
      'photoUrl': _databaseSafePhotoUrl(session.photoUrl),
      'updatedAt': ServerValue.timestamp,
    });

    await _db.child('publicUsers/${session.id}').update({
      'displayName': session.displayName,
      'avatarColorValue': session.avatarColorValue,
      'photoUrl': _databaseSafePhotoUrl(session.photoUrl),
      'updatedAt': ServerValue.timestamp,
    });
  }

  DatabaseReference get _db => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref();

  int _intFromValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String? _databaseSafePhotoUrl(String? value) {
    if (value == null || value.isEmpty || value.startsWith('data:image')) {
      return null;
    }
    return value;
  }
}
