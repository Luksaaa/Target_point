import 'dart:async';
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

  bool _isLiveHost = false;
  bool get isLiveHost => _isLiveHost;

  String? _liveHostUserId;

  String? _liveMatchMessage;
  String? get liveMatchMessage => _liveMatchMessage;

  bool get isLiveMatchActive => _liveMatchId != null;
  bool get isDartsGame => gameId == 'darts';

  void changeTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  // Player Profiles registry (for lifetime/session stats)
  final List<PlayerProfile> _profiles = [];
  List<PlayerProfile> get profiles => List.unmodifiable(_profiles);

  final List<FollowedUser> _following = [];
  List<FollowedUser> get following => List.unmodifiable(_following);

  // Active game settings
  GameSettings _settings = const GameSettings(
    mode: GameMode.x01,
    startingScore: 501,
    outRule: OutRule.doubleOut,
  );
  GameSettings get settings => _settings;

  // Active match state
  List<PlayerScore> _players = [];
  List<PlayerScore> get players => _players;

  final List<DartHit> _currentTurn = [];
  List<DartHit> get currentTurn => _currentTurn;

  int _currentPlayerIndex = 0;
  int get currentPlayerIndex => _currentPlayerIndex;

  String? _matchMessage;
  String? get matchMessage => _matchMessage;

  PlayerScore get currentPlayer => _players.isEmpty
      ? const PlayerScore(
          name: 'No Players',
          avatarColorValue: 0xFF9E9E9E,
          remaining: 0,
          totalScored: 0,
          turns: [],
          isWinner: false,
        )
      : _players[_currentPlayerIndex];
  bool get matchFinished => _players.isEmpty || _players.any((p) => p.isWinner);

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

    final result = await _authRepository.signInWithGoogle();
    if (result.isSuccess) {
      _currentUser = result.session!;
      _accountMessage = 'Signed in as ${_currentUser.displayName}.';
      _ensureCurrentUserParticipant();
      await _activateRealtimeMatchForCurrentUser();
    } else {
      _accountMessage = result.errorMessage;
    }

    _isSigningIn = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    final signedOutUserId = _currentUser.id;
    await leaveLiveMatch();
    await _authRepository.signOut();
    _players.removeWhere((player) => player.userId == signedOutUserId);
    _profiles.removeWhere(
      (profile) => profile.name == _currentUser.displayName,
    );
    _currentTurn.clear();
    _currentPlayerIndex = _players.isEmpty
        ? 0
        : _currentPlayerIndex % _players.length;
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

  void updateUserProfile(String displayName, int avatarColorValue) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _currentUser = _currentUser.copyWith(
      displayName: trimmed,
      avatarColorValue: avatarColorValue,
    );
    _accountMessage = _currentUser.isGuest
        ? 'Guest profile updated locally.'
        : 'Profile updated for this session.';
    _ensureCurrentUserParticipant();
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
    final player = PlayerScore(
      userId: _currentUser.id,
      name: _currentUser.displayName,
      avatarColorValue: _currentUser.avatarColorValue,
      remaining: _settings.mode == GameMode.x01 && isDartsGame
          ? _settings.startingScore
          : 0,
      totalScored: 0,
      turns: const [],
      isWinner: false,
    );

    if (existingPlayerIndex == -1) {
      _players.add(player);
      if (_currentPlayerIndex >= _players.length) {
        _currentPlayerIndex = 0;
      }
    } else {
      _players[existingPlayerIndex] = _players[existingPlayerIndex].copyWith(
        userId: _currentUser.id,
        name: _currentUser.displayName,
        avatarColorValue: _currentUser.avatarColorValue,
      );
    }
  }

  Future<void> _activateRealtimeMatchForCurrentUser() async {
    if (!_cloudFeaturesAvailable || _currentUser.isGuest) {
      return;
    }

    final matchId = '$gameId-active';
    _liveMatchId = matchId;
    _isLiveHost = true;
    _liveHostUserId = _currentUser.id;
    _liveMatchMessage = 'Realtime sync is active.';

    final payload = await _authRepository.fetchGameSession(gameId);
    _subscribeToLiveMatch(gameId);
    if (payload == null) {
      await _syncLiveMatch();
      return;
    }
    _applyLivePayload(payload);
    _ensureCurrentUserParticipant();
    await _syncLiveMatch();
  }

  Future<void> leaveLiveMatch() async {
    await _liveMatchSubscription?.cancel();
    _liveMatchSubscription = null;
    _liveMatchId = null;
    _isLiveHost = false;
    _liveHostUserId = null;
    _liveMatchMessage = 'Live match left.';
    notifyListeners();
  }

  void _subscribeToLiveMatch(String matchId) {
    _liveMatchSubscription?.cancel();
    _liveMatchSubscription = _authRepository.watchGameSession(matchId).listen((
      payload,
    ) {
      if (payload == null) {
        return;
      }
      _applyLivePayload(payload);
    });
  }

  Future<void> _syncLiveMatch() async {
    final matchId = _liveMatchId;
    if (matchId == null || _isApplyingRemoteState || _currentUser.isGuest) {
      return;
    }

    try {
      await _authRepository.saveGameSession(gameId, _livePayload());
    } catch (error) {
      _liveMatchMessage = 'Could not sync live match: $error';
      notifyListeners();
    }
  }

  Map<String, Object?> _livePayload() {
    return {
      'id': _liveMatchId,
      'gameId': gameId,
      'gameName': gameName,
      'hostUserId': _liveHostUserId ?? _currentUser.id,
      'updatedByUserId': _currentUser.id,
      'settings': _settingsToMap(_settings),
      'players': _players.map(_playerToMap).toList(),
      'currentTurn': _currentTurn.map(_hitToMap).toList(),
      'currentPlayerIndex': _currentPlayerIndex,
      'matchMessage': _matchMessage,
    };
  }

  void _applyLivePayload(Map<String, dynamic> payload) {
    _isApplyingRemoteState = true;
    try {
      final settingsValue = payload['settings'];
      final playersValue = payload['players'];
      final turnValue = payload['currentTurn'];
      _liveHostUserId = payload['hostUserId'] as String? ?? _liveHostUserId;
      _isLiveHost = _liveHostUserId == _currentUser.id;

      if (settingsValue is Map) {
        _settings = _settingsFromMap(Map<String, dynamic>.from(settingsValue));
      }
      _players = _asList(playersValue)
          .whereType<Map>()
          .map((value) => _playerFromMap(Map<String, dynamic>.from(value)))
          .toList();
      if (_players.isEmpty) {
        _players = _profiles
            .map(
              (profile) => PlayerScore(
                name: profile.name,
                avatarColorValue: profile.avatarColorValue,
                remaining: _settings.mode == GameMode.x01
                    ? _settings.startingScore
                    : 0,
                totalScored: 0,
                turns: const [],
                isWinner: false,
              ),
            )
            .toList();
      }
      _currentTurn
        ..clear()
        ..addAll(
          _asList(turnValue).whereType<Map>().map(
            (value) => _hitFromMap(Map<String, dynamic>.from(value)),
          ),
        );
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
    if (_currentPlayerIndex >= _players.length) {
      _currentPlayerIndex = 0;
    }
    _currentTurn.clear();
    _matchMessage = 'Removed ${removedPlayer.name} from current match.';
    _syncLiveMatch();
    notifyListeners();
  }

  void reorderPlayers(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final player = _players.removeAt(oldIndex);
    _players.insert(newIndex, player);

    // Keep active player selection pointing to the correct person
    if (_currentPlayerIndex == oldIndex) {
      _currentPlayerIndex = newIndex;
    } else if (oldIndex < _currentPlayerIndex &&
        newIndex >= _currentPlayerIndex) {
      _currentPlayerIndex--;
    } else if (oldIndex > _currentPlayerIndex &&
        newIndex <= _currentPlayerIndex) {
      _currentPlayerIndex++;
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
    if (matchFinished || _currentTurn.length == 3) {
      return;
    }

    _currentTurn.add(hit);
    _matchMessage = null;
    _syncLiveMatch();
    notifyListeners();
  }

  void undoLastHit() {
    if (_currentTurn.isEmpty || matchFinished) {
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

  void adjustCurrentPlayerScore(int delta) {
    if (_players.isEmpty || isDartsGame) {
      return;
    }

    final player = currentPlayer;
    final nextScore = (player.totalScored + delta).clamp(0, 999999);
    _players[_currentPlayerIndex] = player.copyWith(
      remaining: nextScore,
      totalScored: nextScore,
    );
    _matchMessage = '${player.name}: $nextScore';
    _syncLiveMatch();
    notifyListeners();
  }

  void advanceGenericTurn() {
    if (_players.isEmpty || isDartsGame) {
      return;
    }

    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    _matchMessage = '${currentPlayer.name} is next.';
    _syncLiveMatch();
    notifyListeners();
  }

  void commitTurn() {
    if (_currentTurn.isEmpty) {
      return;
    }

    final player = currentPlayer;
    final turnScore = _currentTurn.fold<int>(
      0,
      (total, hit) => total + hit.score,
    );
    final nextTurns = [...player.turns, List<DartHit>.from(_currentTurn)];

    if (_settings.mode == GameMode.countUp) {
      _players[_currentPlayerIndex] = player.copyWith(
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
      _players[_currentPlayerIndex] = player.copyWith(turns: nextTurns);
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
    _players[_currentPlayerIndex] = player.copyWith(
      remaining: nextRemaining,
      totalScored: player.totalScored + turnScore,
      turns: nextTurns,
      isWinner: isWinner,
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
    }
    _currentTurn.clear();
    _currentPlayerIndex = 0;
    _matchMessage = null;
    _syncLiveMatch();
    notifyListeners();
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
      'remaining': player.remaining,
      'totalScored': player.totalScored,
      'isWinner': player.isWinner,
      'turns': player.turns
          .map((turn) => turn.map(_hitToMap).toList())
          .toList(),
    };
  }

  PlayerScore _playerFromMap(Map<String, dynamic> value) {
    return PlayerScore(
      userId: value['userId'] as String?,
      name: value['name'] as String? ?? 'Player',
      avatarColorValue: _intFromValue(
        value['avatarColorValue'],
        fallback: 0xFF0F8B6B,
      ),
      remaining: _intFromValue(value['remaining']),
      totalScored: _intFromValue(value['totalScored']),
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
}
