import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'dart_hit.dart';
import 'player_score.dart';
import 'game_settings.dart';
import 'match_history.dart';
import 'user_session.dart';
import '../services/auth_repository.dart';

class PlayerProfile {
  PlayerProfile({
    required this.name,
    required this.avatarColorValue,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.totalScored = 0,
    this.totalThrows = 0,
    this.highestTurn = 0,
    this.doubleHits = 0,
    this.tripleHits = 0,
  });

  String name;
  int avatarColorValue;
  int matchesPlayed;
  int matchesWon;
  int totalScored;
  int totalThrows;
  int highestTurn;
  int doubleHits;
  int tripleHits;

  double get averageScore =>
      totalThrows == 0 ? 0.0 : (totalScored / (totalThrows / 3));
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String role;

  bool get isOwner => role == 'owner';
}

enum GroupDeviceMode { ownDevice, sharedDevices, adminDevice }

enum CheckoutStrategy { professional, adaptive }

enum GroupImportMode { addToCurrent, useSourceValues }

class UserGameGroup {
  const UserGameGroup({
    required this.sessionId,
    required this.groupCode,
    required this.sessionName,
    required this.role,
    this.updatedAt = 0,
    this.memberCount = 0,
  });

  final String sessionId;
  final String groupCode;
  final String sessionName;
  final String role;
  final int updatedAt;
  final int memberCount;

  bool get isOwner => role == 'owner';
}

class SportEvent {
  const SportEvent({
    required this.id,
    required this.playerName,
    required this.label,
    required this.scoreDelta,
    required this.totalScore,
    required this.createdAt,
    this.actionId,
    this.statKey,
  });

  final String id;
  final String playerName;
  final String label;
  final int scoreDelta;
  final int totalScore;
  final DateTime createdAt;
  final String? actionId;
  final String? statKey;
}

class GameStateController extends ChangeNotifier {
  GameStateController({required this.gameId, required this.gameName}) {
    _initializeServices();

    // Setup initial match
    _resetMatch();
  }

  final String gameId;
  final String gameName;

  final AuthRepository _authRepository = AuthRepository();
  StreamSubscription<Map<String, dynamic>?>? _liveMatchSubscription;
  bool _isApplyingRemoteState = false;

  Future<void> _initializeServices() async {
    await _authRepository.initialize();
    _cloudFeaturesAvailable = _authRepository.firebaseReady;
    final savedSession = _authRepository.currentSession();
    if (savedSession != null) {
      _currentUser = savedSession;
      _accountMessage = 'Signed in as ${_currentUser.displayName}.';
      await _activateRealtimeMatchForCurrentUser();
      if (!isLiveMatchActive) {
        _ensureCurrentUserParticipant();
      }
    }
    notifyListeners();
  }

  // Configuration options
  final List<int> scoreOptions = const [301, 501, 701];

  // Navigation tab
  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;

  UserSession _currentUser = const UserSession(
    id: 'guest',
    displayName: 'Guest',
    email: null,
    avatarColorValue: 0xFF0F8B6B,
    isGuest: true,
  );
  UserSession get currentUser => _currentUser;

  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;

  bool _cloudFeaturesAvailable = false;
  bool get cloudFeaturesAvailable => _cloudFeaturesAvailable;

  String? _accountMessage;
  String? get accountMessage => _accountMessage;

  String? _liveMatchId;
  String? get liveMatchId => _liveMatchId;
  String? _activeGroupCode;
  String? get activeSessionId => _activeGroupCode ?? _liveMatchId;

  bool _isLiveHost = false;
  bool get isLiveHost => _isLiveHost;

  String? _liveHostUserId;
  String _activeSessionName = 'Personal session';
  String get activeSessionName => _activeSessionName;
  GroupDeviceMode _deviceMode = GroupDeviceMode.ownDevice;
  GroupDeviceMode get deviceMode => _deviceMode;
  CheckoutStrategy _checkoutStrategy = CheckoutStrategy.professional;
  CheckoutStrategy get checkoutStrategy => _checkoutStrategy;
  final Map<String, Map<String, Object?>> _groupMembers = {};
  final List<UserGameGroup> _userGroups = [];
  List<UserGameGroup> get userGroups => List.unmodifiable(_userGroups);

  String? _liveMatchMessage;
  String? get liveMatchMessage => _liveMatchMessage;
  int _lastLocalSyncAt = 0;
  int _clientRevision = 0;
  Future<void> _syncQueue = Future.value();

  bool get isLiveMatchActive => _liveMatchId != null;
  bool get isDartsGame => gameId == 'darts';

  bool isGroupOwner(PlayerScore player) {
    final userId = player.userId;
    return userId != null && userId == _liveHostUserId;
  }

  bool get canManageGroupMembers {
    return !_currentUser.isGuest &&
        _liveHostUserId != null &&
        _currentUser.id == _liveHostUserId;
  }

  bool get canManageLineup {
    return !isLiveMatchActive || canManageGroupMembers;
  }

  bool get canScoreCurrentTurn {
    if (_players.isEmpty || matchFinished) {
      return false;
    }
    if (!isLiveMatchActive || _currentUser.isGuest) {
      return true;
    }

    if (_deviceMode == GroupDeviceMode.adminDevice) {
      return canManageGroupMembers;
    }

    if (_deviceMode == GroupDeviceMode.sharedDevices) {
      return _players.any((player) => player.userId == _currentUser.id);
    }

    final player = _players[_currentPlayerIndex.clamp(0, _players.length - 1)];
    final userId = player.userId;
    if (userId == null || userId.isEmpty) {
      return canManageGroupMembers;
    }
    return userId == _currentUser.id;
  }

  List<PlayerScore> _dedupedPlayers() {
    final byUserId = <String, PlayerScore>{};
    final localPlayers = <PlayerScore>[];

    for (final player in _players) {
      final userId = player.userId;
      if (userId == null || userId.isEmpty) {
        localPlayers.add(player);
        continue;
      }

      final existing = byUserId[userId];
      if (existing == null) {
        byUserId[userId] = player;
        continue;
      }

      final preferredName =
          player.name.trim().length >= existing.name.trim().length
          ? player.name
          : existing.name;
      byUserId[userId] = player.copyWith(
        name: preferredName,
        remaining: player.remaining,
        totalScored: player.totalScored,
      );
    }

    return [...byUserId.values, ...localPlayers];
  }

  void changeTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  // Player Profiles registry (for lifetime/session stats)
  final List<PlayerProfile> _profiles = [];
  List<PlayerProfile> get profiles => List.unmodifiable(_profiles);

  final List<FollowedUser> _following = [];
  List<FollowedUser> get following => List.unmodifiable(_following);

  List<GroupMember> get groupMembers {
    final members = <String, GroupMember>{};
    for (final entry in _groupMembers.entries) {
      final value = entry.value;
      members[entry.key] = GroupMember(
        userId: entry.key,
        displayName: value['displayName'] as String? ?? 'Player',
        role: value['role'] as String? ?? 'participant',
      );
    }

    for (final player in _players) {
      final userId = player.userId;
      if (userId == null || userId.isEmpty) {
        continue;
      }
      members.putIfAbsent(
        userId,
        () => GroupMember(
          userId: userId,
          displayName: player.name,
          role: userId == _liveHostUserId ? 'owner' : 'participant',
        ),
      );
    }

    if (!_currentUser.isGuest && isLiveMatchActive) {
      members.putIfAbsent(
        _currentUser.id,
        () => GroupMember(
          userId: _currentUser.id,
          displayName: _currentUser.displayName,
          role: _currentUser.id == _liveHostUserId ? 'owner' : 'participant',
        ),
      );
    }

    final sorted = members.values.toList()
      ..sort((a, b) {
        if (a.isOwner != b.isOwner) {
          return a.isOwner ? -1 : 1;
        }
        return a.displayName.compareTo(b.displayName);
      });
    return sorted;
  }

