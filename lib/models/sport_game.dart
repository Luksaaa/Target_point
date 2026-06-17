import 'package:flutter/material.dart';

enum SportGameStatus { ready, planned }

class SportAction {
  const SportAction({
    required this.id,
    required this.label,
    required this.icon,
    this.scoreDelta = 0,
    this.statKey,
    this.statDelta = 1,
    this.endsTurn = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final int scoreDelta;
  final String? statKey;
  final int statDelta;
  final bool endsTurn;
}

class SportGame {
  const SportGame({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.status,
    required this.modes,
    this.participants = const [],
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final SportGameStatus status;
  final List<String> modes;
  final List<String> participants;
  final bool isCustom;
}

const _goalActions = [
  SportAction(
    id: 'goal',
    label: 'Goal',
    icon: Icons.sports_soccer,
    scoreDelta: 1,
    statKey: 'goals',
  ),
  SportAction(
    id: 'yellow-card',
    label: 'Yellow',
    icon: Icons.style,
    statKey: 'yellowCards',
  ),
  SportAction(
    id: 'red-card',
    label: 'Red',
    icon: Icons.stop_circle,
    statKey: 'redCards',
  ),
  SportAction(id: 'foul', label: 'Foul', icon: Icons.flag, statKey: 'fouls'),
];

const _pointSetActions = [
  SportAction(
    id: 'point',
    label: 'Point',
    icon: Icons.add,
    scoreDelta: 1,
    statKey: 'points',
  ),
  SportAction(id: 'game', label: 'Game', icon: Icons.check, statKey: 'games'),
  SportAction(
    id: 'set',
    label: 'Set',
    icon: Icons.emoji_events,
    statKey: 'sets',
  ),
  SportAction(
    id: 'fault',
    label: 'Fault',
    icon: Icons.report,
    statKey: 'faults',
  ),
];

const _teamPointActions = [
  SportAction(
    id: 'point',
    label: 'Point',
    icon: Icons.add,
    scoreDelta: 1,
    statKey: 'points',
  ),
  SportAction(id: 'set', label: 'Set', icon: Icons.check, statKey: 'sets'),
  SportAction(id: 'foul', label: 'Foul', icon: Icons.flag, statKey: 'fouls'),
  SportAction(
    id: 'timeout',
    label: 'Timeout',
    icon: Icons.timer,
    statKey: 'timeouts',
  ),
];

const _basketballActions = [
  SportAction(
    id: 'one',
    label: '+1',
    icon: Icons.exposure_plus_1,
    scoreDelta: 1,
    statKey: 'freeThrows',
  ),
  SportAction(
    id: 'two',
    label: '+2',
    icon: Icons.add_circle,
    scoreDelta: 2,
    statKey: 'twoPointers',
  ),
  SportAction(
    id: 'three',
    label: '+3',
    icon: Icons.adjust,
    scoreDelta: 3,
    statKey: 'threePointers',
  ),
  SportAction(id: 'foul', label: 'Foul', icon: Icons.flag, statKey: 'fouls'),
];

const _cueActions = [
  SportAction(
    id: 'pot',
    label: 'Pot',
    icon: Icons.add,
    scoreDelta: 1,
    statKey: 'pots',
  ),
  SportAction(
    id: 'frame',
    label: 'Frame',
    icon: Icons.emoji_events,
    statKey: 'frames',
  ),
  SportAction(id: 'foul', label: 'Foul', icon: Icons.flag, statKey: 'fouls'),
  SportAction(
    id: 'visit',
    label: 'Visit',
    icon: Icons.swap_horiz,
    statKey: 'visits',
    endsTurn: true,
  ),
];

const _boardGameActions = [
  SportAction(
    id: 'point',
    label: 'Point',
    icon: Icons.add,
    scoreDelta: 1,
    statKey: 'points',
  ),
  SportAction(
    id: 'round',
    label: 'Round',
    icon: Icons.refresh,
    statKey: 'rounds',
  ),
  SportAction(
    id: 'bonus',
    label: 'Bonus',
    icon: Icons.star,
    statKey: 'bonuses',
  ),
  SportAction(
    id: 'penalty',
    label: 'Penalty',
    icon: Icons.remove,
    scoreDelta: -1,
    statKey: 'penalties',
  ),
];

const _chessActions = [
  SportAction(
    id: 'win',
    label: 'Win',
    icon: Icons.emoji_events,
    scoreDelta: 1,
    statKey: 'wins',
  ),
  SportAction(id: 'draw', label: 'Draw', icon: Icons.balance, statKey: 'draws'),
  SportAction(id: 'loss', label: 'Loss', icon: Icons.close, statKey: 'losses'),
  SportAction(
    id: 'timeout',
    label: 'Timeout',
    icon: Icons.timer_off,
    statKey: 'timeouts',
  ),
];

const _genericCompetitionActions = [
  SportAction(
    id: 'point',
    label: 'Point',
    icon: Icons.add,
    scoreDelta: 1,
    statKey: 'points',
  ),
  SportAction(
    id: 'win',
    label: 'Win',
    icon: Icons.emoji_events,
    statKey: 'wins',
  ),
  SportAction(
    id: 'penalty',
    label: 'Penalty',
    icon: Icons.remove,
    scoreDelta: -1,
    statKey: 'penalties',
  ),
  SportAction(id: 'next', label: 'Next', icon: Icons.skip_next, endsTurn: true),
];

List<SportAction> sportActionsFor(String gameId) {
  switch (gameId) {
    case 'football':
    case 'handball':
    case 'hockey':
    case 'rugby':
    case 'foosball':
    case 'beer-pong':
      return _goalActions;
    case 'tennis':
    case 'table-tennis':
    case 'badminton':
    case 'squash':
    case 'padel':
    case 'pickleball':
      return _pointSetActions;
    case 'basketball':
      return _basketballActions;
    case 'volleyball':
      return _teamPointActions;
    case 'billiards':
    case 'snooker':
      return _cueActions;
    case 'chess':
      return _chessActions;
    case 'catan':
    case 'monopoly':
    case 'risk':
    case 'uno':
    case 'poker':
    case 'blackjack':
    case 'scrabble':
    case 'yahtzee':
    case 'dominoes':
    case 'dixit':
    case 'ticket-to-ride':
    case 'carcassonne':
    case 'clue':
    case 'trivia':
      return _boardGameActions;
    default:
      return _genericCompetitionActions;
  }
}

const sportGames = [
  SportGame(
    id: 'darts',
    name: 'Darts',
    subtitle: 'X01, Count up, players, groups and match history',
    icon: Icons.adjust,
    color: Color(0xFF0F8B6B),
    status: SportGameStatus.ready,
    modes: ['301', '501', '701', 'Count up'],
  ),
  SportGame(
    id: 'table-tennis',
    name: 'Table Tennis',
    subtitle: 'Sets, points, serve tracking and match timer',
    icon: Icons.sports_tennis,
    color: Color(0xFF276EF1),
    status: SportGameStatus.ready,
    modes: ['Best of 3', 'Best of 5', '11 points'],
  ),
  SportGame(
    id: 'tennis',
    name: 'Tennis',
    subtitle: 'Games, sets, tie-break and serve order',
    icon: Icons.sports,
    color: Color(0xFFE89A1A),
    status: SportGameStatus.ready,
    modes: ['Singles', 'Doubles', 'Tie-break'],
  ),
  SportGame(
    id: 'football',
    name: 'Football',
    subtitle: 'Score, timer, teams, goals and match events',
    icon: Icons.sports_soccer,
    color: Color(0xFFC7352F),
    status: SportGameStatus.ready,
    modes: ['5v5', '7v7', '11v11'],
  ),
  SportGame(
    id: 'billiards',
    name: 'Billiards',
    subtitle: 'Frames, balls, fouls and player turns',
    icon: Icons.album,
    color: Color(0xFF8E44AD),
    status: SportGameStatus.ready,
    modes: ['8-ball', '9-ball', 'Straight pool'],
  ),
  SportGame(
    id: 'snooker',
    name: 'Snooker',
    subtitle: 'Frames, breaks, fouls and table visits',
    icon: Icons.trip_origin,
    color: Color(0xFF6C8F2F),
    status: SportGameStatus.ready,
    modes: ['Frames', 'Best of 3', 'Best of 5'],
  ),
  SportGame(
    id: 'bowling',
    name: 'Bowling',
    subtitle: 'Frames, strikes, spares and final score',
    icon: Icons.sports_score,
    color: Color(0xFFB25518),
    status: SportGameStatus.ready,
    modes: ['10 frames', 'Teams', 'Practice'],
  ),
  SportGame(
    id: 'badminton',
    name: 'Badminton',
    subtitle: 'Sets, rallies, serve side and match point',
    icon: Icons.sports_tennis,
    color: Color(0xFF00A6A6),
    status: SportGameStatus.ready,
    modes: ['Singles', 'Doubles', '21 points'],
  ),
  SportGame(
    id: 'squash',
    name: 'Squash',
    subtitle: 'Games, rallies, serve tracking and tie-breaks',
    icon: Icons.motion_photos_on,
    color: Color(0xFFD94862),
    status: SportGameStatus.ready,
    modes: ['Best of 5', '11 points', 'PAR'],
  ),
  SportGame(
    id: 'basketball',
    name: 'Basketball',
    subtitle: 'Quarters, team score, fouls and timeout tracking',
    icon: Icons.sports_basketball,
    color: Color(0xFFE67E22),
    status: SportGameStatus.ready,
    modes: ['3v3', '5v5', 'Pickup'],
  ),
  SportGame(
    id: 'volleyball',
    name: 'Volleyball',
    subtitle: 'Sets, points, serve possession and rotation',
    icon: Icons.sports_volleyball,
    color: Color(0xFF1A6EB4),
    status: SportGameStatus.ready,
    modes: ['Indoor', 'Beach', 'Best of 5'],
  ),
  SportGame(
    id: 'handball',
    name: 'Handball',
    subtitle: 'Timer, goals, penalties and team events',
    icon: Icons.sports_handball,
    color: Color(0xFF4C6FFF),
    status: SportGameStatus.ready,
    modes: ['Teams', 'Timer', 'Penalties'],
  ),
  SportGame(
    id: 'golf',
    name: 'Golf',
    subtitle: 'Holes, strokes, par and player leaderboard',
    icon: Icons.sports_golf,
    color: Color(0xFF2E7D32),
    status: SportGameStatus.ready,
    modes: ['9 holes', '18 holes', 'Stroke play'],
  ),
  SportGame(
    id: 'hockey',
    name: 'Hockey',
    subtitle: 'Periods, score, penalties and match clock',
    icon: Icons.sports_hockey,
    color: Color(0xFF607D8B),
    status: SportGameStatus.ready,
    modes: ['Ice', 'Field', 'Penalties'],
  ),
  SportGame(
    id: 'baseball',
    name: 'Baseball',
    subtitle: 'Innings, runs, outs and team score',
    icon: Icons.sports_baseball,
    color: Color(0xFF795548),
    status: SportGameStatus.ready,
    modes: ['9 innings', 'Softball', 'Casual'],
  ),
  SportGame(
    id: 'cricket',
    name: 'Cricket',
    subtitle: 'Runs, wickets, overs and innings',
    icon: Icons.sports_cricket,
    color: Color(0xFF00897B),
    status: SportGameStatus.ready,
    modes: ['T20', 'ODI', 'Test'],
  ),
  SportGame(
    id: 'rugby',
    name: 'Rugby',
    subtitle: 'Match timer, tries, conversions and penalties',
    icon: Icons.sports_rugby,
    color: Color(0xFF5D4037),
    status: SportGameStatus.ready,
    modes: ['Union', 'League', 'Sevens'],
  ),
  SportGame(
    id: 'foosball',
    name: 'Foosball',
    subtitle: 'Goals, sets and quick table matches',
    icon: Icons.table_bar,
    color: Color(0xFF546E7A),
    status: SportGameStatus.ready,
    modes: ['Singles', 'Doubles', 'First to 10'],
  ),
  SportGame(
    id: 'chess',
    name: 'Chess',
    subtitle: 'Clock, result, color and match record',
    icon: Icons.grid_on,
    color: Color(0xFF263238),
    status: SportGameStatus.ready,
    modes: ['Rapid', 'Blitz', 'Classical'],
  ),
  SportGame(
    id: 'catan',
    name: 'Catan',
    subtitle: 'Victory points, longest road, army and trade notes',
    icon: Icons.hexagon,
    color: Color(0xFFB85C38),
    status: SportGameStatus.ready,
    modes: ['10 points', 'Expansion', 'Teams'],
  ),
  SportGame(
    id: 'monopoly',
    name: 'Monopoly',
    subtitle: 'Cash, properties, bankrupt players and winner',
    icon: Icons.account_balance,
    color: Color(0xFF1565C0),
    status: SportGameStatus.ready,
    modes: ['Classic', 'Speed die', 'House rules'],
  ),
  SportGame(
    id: 'risk',
    name: 'Risk',
    subtitle: 'Territories, missions, eliminations and final winner',
    icon: Icons.public,
    color: Color(0xFFC62828),
    status: SportGameStatus.ready,
    modes: ['World', 'Missions', 'Teams'],
  ),
  SportGame(
    id: 'uno',
    name: 'Uno',
    subtitle: 'Rounds, cards, penalties and points',
    icon: Icons.style,
    color: Color(0xFFFFB300),
    status: SportGameStatus.ready,
    modes: ['500 points', 'Rounds', 'House rules'],
  ),
  SportGame(
    id: 'poker',
    name: 'Poker',
    subtitle: 'Buy-ins, chips, placements and session winner',
    icon: Icons.diamond,
    color: Color(0xFF00838F),
    status: SportGameStatus.ready,
    modes: ['Texas Holdem', 'Tournament', 'Cash'],
  ),
  SportGame(
    id: 'blackjack',
    name: 'Blackjack',
    subtitle: 'Rounds, bankroll, wins and losses',
    icon: Icons.casino,
    color: Color(0xFF2E7D32),
    status: SportGameStatus.ready,
    modes: ['Bankroll', 'Dealer', 'Rounds'],
  ),
  SportGame(
    id: 'scrabble',
    name: 'Scrabble',
    subtitle: 'Words, turn scores, bonuses and final score',
    icon: Icons.text_fields,
    color: Color(0xFF6A1B9A),
    status: SportGameStatus.ready,
    modes: ['Classic', 'Timed', 'Teams'],
  ),
  SportGame(
    id: 'yahtzee',
    name: 'Yahtzee',
    subtitle: 'Categories, dice rolls, bonuses and total score',
    icon: Icons.casino_outlined,
    color: Color(0xFF5D4037),
    status: SportGameStatus.ready,
    modes: ['Classic', 'Bonus', 'Rounds'],
  ),
  SportGame(
    id: 'dominoes',
    name: 'Dominoes',
    subtitle: 'Rounds, tiles, blocked games and points',
    icon: Icons.view_module,
    color: Color(0xFF455A64),
    status: SportGameStatus.ready,
    modes: ['Block', 'Draw', 'Teams'],
  ),
  SportGame(
    id: 'dixit',
    name: 'Dixit',
    subtitle: 'Storyteller rounds, votes and scoring track',
    icon: Icons.auto_stories,
    color: Color(0xFFAB47BC),
    status: SportGameStatus.ready,
    modes: ['Classic', 'Teams', 'House rules'],
  ),
  SportGame(
    id: 'ticket-to-ride',
    name: 'Ticket to Ride',
    subtitle: 'Routes, destination tickets and final bonuses',
    icon: Icons.train,
    color: Color(0xFFEF6C00),
    status: SportGameStatus.ready,
    modes: ['Europe', 'USA', 'Expansion'],
  ),
  SportGame(
    id: 'carcassonne',
    name: 'Carcassonne',
    subtitle: 'Meeples, cities, roads, farms and final scoring',
    icon: Icons.castle,
    color: Color(0xFF795548),
    status: SportGameStatus.ready,
    modes: ['Base', 'Expansion', 'Fields'],
  ),
  SportGame(
    id: 'clue',
    name: 'Clue',
    subtitle: 'Suspects, rooms, weapons and accusations',
    icon: Icons.search,
    color: Color(0xFF283593),
    status: SportGameStatus.ready,
    modes: ['Classic', 'Teams', 'Notes'],
  ),
  SportGame(
    id: 'trivia',
    name: 'Trivia',
    subtitle: 'Questions, categories, teams and final score',
    icon: Icons.quiz,
    color: Color(0xFF00796B),
    status: SportGameStatus.ready,
    modes: ['Teams', 'Rounds', 'Sudden death'],
  ),
  SportGame(
    id: 'beer-pong',
    name: 'Beer Pong',
    subtitle: 'Cups, teams, turns and house rules',
    icon: Icons.local_bar,
    color: Color(0xFFE65100),
    status: SportGameStatus.ready,
    modes: ['1v1', '2v2', 'House rules'],
  ),
  SportGame(
    id: 'padel',
    name: 'Padel',
    subtitle: 'Games, sets, tie-breaks and doubles scoring',
    icon: Icons.sports_tennis,
    color: Color(0xFFAD1457),
    status: SportGameStatus.ready,
    modes: ['Doubles', 'Best of 3', 'Tie-break'],
  ),
  SportGame(
    id: 'pickleball',
    name: 'Pickleball',
    subtitle: 'Serve order, side out, points and games',
    icon: Icons.sports_tennis,
    color: Color(0xFF7CB342),
    status: SportGameStatus.ready,
    modes: ['Singles', 'Doubles', '11 points'],
  ),
];