  // Active game settings
  GameSettings _settings = const GameSettings(
    mode: GameMode.x01,
    startingScore: 501,
    outRule: OutRule.doubleOut,
  );
  GameSettings get settings => _settings;

  // Active match state
  List<PlayerScore> _players = [];
  List<PlayerScore> get players => _dedupedPlayers();
  final List<SportEvent> _sportEvents = [];
  List<SportEvent> get sportEvents => List.unmodifiable(_sportEvents);

  final List<DartHit> _currentTurn = [];
  List<DartHit> get currentTurn => _currentTurn;

  bool get hasActiveMatchProgress {
    return _currentTurn.isNotEmpty ||
        _sportEvents.isNotEmpty ||
        _players.any(
          (player) =>
              player.turns.isNotEmpty ||
              player.totalScored != 0 ||
              player.isWinner,
        );
  }

  int _currentPlayerIndex = 0;
  int get currentPlayerIndex => _currentPlayerIndex;

  String? _matchMessage;
  String? get matchMessage => _matchMessage;

  int get _scoringPlayerIndex {
    if (_players.isEmpty) {
      return 0;
    }
    if (_currentPlayerIndex >= _players.length) {
      return 0;
    }
    return _currentPlayerIndex;
  }

  PlayerScore get currentPlayer => _players.isEmpty
      ? const PlayerScore(
          name: 'No Players',
          avatarColorValue: 0xFF9E9E9E,
          remaining: 0,
          totalScored: 0,
          turns: [],
          isWinner: false,
        )
      : _players[_scoringPlayerIndex];
  bool get matchFinished => _players.isEmpty || _players.any((p) => p.isWinner);

  String? get checkoutHint {
    if (!isDartsGame ||
        matchFinished ||
        _settings.mode != GameMode.x01 ||
        _players.isEmpty) {
      return null;
    }

    final pendingScore = _currentTurn.fold<int>(
      0,
      (total, hit) => total + hit.score,
    );
    final remaining = currentPlayer.remaining - pendingScore;
    final dartsLeft = 3 - _currentTurn.length;
    if (remaining <= 0 || dartsLeft <= 0 || remaining > 170) {
      return null;
    }

    return _checkoutFor(remaining, dartsLeft);
  }

  // Match history list
  final List<MatchHistoryEntry> _matchHistory = [];
  List<MatchHistoryEntry> get matchHistory => List.unmodifiable(_matchHistory);

  // Search Results & state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<PlayerProfile> get filteredProfiles {
    if (_searchQuery.isEmpty) return _profiles;
    return _profiles
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Account and social state
  Future<void> signInWithGoogle() async {
    if (_isSigningIn) {
      return;
    }

    _isSigningIn = true;
    _accountMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.signInWithGoogle().timeout(
        const Duration(seconds: 45),
        onTimeout: () => const AuthResult.failure(
          'Google sign-in timed out. Close the Google window and try again.',
        ),
      );
      if (result.isSuccess) {
        _currentUser = result.session!;
        _accountMessage = 'Signed in as ${_currentUser.displayName}.';
        await _refreshUserGroups();
        await _activateRealtimeMatchForCurrentUser();
        if (!isLiveMatchActive) {
          _ensureCurrentUserParticipant();
        }
      } else {
        _accountMessage = result.errorMessage;
      }
    } catch (error) {
      _accountMessage = 'Google sign-in failed: $error';
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await leaveLiveMatch();
    await _authRepository.signOut();
    _players.clear();
    _profiles.clear();
    _following.clear();
    _userGroups.clear();
    _matchHistory.clear();
    _currentTurn.clear();
    _currentPlayerIndex = 0;
    _matchMessage = null;
    _currentUser = const UserSession(
      id: 'guest',
      displayName: 'Guest',
      email: null,
      avatarColorValue: 0xFF0F8B6B,
      isGuest: true,
    );
    _accountMessage = 'Signed out. Guest mode is active.';
    notifyListeners();
  }

  void updateUserProfile(
    String displayName,
    int avatarColorValue, {
    String? photoUrl,
  }) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _currentUser = _currentUser.copyWith(
      displayName: trimmed,
      avatarColorValue: avatarColorValue,
      photoUrl: photoUrl,
    );
    _accountMessage = _currentUser.isGuest
        ? 'Guest profile updated locally.'
        : 'Profile updated for this session.';
    _ensureCurrentUserParticipant();
    if (!_currentUser.isGuest) {
      _authRepository.saveUserProfile(_currentUser).catchError((Object error) {
        _accountMessage = 'Could not save profile: $error';
        notifyListeners();
      });
    }
    _syncLiveMatch();
    notifyListeners();
  }

  void _ensureCurrentUserParticipant() {
    if (_currentUser.isGuest) {
      return;
    }

    final existingProfileIndex = _profiles.indexWhere(
      (profile) => profile.name == _currentUser.displayName,
    );
    if (existingProfileIndex == -1) {
      _profiles.add(
        PlayerProfile(
          name: _currentUser.displayName,
          avatarColorValue: _currentUser.avatarColorValue,
        ),
      );
    } else {
      _profiles[existingProfileIndex].avatarColorValue =
          _currentUser.avatarColorValue;
    }

    final existingPlayerIndex = _players.indexWhere(
      (player) => player.userId == _currentUser.id,
    );
    final sameNamePlayerIndex = _players.indexWhere(
      (player) =>
          (player.userId == null || player.userId!.isEmpty) &&
          player.name.trim().toLowerCase() ==
              _currentUser.displayName.trim().toLowerCase(),
    );
    final player = PlayerScore(
      userId: _currentUser.id,
      name: _currentUser.displayName,
      avatarColorValue: _currentUser.avatarColorValue,
      photoUrl: _currentUser.photoUrl,
      remaining: _settings.mode == GameMode.x01 && isDartsGame
          ? _settings.startingScore
          : 0,
      totalScored: 0,
      turns: const [],
      isWinner: false,
    );

    if (existingPlayerIndex == -1) {
      if (sameNamePlayerIndex != -1) {
        _players[sameNamePlayerIndex] = _players[sameNamePlayerIndex].copyWith(
          userId: _currentUser.id,
          name: _currentUser.displayName,
          avatarColorValue: _currentUser.avatarColorValue,
          photoUrl: _currentUser.photoUrl,
        );
        return;
      }

      _players.add(player);
      if (_currentPlayerIndex >= _players.length) {
        _currentPlayerIndex = 0;
      }
    } else {
      _players[existingPlayerIndex] = _players[existingPlayerIndex].copyWith(
        userId: _currentUser.id,
        name: _currentUser.displayName,
        avatarColorValue: _currentUser.avatarColorValue,
        photoUrl: _currentUser.photoUrl,
      );
    }
  }

  Future<void> _activateRealtimeMatchForCurrentUser() async {
    if (!_cloudFeaturesAvailable || _currentUser.isGuest) {
      return;
    }

    await _refreshUserGroups();
    final lastSession = _userGroups.isNotEmpty
        ? <String, Object?>{
            'sessionId': _userGroups.first.sessionId,
            'sessionName': _userGroups.first.sessionName,
            'role': _userGroups.first.role,
          }
        : await _authRepository.fetchLatestUserSessionForSport(
            userId: _currentUser.id,
            sportId: gameId,
          );
    final lastSessionId = lastSession?['sessionId'] as String?;
    if (lastSessionId != null && lastSessionId.isNotEmpty) {
      final loaded = await selectUserGroup(lastSessionId, notify: false);
      if (loaded) {
        return;
      }
    }

    _liveMatchId = null;
    _activeGroupCode = null;
    _activeSessionName = '';
    _isLiveHost = false;
    _liveHostUserId = null;
    _groupMembers.clear();
    _liveMatchMessage = 'Create or join a group to sync this match.';
    notifyListeners();
  }

  Future<void> _refreshUserGroups() async {
    if (!_cloudFeaturesAvailable || _currentUser.isGuest) {
      _userGroups.clear();
      return;
    }

    final sessions = await _authRepository.fetchUserSessionsForSport(
      userId: _currentUser.id,
      sportId: gameId,
    );
    _userGroups
      ..clear()
      ..addAll(
        sessions
            .map((entry) {
              final sessionId = entry['sessionId'] as String? ?? '';
              final sessionParts = sessionId.split('_');
              final fallbackCode = sessionParts.isEmpty
                  ? sessionId
                  : sessionParts.last;
              return UserGameGroup(
                sessionId: sessionId,
                groupCode: (entry['groupCode'] as String? ?? fallbackCode)
                    .toUpperCase(),
                sessionName:
                    entry['sessionName'] as String? ??
                    (fallbackCode.isEmpty ? '$gameName group' : fallbackCode),
                role: entry['role'] as String? ?? 'participant',
                updatedAt: _intFromValue(entry['updatedAt']),
                memberCount: _intFromValue(entry['memberCount']),
              );
            })
            .where((group) => group.sessionId.isNotEmpty),
      );
  }

  Future<bool> selectUserGroup(String sessionId, {bool notify = true}) async {
    if (!_cloudFeaturesAvailable || _currentUser.isGuest) {
      return false;
    }

    final normalizedSessionId = sessionId.contains('_')
        ? sessionId
        : _sessionIdFromGroupCode(sessionId);
    if (normalizedSessionId == _liveMatchId) {
      return true;
    }

    final payload = await _authRepository.fetchSession(normalizedSessionId);
    if (payload == null) {
      _liveMatchMessage = 'Group not found.';
      if (notify) {
        notifyListeners();
      }
      return false;
    }

    await _liveMatchSubscription?.cancel();
    _currentTurn.clear();
    _liveMatchId = normalizedSessionId;
    final sessionParts = normalizedSessionId.split('_');
    _activeGroupCode =
        payload['groupCode'] as String? ??
        (sessionParts.isEmpty ? normalizedSessionId : sessionParts.last);
    final matchingGroupName = _userGroups
        .where((group) => group.sessionId == normalizedSessionId)
        .map((group) => group.sessionName)
        .cast<String?>()
        .firstWhere((name) => name != null, orElse: () => null);
    _activeSessionName =
        payload['sessionName'] as String? ??
        matchingGroupName ??
        '$gameName group';
    _applyLivePayload(payload);
    _ensureCurrentUserParticipant();
    _subscribeToLiveMatch(normalizedSessionId);
    _liveMatchMessage = 'Group loaded.';
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<void> createCloudSession(String sessionName) async {
    if (!_cloudFeaturesAvailable || _currentUser.isGuest) {
      _liveMatchMessage = 'Sign in to create a synced group.';
      notifyListeners();
      return;
    }

    final trimmed = sessionName.trim();
    if (trimmed.isEmpty) {
      _liveMatchMessage = 'Group name is required.';
      notifyListeners();
      return;
    }
    if (trimmed.length > 16) {
      _liveMatchMessage = 'Group name can have max 16 characters.';
      notifyListeners();
      return;
    }

    final normalizedName = _normalizeGroupName(trimmed);
    Map<String, dynamic>? existingName;
    try {
      existingName = await _authRepository.fetchSportGroupName(
        gameId,
        normalizedName,
      );
    } catch (_) {
      existingName = null;
    }
    if (existingName != null) {
      _liveMatchMessage = 'Group name already exists for $gameName.';
      notifyListeners();
      return;
    }

    final safeName = trimmed;
    final groupCode = await _generateAvailableGroupCode();
    final sessionId = _sessionIdFromGroupCode(groupCode);

    await _liveMatchSubscription?.cancel();
    _liveMatchId = sessionId;
    _activeGroupCode = groupCode;
    _activeSessionName = safeName;
    _isLiveHost = true;
    _liveHostUserId = _currentUser.id;
    _liveMatchMessage = 'Created group $groupCode.';
    _startFreshGroupForCurrentUser();
    _ensureCurrentUserParticipant();
    final synced = await _syncLiveMatch();
    if (!synced) {
      return;
    }
    _subscribeToLiveMatch(sessionId);
    try {
      await _authRepository.addUserSession(
        userId: _currentUser.id,
        sessionId: sessionId,
        groupCode: groupCode,
        sportId: gameId,
        sessionName: safeName,
        role: 'owner',
        memberCount: _players.length,
      );
      await _authRepository.reserveSportGroupName(
        sportId: gameId,
        normalizedName: normalizedName,
        sessionId: sessionId,
        ownerUserId: _currentUser.id,
      );
    } catch (_) {
      _liveMatchMessage = 'Created group $groupCode.';
    }
    await _refreshUserGroups();
    notifyListeners();
  }

  void _startFreshGroupForCurrentUser() {
    _groupMembers.clear();
    _currentTurn.clear();
    _sportEvents.clear();
    _matchMessage = null;
    _currentPlayerIndex = 0;
    _deviceMode = GroupDeviceMode.ownDevice;
    _checkoutStrategy = CheckoutStrategy.professional;
    _clientRevision = 0;
    _lastLocalSyncAt = 0;
    _players = [
      PlayerScore(
        userId: _currentUser.id,
        name: _currentUser.displayName,
        avatarColorValue: _currentUser.avatarColorValue,
        photoUrl: _currentUser.photoUrl,
        remaining: _settings.mode == GameMode.x01 && isDartsGame
            ? _settings.startingScore
            : 0,
        totalScored: 0,
        turns: const [],
        isWinner: false,
      ),
    ];
  }

  Future<void> joinCloudSession(String sessionId) async {
    final groupCode = sessionId.trim().toUpperCase();
    final trimmed = _sessionIdFromGroupCode(groupCode);
    if (trimmed.isEmpty) {
      return;
    }
    if (!_cloudFeaturesAvailable || _currentUser.isGuest) {
      _liveMatchMessage = 'Sign in to join a synced group.';
      notifyListeners();
      return;
    }

    final payload = await _authRepository.fetchSession(trimmed);
    if (payload == null) {
      _liveMatchMessage = 'Group not found.';
      notifyListeners();
      return;
    }

    await _liveMatchSubscription?.cancel();
    _liveMatchId = trimmed;
    _activeGroupCode = groupCode;
    _activeSessionName =
        payload['sessionName'] as String? ??
        payload['gameName'] as String? ??
        '$gameName session';
    _applyLivePayload(payload);
    _ensureCurrentUserParticipant();
    try {
      await _authRepository.addSessionMember(
        sessionId: trimmed,
        user: _currentUser,
        role: 'participant',
      );
      await _authRepository.addUserSession(
        userId: _currentUser.id,
        sessionId: trimmed,
        groupCode: groupCode,
        sportId: gameId,
        sessionName: _activeSessionName,
        role: 'participant',
        memberCount: _players.length,
      );
      _subscribeToLiveMatch(trimmed);
      await _syncLiveMatch();
      _liveMatchMessage = 'Joined group $groupCode.';
      await _refreshUserGroups();
    } catch (error) {
      await leaveLiveMatch();
      _liveMatchMessage = 'Could not join group: $error';
    }
    notifyListeners();
  }

  Future<void> leaveLiveMatch() async {
    await _liveMatchSubscription?.cancel();
    _liveMatchSubscription = null;
    _liveMatchId = null;
    _activeGroupCode = null;
    _isLiveHost = false;
    _liveHostUserId = null;
    _deviceMode = GroupDeviceMode.ownDevice;
    _groupMembers.clear();
    _liveMatchMessage = 'Live match left.';
    notifyListeners();
  }

  Future<void> leaveGroup() async {
    final sessionId = _liveMatchId;
    if (sessionId == null || _currentUser.isGuest) {
      await leaveLiveMatch();
      return;
    }

    try {
      final payload = _livePayload();
      final members = Map<String, Object?>.from(
        payload['members'] as Map<String, Object?>,
      )..remove(_currentUser.id);
      final players = _players
          .where((player) => player.userId != _currentUser.id)
          .map(_playerToMap)
          .toList();
      final participants = _players
          .where((player) => player.userId != _currentUser.id)
          .map(_playerToParticipantMap)
          .toList();

      await _authRepository.saveSession(sessionId, {
        ...payload,
        'members': members,
        'players': players,
        'participants': participants,
        'updatedByUserId': _currentUser.id,
      });
      await _authRepository.removeUserSession(
        userId: _currentUser.id,
        sessionId: sessionId,
      );
      await _refreshUserGroups();
    } catch (error) {
      _liveMatchMessage = 'Could not leave group: $error';
      notifyListeners();
      return;
    }

    _players.removeWhere((player) => player.userId == _currentUser.id);
    _currentTurn.clear();
    _currentPlayerIndex = _players.isEmpty
        ? 0
        : _currentPlayerIndex % _players.length;
    await leaveLiveMatch();
    _liveMatchMessage = 'You left the group.';
    if (_userGroups.isNotEmpty) {
      await selectUserGroup(_userGroups.first.sessionId, notify: false);
    }
    notifyListeners();
  }

  void _subscribeToLiveMatch(String matchId) {
    _liveMatchSubscription?.cancel();
    _liveMatchSubscription = _authRepository.watchSession(matchId).listen((
      payload,
    ) {
      if (payload == null) {
        return;
      }
      _applyLivePayload(payload);
    });
  }

  Future<bool> _syncLiveMatch() {
    final matchId = _liveMatchId;
    if (matchId == null || _isApplyingRemoteState || _currentUser.isGuest) {
      return Future.value(false);
    }

    _lastLocalSyncAt = DateTime.now().millisecondsSinceEpoch;
    _clientRevision += 1;
    final payload = _livePayload();
    final completer = Completer<bool>();

    _syncQueue = _syncQueue.then((_) async {
      try {
        await _authRepository.saveSession(matchId, payload);
        completer.complete(true);
      } catch (error) {
        _liveMatchMessage = 'Could not sync group: $error';
        notifyListeners();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  Map<String, Object?> _livePayload() {
    return {
      'id': _liveMatchId,
      'groupCode': _activeGroupCode,
      'sessionName': _activeSessionName,
      'gameId': gameId,
      'gameName': gameName,
      'sportId': gameId,
      'sportName': gameName,
      'deviceMode': _deviceMode.name,
      'checkoutStrategy': _checkoutStrategy.name,
      'hostUserId': _liveHostUserId ?? _currentUser.id,
      'ownerUserId': _liveHostUserId ?? _currentUser.id,
      'updatedByUserId': _currentUser.id,
      'clientUpdatedAt': _lastLocalSyncAt,
      'clientRevision': _clientRevision,
      'status': matchFinished ? 'finished' : 'active',
      'members': _membersToMap(),
      'settings': _settingsToMap(_settings),
      'players': _players.map(_playerToMap).toList(),
      'participants': _players.map(_playerToParticipantMap).toList(),
      'sportEvents': _sportEvents.map(_sportEventToMap).toList(),
      'matchHistory': _matchHistory.map(_matchHistoryToMap).toList(),
      'currentTurn': _currentTurn.map(_hitToMap).toList(),
      'currentPlayerIndex': _currentPlayerIndex,
      'matchMessage': _matchMessage,
    };
  }

  void _applyLivePayload(Map<String, dynamic> payload) {
    final remoteUpdatedAt = _intFromValue(payload['clientUpdatedAt']);
    final remoteRevision = _intFromValue(payload['clientRevision']);
    if (remoteRevision != 0 && remoteRevision < _clientRevision) {
      return;
    }
    final hasRecentLocalWrite =
        _lastLocalSyncAt != 0 &&
        DateTime.now().millisecondsSinceEpoch - _lastLocalSyncAt < 10000;
    if (hasRecentLocalWrite &&
        (remoteUpdatedAt == 0 || remoteUpdatedAt < _lastLocalSyncAt)) {
      return;
    }

    _isApplyingRemoteState = true;
    try {
      final settingsValue = payload['settings'];
      final playersValue = payload['players'];
      final membersValue = payload['members'];
      final turnValue = payload['currentTurn'];
      final sportEventsValue = payload['sportEvents'];
      final historyValue = payload['matchHistory'];
      _liveMatchId = payload['id'] as String? ?? _liveMatchId;
      _activeGroupCode = payload['groupCode'] as String? ?? _activeGroupCode;
      _activeSessionName =
          payload['sessionName'] as String? ?? _activeSessionName;
      _liveHostUserId =
          payload['hostUserId'] as String? ??
          payload['ownerUserId'] as String? ??
          _liveHostUserId;
      _deviceMode = GroupDeviceMode.values.firstWhere(
        (mode) => mode.name == payload['deviceMode'],
        orElse: () => GroupDeviceMode.ownDevice,
      );
      _checkoutStrategy = CheckoutStrategy.values.firstWhere(
        (strategy) => strategy.name == payload['checkoutStrategy'],
        orElse: () => CheckoutStrategy.professional,
      );
      if (remoteRevision > _clientRevision) {
        _clientRevision = remoteRevision;
      }
      _isLiveHost = _liveHostUserId == _currentUser.id;

      if (settingsValue is Map) {
        _settings = _settingsFromMap(Map<String, dynamic>.from(settingsValue));
      }
      _players = _asList(playersValue)
          .whereType<Map>()
          .map((value) => _playerFromMap(Map<String, dynamic>.from(value)))
          .toList();
      if (_players.isEmpty) {
        _players = _profiles.map(_playerFromProfile).toList();
      }
      _mergeMembersIntoPlayers(membersValue);
      _currentTurn
        ..clear()
        ..addAll(
          _asList(turnValue).whereType<Map>().map(
            (value) => _hitFromMap(Map<String, dynamic>.from(value)),
          ),
        );
      _sportEvents
        ..clear()
        ..addAll(
          _asList(sportEventsValue).whereType<Map>().map(
            (value) => _sportEventFromMap(Map<String, dynamic>.from(value)),
          ),
        );
      if (payload.containsKey('matchHistory')) {
        _matchHistory
          ..clear()
          ..addAll(
            _asList(historyValue).whereType<Map>().map(
              (value) => _matchHistoryFromMap(Map<String, dynamic>.from(value)),
            ),
          );
      }
      _currentPlayerIndex = _intFromValue(payload['currentPlayerIndex']);
      if (_currentPlayerIndex >= _players.length) {
        _currentPlayerIndex = 0;
      }
      _matchMessage = payload['matchMessage'] as String?;
      _liveMatchMessage = 'Live match synced.';
    } finally {
      _isApplyingRemoteState = false;
    }
    notifyListeners();
  }

  Future<void> addParticipantToSession(String displayNameOrUserId) async {
    final value = displayNameOrUserId.trim();
    if (value.isEmpty) {
      return;
    }

    final existing = _players.any(
      (player) =>
          player.name.toLowerCase() == value.toLowerCase() ||
          player.userId == value,
    );
    if (existing) {
      _liveMatchMessage = '$value is already in this session.';
      notifyListeners();
      return;
    }

    addPlayerProfile(value, _nextAvatarColor());
  }

  void followUser(String displayNameOrHandle) {
    final value = displayNameOrHandle.trim();
    if (value.isEmpty) {
      return;
    }

    final normalized = value.startsWith('@') ? value.substring(1) : value;
    final id = normalized.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (_following.any((user) => user.id == id)) {
      return;
    }

    final followedUser = FollowedUser(
      id: id,
      displayName: normalized,
      handle: '@$id',
    );
    _following.add(followedUser);
    _authRepository
        .followUser(ownerUserId: _currentUser.id, followedUser: followedUser)
        .catchError((Object error) {
          _accountMessage = 'Could not sync following to Firebase: $error';
        });
    _accountMessage = _currentUser.isGuest
        ? 'Following saved for this guest session.'
        : 'Following ${followedUser.displayName}.';
    notifyListeners();
  }

  List<MatchHistoryEntry> get filteredHistory {
    if (_searchQuery.isEmpty) return _matchHistory;
    return _matchHistory.where((m) {
      final query = _searchQuery.toLowerCase();
      final dateStr = '${m.date.day}.${m.date.month}.${m.date.year}';
      return m.winnerName.toLowerCase().contains(query) ||
          m.settings.mode.name.toLowerCase().contains(query) ||
          dateStr.contains(query) ||
          m.finalScores.any((p) => p.name.toLowerCase().contains(query));
    }).toList();
  }

  // Manage Profiles & Players list
  void addPlayerProfile(String name, int colorValue) {
    final existing = _profiles.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );
    if (existing) return; // Prevent duplicate profile names

    final newProfile = PlayerProfile(name: name, avatarColorValue: colorValue);
    _profiles.add(newProfile);

    // If the match has room to edit, add to the active leaderboard.
    if (_players.isEmpty || !matchFinished) {
      _players.add(
        PlayerScore(
          name: name,
          avatarColorValue: colorValue,
          remaining: _settings.mode == GameMode.x01
              ? _settings.startingScore
              : 0,
          totalScored: 0,
          turns: const [],
          isWinner: false,
        ),
      );
    }
    _syncLiveMatch();
    notifyListeners();
  }

  void deletePlayer(int index) {
    if (_players.length <= 1) return; // Must have at least 1 player

    final removedPlayer = _players.removeAt(index);
    final removedUserId = removedPlayer.userId;
    if (removedUserId != null) {
      _groupMembers.remove(removedUserId);
    }
    if (_currentPlayerIndex >= _players.length) {
      _currentPlayerIndex = 0;
    }
    _currentTurn.clear();
    _matchMessage = 'Removed ${removedPlayer.name} from current match.';
    _syncLiveMatch();
    notifyListeners();
  }

  void removeGroupPlayer(PlayerScore player) {
    final index = _players.indexWhere((candidate) {
      if (player.userId != null) {
        return candidate.userId == player.userId;
      }
      return candidate.name == player.name;
    });
    if (index == -1) {
      return;
    }
    deletePlayer(index);
  }

  void reorderPlayers(int oldIndex, int newIndex) {
    if (!canManageLineup) {
      _liveMatchMessage = 'Only the group admin can reorder players.';
      notifyListeners();
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final player = _players.removeAt(oldIndex);
    _players.insert(newIndex, player);

    // The first player in the admin-defined lineup throws next.
    _currentPlayerIndex = 0;
    _syncLiveMatch();
    notifyListeners();
  }

  void updateDeviceMode(GroupDeviceMode mode) {
    if (isLiveMatchActive && !canManageGroupMembers) {
      _liveMatchMessage = 'Only the group admin can change device mode.';
      notifyListeners();
      return;
    }
    _deviceMode = mode;
    _syncLiveMatch();
    notifyListeners();
  }

  void updateCheckoutStrategy(CheckoutStrategy strategy) {
    if (isLiveMatchActive && !canManageGroupMembers) {
      _liveMatchMessage = 'Only the group admin can change checkout advice.';
      notifyListeners();
      return;
    }
    _checkoutStrategy = strategy;
    _syncLiveMatch();
    notifyListeners();
  }

  Future<void> importStatsFromGroup(
    String sessionId, {
    GroupImportMode mode = GroupImportMode.addToCurrent,
  }) async {
    if (!_cloudFeaturesAvailable || _currentUser.isGuest) {
      _liveMatchMessage = 'Sign in to import group stats.';
      notifyListeners();
      return;
    }
    if (!isLiveMatchActive) {
      _liveMatchMessage = 'Open a group before importing stats.';
      notifyListeners();
      return;
    }
    if (!canManageGroupMembers) {
      _liveMatchMessage = 'Only the group admin can import stats.';
      notifyListeners();
      return;
    }
    if (sessionId == _liveMatchId) {
      _liveMatchMessage = 'Choose a different group to import from.';
      notifyListeners();
      return;
    }

    final payload = await _authRepository.fetchSession(sessionId);
    if (payload == null) {
      _liveMatchMessage = 'Source group was not found.';
      notifyListeners();
      return;
    }

    final sourcePlayers = _asList(payload['players'])
        .whereType<Map>()
        .map((value) => _playerFromMap(Map<String, dynamic>.from(value)))
        .toList();
    final sourceHistory = _asList(payload['matchHistory'])
        .whereType<Map>()
        .map((value) => _matchHistoryFromMap(Map<String, dynamic>.from(value)))
        .toList();
    var imported = 0;

    for (final source in sourcePlayers) {
      final sourceStats = _persistentStatsForNewMatch(source.stats);
      final targetIndex = _players.indexWhere((player) {
        final sourceUserId = source.userId;
        if (sourceUserId != null && sourceUserId.isNotEmpty) {
          return player.userId == sourceUserId;
        }
        return player.name.trim().toLowerCase() ==
            source.name.trim().toLowerCase();
      });

      if (targetIndex == -1) {
        _players.add(
          source.copyWith(
            remaining: _settings.mode == GameMode.x01 && isDartsGame
                ? _settings.startingScore
                : 0,
            totalScored: 0,
            turns: const [],
            isWinner: false,
            stats: sourceStats,
          ),
        );
        imported++;
      } else {
        if (sourceStats.isEmpty) {
          continue;
        }
        final target = _players[targetIndex];
        _players[targetIndex] = target.copyWith(
          stats: mode == GroupImportMode.addToCurrent
              ? _mergedStats(target.stats, sourceStats)
              : sourceStats,
        );
        imported++;
      }
    }

    var importedHistory = 0;
    for (final entry in sourceHistory.reversed) {
      if (_matchHistory.any((current) => current.id == entry.id)) {
        continue;
      }
      _matchHistory.insert(0, entry);
      importedHistory++;
    }

    _liveMatchMessage = imported == 0
        ? 'No stats were available to import.'
        : 'Imported stats for $imported players.';
    if (importedHistory > 0) {
      _liveMatchMessage =
          '${_liveMatchMessage!} Imported $importedHistory history entries.';
    }
    _syncLiveMatch();
    notifyListeners();
  }

  void updatePlayerProfile(String oldName, String newName, int colorValue) {
    final pIndex = _profiles.indexWhere((p) => p.name == oldName);
    if (pIndex != -1) {
      _profiles[pIndex].name = newName;
      _profiles[pIndex].avatarColorValue = colorValue;
    }

    // Also update in the active game if present
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].name == oldName) {
        _players[i] = _players[i].copyWith(
          name: newName,
          avatarColorValue: colorValue,
        );
      }
    }
    _syncLiveMatch();
    notifyListeners();
  }

  // Scoring Logic & Actions
  void handleHit(DartHit hit) {
    if (!canScoreCurrentTurn || _currentTurn.length == 3) {
      if (!canScoreCurrentTurn && isLiveMatchActive) {
        _matchMessage = 'Waiting for ${currentPlayer.name}.';
        notifyListeners();
      }
      return;
    }

    _currentTurn.add(hit);
    _matchMessage = null;
    _syncLiveMatch();
    notifyListeners();
  }

  void setManualDartScore(int index, int score) {
    final normalizedScore = score.clamp(0, 60).toInt();
    setManualDartHit(index, _manualDartHit(normalizedScore));
  }

  void setManualDartHit(int index, DartHit hit) {
    if (!canScoreCurrentTurn || index < 0 || index > 2) {
      if (!canScoreCurrentTurn && isLiveMatchActive) {
        _matchMessage = 'Waiting for ${currentPlayer.name}.';
        notifyListeners();
      }
      return;
    }

    while (_currentTurn.length < index) {
      _currentTurn.add(_manualDartHit(0));
    }

    if (index < _currentTurn.length) {
      _currentTurn[index] = hit;
    } else if (_currentTurn.length < 3) {
      _currentTurn.add(hit);
    }

    _matchMessage = null;
    _syncLiveMatch();
    notifyListeners();
  }

  void undoLastHit() {
    if (_currentTurn.isEmpty || !canScoreCurrentTurn) {
      return;
    }

    _currentTurn.removeLast();
    _matchMessage = null;
    _syncLiveMatch();
    notifyListeners();
  }

  void addMiss() {
    handleHit(
      const DartHit(
        label: 'MISS',
        score: 0,
        band: SegmentBand.miss,
        dx: 0,
        dy: -0.99,
      ),
    );
  }

  DartHit _manualDartHit(int score) {
    return DartHit(
      label: score == 0 ? 'MISS' : score.toString(),
      score: score,
      band: score == 0 ? SegmentBand.miss : SegmentBand.single,
      dx: 0,
      dy: 0,
    );
  }

  void adjustCurrentPlayerScore(int delta) {
    if (_players.isEmpty || isDartsGame || !canScoreCurrentTurn) {
      return;
    }

    final playerIndex = _scoringPlayerIndex;
    final player = _players[playerIndex];
    final nextScore = (player.totalScored + delta).clamp(0, 999999);
    _players[playerIndex] = player.copyWith(
      remaining: nextScore,
      totalScored: nextScore,
    );
    _matchMessage = '${player.name}: $nextScore';
    _syncLiveMatch();
    notifyListeners();
  }

  void applySportAction({
    required String label,
    String? actionId,
    int scoreDelta = 0,
    String? statKey,
    int statDelta = 1,
    bool endsTurn = false,
  }) {
    if (_players.isEmpty || isDartsGame || !canScoreCurrentTurn) {
      return;
    }

    final playerIndex = _scoringPlayerIndex;
    final player = _players[playerIndex];
    final nextStats = Map<String, int>.from(player.stats);
    if (statKey != null) {
      nextStats[statKey] = ((nextStats[statKey] ?? 0) + statDelta).clamp(
        0,
        999999,
      );
    }
    final nextScore = (player.totalScored + scoreDelta).clamp(0, 999999);
    _players[playerIndex] = player.copyWith(
      remaining: nextScore,
      totalScored: nextScore,
      stats: nextStats,
    );
    _sportEvents.insert(
      0,
      SportEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        playerName: player.name,
        label: label,
        actionId: actionId,
        scoreDelta: scoreDelta,
        totalScore: nextScore,
        statKey: statKey,
        createdAt: DateTime.now(),
      ),
    );
    _matchMessage = scoreDelta == 0
        ? '${player.name}: $label'
        : '${player.name}: $label ($nextScore)';
    if (endsTurn && _players.length > 1) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    }
    _syncLiveMatch();
    notifyListeners();
  }

  void removeSportEvent(String eventId) {
    if (!canManageGroupMembers) {
      return;
    }
    final eventIndex = _sportEvents.indexWhere((event) => event.id == eventId);
    if (eventIndex == -1) {
      return;
    }

    final event = _sportEvents.removeAt(eventIndex);
    final playerIndex = _players.indexWhere(
      (player) => player.name == event.playerName,
    );
    if (playerIndex != -1) {
      final player = _players[playerIndex];
      final nextStats = Map<String, int>.from(player.stats);
      final statKey = event.statKey;
      if (statKey != null) {
        final nextValue = (nextStats[statKey] ?? 0) - 1;
        if (nextValue <= 0) {
          nextStats.remove(statKey);
        } else {
          nextStats[statKey] = nextValue;
        }
      }
      final nextScore = (player.totalScored - event.scoreDelta).clamp(
        0,
        999999,
      );
      _players[playerIndex] = player.copyWith(
        remaining: nextScore,
        totalScored: nextScore,
        stats: nextStats,
      );
    }

    _matchMessage = 'Removed ${event.label} for ${event.playerName}.';
    _syncLiveMatch();
    notifyListeners();
  }

  void advanceGenericTurn() {
    if (_players.isEmpty || isDartsGame || !canScoreCurrentTurn) {
      return;
    }

    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    _matchMessage = '${currentPlayer.name} is next.';
    _syncLiveMatch();
    notifyListeners();
  }

  void commitTurn() {
    if (_currentTurn.isEmpty || !canScoreCurrentTurn) {
      return;
    }

    final playerIndex = _scoringPlayerIndex;
    final player = _players[playerIndex];
    final turnScore = _currentTurn.fold<int>(
      0,
      (total, hit) => total + hit.score,
    );
    final nextTurns = [...player.turns, List<DartHit>.from(_currentTurn)];

    if (_settings.mode == GameMode.countUp) {
      _players[playerIndex] = player.copyWith(
        remaining: player.remaining + turnScore,
        totalScored: player.totalScored + turnScore,
        turns: nextTurns,
      );
      _matchMessage = '${player.name} scored $turnScore.';
      _advanceTurn();
      _syncLiveMatch();
      notifyListeners();
      return;
    }

    // X01 logic
    final nextRemaining = player.remaining - turnScore;
    final finishingHit = _currentTurn.last;
    final hasValidFinish = _isValidFinish(nextRemaining, finishingHit);
    final isBust =
        nextRemaining < 0 ||
        nextRemaining == 1 ||
        (nextRemaining == 0 && !hasValidFinish);

    if (isBust) {
      _players[playerIndex] = player.copyWith(turns: nextTurns);
      _matchMessage =
          '${player.name} busts. Score stays at ${player.remaining}.';

      // Update profiles stats for throw (bust throws still count as throws)
      _updateProfileStatsForPlayer(player.name, _currentTurn, 0, false);

      _advanceTurn();
      _syncLiveMatch();
      notifyListeners();
      return;
    }

    final isWinner = nextRemaining == 0;
    final nextStats = Map<String, int>.from(player.stats);
    if (isWinner) {
      nextStats['wins'] = (nextStats['wins'] ?? 0) + 1;
    }
    _players[playerIndex] = player.copyWith(
      remaining: nextRemaining,
      totalScored: player.totalScored + turnScore,
      turns: nextTurns,
      isWinner: isWinner,
      stats: nextStats,
    );

    _matchMessage = isWinner
        ? '${player.name} wins with ${finishingHit.label}!'
        : '${player.name} scored $turnScore.';

    // Update profiles stats for throw
    _updateProfileStatsForPlayer(
      player.name,
      _currentTurn,
      turnScore,
      isWinner,
    );

    if (isWinner) {
      _archiveMatch();
    } else {
      _advanceTurn();
    }
    _syncLiveMatch();
    notifyListeners();
  }

  bool _isValidFinish(int remaining, DartHit hit) {
    if (remaining != 0) {
      return false;
    }

    return switch (_settings.outRule) {
      OutRule.singleOut => true,
      OutRule.doubleOut => hit.isDouble,
      OutRule.masterOut => hit.isDouble || hit.band == SegmentBand.triple,
    };
  }

  String? _checkoutFor(int remaining, int dartsLeft) {
    final hits = _checkoutHits();
    for (var length = 1; length <= dartsLeft; length++) {
      final result = _findCheckout(
        remaining: remaining,
        dartsLeft: length,
        hits: hits,
        current: const [],
      );
      if (result != null) {
        return result.map((hit) => hit.label).join(' + ');
      }
    }
    return null;
  }

  List<DartHit>? _findCheckout({
    required int remaining,
    required int dartsLeft,
    required List<DartHit> hits,
    required List<DartHit> current,
  }) {
    if (dartsLeft == 0) {
      if (remaining == 0 &&
          current.isNotEmpty &&
          _isValidFinish(0, current.last)) {
        return current;
      }
      return null;
    }

    for (final hit in hits) {
      if (hit.score > remaining) {
        continue;
      }
      final next = [...current, hit];
      final result = _findCheckout(
        remaining: remaining - hit.score,
        dartsLeft: dartsLeft - 1,
        hits: hits,
        current: next,
      );
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  List<DartHit> _checkoutHits() {
    final hits = <DartHit>[];

    for (var number = 20; number >= 1; number--) {
      hits.add(
        DartHit(
          label: 'T$number',
          score: number * 3,
          band: SegmentBand.triple,
          number: number,
        ),
      );
    }
    hits.add(const DartHit(label: 'BULL', score: 50, band: SegmentBand.bull));
    hits.add(
      const DartHit(label: '25', score: 25, band: SegmentBand.outerBull),
    );
    for (var number = 20; number >= 1; number--) {
      hits.add(
        DartHit(
          label: 'D$number',
          score: number * 2,
          band: SegmentBand.double,
          number: number,
        ),
      );
    }
    for (var number = 20; number >= 1; number--) {
      hits.add(
        DartHit(
          label: 'S$number',
          score: number,
          band: SegmentBand.single,
          number: number,
        ),
      );
    }
    if (_checkoutStrategy == CheckoutStrategy.adaptive &&
        currentPlayer.numberHitCounts.isNotEmpty) {
      final hitCounts = currentPlayer.numberHitCounts;
      hits.sort((a, b) {
        final countCompare = (hitCounts[b.number] ?? 0).compareTo(
          hitCounts[a.number] ?? 0,
        );
        if (countCompare != 0) {
          return countCompare;
        }
        final bandCompare = _checkoutBandRank(
          a.band,
        ).compareTo(_checkoutBandRank(b.band));
        if (bandCompare != 0) {
          return bandCompare;
        }
        return b.score.compareTo(a.score);
      });
    }
    return hits;
  }

  int _checkoutBandRank(SegmentBand band) {
    return switch (band) {
      SegmentBand.double => 0,
      SegmentBand.triple => 1,
      SegmentBand.bull => 2,
      SegmentBand.outerBull => 3,
      SegmentBand.single => 4,
      SegmentBand.miss => 5,
    };
  }

  void _advanceTurn() {
    _currentTurn.clear();
    if (!matchFinished) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    }
  }

  void _updateProfileStatsForPlayer(
    String name,
    List<DartHit> turn,
    int score,
    bool wonMatch,
  ) {
    final pIndex = _profiles.indexWhere((p) => p.name == name);
    if (pIndex == -1) return;

    final profile = _profiles[pIndex];
    profile.totalThrows += turn.length;
    profile.totalScored += score;

    final turnSum = turn.fold<int>(0, (sum, hit) => sum + hit.score);
    if (turnSum > profile.highestTurn) {
      profile.highestTurn = turnSum;
    }

    for (final hit in turn) {
      if (hit.band == SegmentBand.double || hit.band == SegmentBand.bull) {
        profile.doubleHits++;
      } else if (hit.band == SegmentBand.triple) {
        profile.tripleHits++;
      }
    }

    if (wonMatch) {
      profile.matchesWon++;
    }
  }

  void _archiveMatch() {
    // Update match count for all participants
    for (final player in _players) {
      final pIndex = _profiles.indexWhere((p) => p.name == player.name);
      if (pIndex != -1) {
        _profiles[pIndex].matchesPlayed++;
      }
    }

    final entry = MatchHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      settings: _settings,
      winnerName: currentPlayer.name,
      finalScores: List.from(_players),
    );
    _matchHistory.insert(0, entry);
  }

  // Control & Settings
  void updateSettings({GameMode? mode, int? startingScore, OutRule? outRule}) {
    _settings = GameSettings(
      mode: mode ?? _settings.mode,
      startingScore: startingScore ?? _settings.startingScore,
      outRule: outRule ?? _settings.outRule,
    );
    _resetMatch();
  }

  void startNewMatch() {
    _resetMatch();
  }

  void _resetMatch() {
    // If we have no active players yet, initialize from default profiles
    if (_players.isEmpty) {
      _players = _profiles
          .map(
            (p) => PlayerScore(
              name: p.name,
              avatarColorValue: p.avatarColorValue,
              remaining: _settings.mode == GameMode.x01
                  ? _settings.startingScore
                  : 0,
              totalScored: 0,
              turns: const [],
              isWinner: false,
            ),
          )
          .toList();
    } else {
      // Re-initialize score for existing players
      _players = _players
          .map(
            (p) => p.copyWith(
              remaining: _settings.mode == GameMode.x01
                  ? _settings.startingScore
                  : 0,
              totalScored: 0,
              turns: const [],
              isWinner: false,
              stats: _persistentStatsForNewMatch(p.stats),
            ),
          )
          .toList();
    }
    _currentTurn.clear();
    _sportEvents.clear();
    _currentPlayerIndex = 0;
    _matchMessage = null;
    _syncLiveMatch();
    notifyListeners();
  }

  Map<String, int> _persistentStatsForNewMatch(Map<String, int> stats) {
    final persistent = <String, int>{};
    for (final entry in stats.entries) {
      if (entry.value > 0) {
        persistent[entry.key] = entry.value;
      }
    }
    return persistent;
  }

  Map<String, int> _mergedStats(
    Map<String, int> current,
    Map<String, int> imported,
  ) {
    final merged = Map<String, int>.from(current);
    for (final entry in imported.entries) {
      merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
    }
    return merged;
  }

  @override
  void dispose() {
    _liveMatchSubscription?.cancel();
    super.dispose();
  }

  Map<String, Object?> _settingsToMap(GameSettings settings) {
    return {
      'mode': settings.mode.name,
      'startingScore': settings.startingScore,
      'outRule': settings.outRule.name,
    };
  }

  GameSettings _settingsFromMap(Map<String, dynamic> value) {
    return GameSettings(
      mode: GameMode.values.firstWhere(
        (mode) => mode.name == value['mode'],
        orElse: () => GameMode.x01,
      ),
      startingScore: _intFromValue(value['startingScore'], fallback: 501),
      outRule: OutRule.values.firstWhere(
        (rule) => rule.name == value['outRule'],
        orElse: () => OutRule.doubleOut,
      ),
    );
  }

  Map<String, Object?> _playerToMap(PlayerScore player) {
    return {
      'userId': player.userId,
      'name': player.name,
      'avatarColorValue': player.avatarColorValue,
      'photoUrl': _sharedPhotoUrl(player.photoUrl),
      'remaining': player.remaining,
      'totalScored': player.totalScored,
      'stats': player.stats,
      'isWinner': player.isWinner,
      'turns': player.turns
          .map((turn) => turn.map(_hitToMap).toList())
          .toList(),
    };
  }

  Map<String, Object?> _playerToParticipantMap(PlayerScore player) {
    return {
      'userId': player.userId,
      'displayName': player.name,
      'avatarColorValue': player.avatarColorValue,
      'photoUrl': _sharedPhotoUrl(player.photoUrl),
      'isRegistered': player.isRegisteredUser,
      'role': player.userId == _liveHostUserId ? 'owner' : 'participant',
    };
  }

  Map<String, Object?> _sportEventToMap(SportEvent event) {
    return {
      'id': event.id,
      'playerName': event.playerName,
      'label': event.label,
      'actionId': event.actionId,
      'scoreDelta': event.scoreDelta,
      'totalScore': event.totalScore,
      'statKey': event.statKey,
      'createdAt': event.createdAt.millisecondsSinceEpoch,
    };
  }

  Map<String, Object?> _matchHistoryToMap(MatchHistoryEntry entry) {
    return {
      'id': entry.id,
      'date': entry.date.millisecondsSinceEpoch,
      'settings': _settingsToMap(entry.settings),
      'winnerName': entry.winnerName,
      'finalScores': entry.finalScores.map(_playerToMap).toList(),
    };
  }

  SportEvent _sportEventFromMap(Map<String, dynamic> value) {
    final createdAt = _intFromValue(value['createdAt']);
    return SportEvent(
      id: value['id'] as String? ?? createdAt.toString(),
      playerName: value['playerName'] as String? ?? 'Player',
      label: value['label'] as String? ?? 'Event',
      actionId: value['actionId'] as String?,
      scoreDelta: _intFromValue(value['scoreDelta']),
      totalScore: _intFromValue(value['totalScore']),
      statKey: value['statKey'] as String?,
      createdAt: createdAt == 0
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }

  MatchHistoryEntry _matchHistoryFromMap(Map<String, dynamic> value) {
    final date = _intFromValue(value['date']);
    final settingsValue = value['settings'];
    return MatchHistoryEntry(
      id: value['id'] as String? ?? date.toString(),
      date: date == 0
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(date),
      settings: settingsValue is Map
          ? _settingsFromMap(Map<String, dynamic>.from(settingsValue))
          : _settings,
      winnerName: value['winnerName'] as String? ?? 'Player',
      finalScores: _asList(value['finalScores'])
          .whereType<Map>()
          .map((player) => _playerFromMap(Map<String, dynamic>.from(player)))
          .toList(),
    );
  }

  PlayerScore _playerFromProfile(PlayerProfile profile) {
    return PlayerScore(
      name: profile.name,
      avatarColorValue: profile.avatarColorValue,
      remaining: _settings.mode == GameMode.x01 && isDartsGame
          ? _settings.startingScore
          : 0,
      totalScored: 0,
      turns: const [],
      isWinner: false,
    );
  }

  PlayerScore _playerFromMap(Map<String, dynamic> value) {
    return PlayerScore(
      userId: value['userId'] as String?,
      name: value['name'] as String? ?? 'Player',
      avatarColorValue: _intFromValue(
        value['avatarColorValue'],
        fallback: 0xFF0F8B6B,
      ),
      photoUrl: value['photoUrl'] as String?,
      remaining: _intFromValue(value['remaining']),
      totalScored: _intFromValue(value['totalScored']),
      stats: _statsFromMap(value['stats']),
      turns: _asList(value['turns'])
          .map(
            (turn) => _asList(turn)
                .whereType<Map>()
                .map((hit) => _hitFromMap(Map<String, dynamic>.from(hit)))
                .toList(),
          )
          .toList(),
      isWinner: value['isWinner'] == true,
    );
  }

  Map<String, int> _statsFromMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return Map<String, dynamic>.from(
      value,
    ).map((key, value) => MapEntry(key, _intFromValue(value)));
  }

  void _mergeMembersIntoPlayers(Object? membersValue) {
    if (membersValue is! Map) {
      return;
    }

    final members = Map<String, dynamic>.from(membersValue);
    _groupMembers
      ..clear()
      ..addEntries(
        members.entries.where((entry) => entry.value is Map).map((entry) {
          return MapEntry(
            entry.key,
            Map<String, Object?>.from(entry.value as Map),
          );
        }),
      );
    for (final entry in members.entries) {
      final userId = entry.key;
      final value = entry.value;
      if (value is! Map || userId.isEmpty) {
        continue;
      }

      final member = Map<String, dynamic>.from(value);
      final displayName = member['displayName'] as String? ?? 'Player';
      final photoUrl = member['photoUrl'] as String?;
      final existingIndex = _players.indexWhere(
        (player) => player.userId == userId,
      );
      if (existingIndex != -1) {
        _players[existingIndex] = _players[existingIndex].copyWith(
          name: displayName,
          photoUrl: photoUrl,
        );
        continue;
      }

      final sameNameIndex = _players.indexWhere(
        (player) =>
            player.userId == null &&
            player.name.trim().toLowerCase() ==
                displayName.trim().toLowerCase(),
      );
      if (sameNameIndex != -1) {
        _players[sameNameIndex] = _players[sameNameIndex].copyWith(
          userId: userId,
          name: displayName,
          photoUrl: photoUrl,
        );
        continue;
      }

      _players.add(
        PlayerScore(
          userId: userId,
          name: displayName,
          avatarColorValue: _nextAvatarColor(),
          photoUrl: photoUrl,
          remaining: _settings.mode == GameMode.x01 && isDartsGame
              ? _settings.startingScore
              : 0,
          totalScored: 0,
          turns: const [],
          isWinner: false,
        ),
      );
    }
  }

  Map<String, Object?> _hitToMap(DartHit hit) {
    return {
      'label': hit.label,
      'score': hit.score,
      'band': hit.band.name,
      'number': hit.number,
      'dx': hit.dx,
      'dy': hit.dy,
    };
  }

  DartHit _hitFromMap(Map<String, dynamic> value) {
    return DartHit(
      label: value['label'] as String? ?? 'MISS',
      score: _intFromValue(value['score']),
      band: SegmentBand.values.firstWhere(
        (band) => band.name == value['band'],
        orElse: () => SegmentBand.miss,
      ),
      number: value['number'] == null ? null : _intFromValue(value['number']),
      dx: _doubleFromValue(value['dx']),
      dy: _doubleFromValue(value['dy']),
    );
  }

  List<dynamic> _asList(Object? value) {
    if (value is List) {
      return value;
    }
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return entries.map((entry) => entry.value).toList();
    }
    return const [];
  }

  int _intFromValue(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  double? _doubleFromValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int _nextAvatarColor() {
    const colors = [
      0xFF0F8B6B,
      0xFFC7352F,
      0xFFF6D77B,
      0xFF1A6EB4,
      0xFF8E44AD,
      0xFFE67E22,
      0xFF2F4858,
      0xFF0096C7,
    ];
    return colors[_players.length % colors.length];
  }

  Future<String> _generateAvailableGroupCode() async {
    for (var attempt = 0; attempt < 16; attempt++) {
      final code = _randomGroupCode();
      final sessionId = _sessionIdFromGroupCode(code);
      final existing = await _authRepository.fetchSession(sessionId);
      if (existing == null) {
        return code;
      }
    }
    return _randomGroupCode();
  }

  String _randomGroupCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random.secure();
    final codeLetters = List.generate(
      3,
      (_) => letters[random.nextInt(letters.length)],
    ).join();
    final codeNumbers = List.generate(3, (_) => random.nextInt(10)).join();
    return '$codeLetters$codeNumbers';
  }

  String _sessionIdFromGroupCode(String groupCode) {
    return '${gameId}_${groupCode.toUpperCase()}';
  }

  String _normalizeGroupName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }

  Map<String, Object?> _membersToMap() {
    final members = <String, Object?>{
      for (final entry in _groupMembers.entries) entry.key: entry.value,
    };
    final fallbackJoinedAt = _lastLocalSyncAt == 0
        ? DateTime.now().millisecondsSinceEpoch
        : _lastLocalSyncAt;
    if (!_currentUser.isGuest) {
      final existing = Map<String, Object?>.from(
        (members[_currentUser.id] as Map?) ?? const {},
      );
      members[_currentUser.id] = {
        'role': _currentUser.id == _liveHostUserId ? 'owner' : 'participant',
        'displayName': _currentUser.displayName,
        'photoUrl': _sharedPhotoUrl(_currentUser.photoUrl),
        'joinedAt': existing['joinedAt'] ?? fallbackJoinedAt,
      };
    }
    for (final player in _players) {
      final userId = player.userId;
      if (userId == null || userId.isEmpty) {
        continue;
      }
      final existing = Map<String, Object?>.from(
        (members[userId] as Map?) ?? const {},
      );
      members[userId] = {
        'role': userId == _liveHostUserId ? 'owner' : 'participant',
        'displayName': player.name,
        'photoUrl': _sharedPhotoUrl(player.photoUrl) ?? existing['photoUrl'],
        'joinedAt': existing['joinedAt'] ?? fallbackJoinedAt,
      };
    }
    return members;
  }

  String? _sharedPhotoUrl(String? value) {
    if (value == null || value.isEmpty || value.startsWith('data:image')) {
      return null;
    }
    return value;
  }
}
