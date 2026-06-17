import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target_point/main.dart';
import 'package:target_point/l10n/app_localizations.dart';
import 'package:target_point/models/dart_hit.dart';
import 'package:target_point/models/game_state_controller.dart';
import 'package:target_point/models/player_score.dart';
import 'package:target_point/models/sport_game.dart';
import 'package:target_point/widgets/dartboard.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1200, 800),
    Brightness? brightness,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    if (brightness != null) {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          brightness;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
    }

    await tester.pumpWidget(const TargetPointApp());
    await tester.pumpAndSettle();
  }

  Future<void> addManualPlayer(WidgetTester tester, String name) async {
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add Player'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, name);
    await tester.tap(find.widgetWithText(FilledButton, 'Add Player').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on darts with the main match tabs', (tester) async {
    await pumpApp(tester);

    expect(find.byType(Dartboard), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Scores'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('opens the activity hub from the darts screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Activities'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a game'), findsOneWidget);
    expect(find.text('Darts'), findsOneWidget);
    expect(find.text('Table Tennis'), findsOneWidget);
    expect(find.text('Tennis'), findsOneWidget);
    expect(find.text('Football'), findsOneWidget);
    expect(find.text('Billiards'), findsOneWidget);
  });

  testWidgets('creates a custom competitive activity', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Activities'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create activity'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Beer race');
    await tester.enterText(
      find.byType(TextField).at(1),
      'First person to finish wins',
    );
    await tester.enterText(find.byType(TextField).at(2), 'Player 1, Player 2');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Beer race'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Player 1'), findsOneWidget);
  });

  testWidgets('records a dartboard hit in the current turn', (tester) async {
    await pumpApp(tester);
    await addManualPlayer(tester, 'Player 1');

    expect(find.text('Target Point'), findsOneWidget);
    expect(find.text('Player 1'), findsWidgets);
    expect(find.text('501'), findsWidgets);

    final dartboard = find.byType(Dartboard);
    expect(dartboard, findsOneWidget);

    await tester.tapAt(tester.getCenter(dartboard));
    await tester.pump();

    expect(find.text('BULL'), findsOneWidget);
    expect(find.text('Turn total: 50'), findsOneWidget);
  });

  testWidgets('undo removes the last pending hit', (tester) async {
    await pumpApp(tester);
    await addManualPlayer(tester, 'Player 1');

    await tester.tapAt(tester.getCenter(find.byType(Dartboard)));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Undo'));
    await tester.pump();

    expect(find.text('BULL'), findsNothing);
    expect(find.text('Turn total: 0'), findsOneWidget);
  });

  testWidgets('renders on a narrow mobile viewport', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await addManualPlayer(tester, 'Player 1');

    expect(find.text('Player 1'), findsWidgets);
    expect(find.byType(Dartboard), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(Dartboard)));
    await tester.pump();

    expect(find.text('BULL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with the system dark theme', (tester) async {
    await pumpApp(
      tester,
      size: const Size(390, 844),
      brightness: Brightness.dark,
    );

    expect(find.text('Target Point'), findsOneWidget);
    expect(find.byType(Dartboard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('keeps the app user profile separate from the active match player', () {
    final controller = GameStateController(gameId: 'darts', gameName: 'Darts');

    expect(controller.currentUser.displayName, 'Guest');
    expect(controller.currentUser.initials, 'G');
    expect(controller.currentPlayer.name, 'No Players');

    controller.updateUserProfile('Guest Profile', 0xFF1A6EB4);

    expect(controller.currentUser.displayName, 'Guest Profile');
    expect(controller.currentUser.initials, 'G');
    expect(controller.currentPlayer.name, 'No Players');
  });

  test('includes board games and party competitions as presets', () {
    final gameNames = sportGames.map((game) => game.name).toSet();

    expect(gameNames.contains('Chess'), isTrue);
    expect(gameNames.contains('Catan'), isTrue);
    expect(gameNames.contains('Monopoly'), isTrue);
    expect(gameNames.contains('Beer Pong'), isTrue);
  });

  test('provides sport specific actions for every game preset', () {
    for (final game in sportGames) {
      expect(game.status, SportGameStatus.ready, reason: game.id);
      expect(sportActionsFor(game.id), isNotEmpty, reason: game.id);
    }

    final footballActions = sportActionsFor(
      'football',
    ).map((action) => action.id).toSet();
    expect(footballActions.contains('goal'), isTrue);
    expect(footballActions.contains('yellow-card'), isTrue);
    expect(footballActions.contains('red-card'), isTrue);
    expect(footballActions.contains('foul'), isTrue);
  });

  test('records sport events with player, action and total score', () {
    final controller = GameStateController(
      gameId: 'football',
      gameName: 'Football',
    );

    controller.addPlayerProfile('Team A', 0xFF276EF1);
    controller.applySportAction(label: 'Goal', scoreDelta: 1, statKey: 'goals');

    expect(controller.currentPlayer.totalScored, 1);
    expect(controller.currentPlayer.stats['goals'], 1);
    expect(controller.sportEvents, hasLength(1));
    expect(controller.sportEvents.first.playerName, 'Team A');
    expect(controller.sportEvents.first.label, 'Goal');
    expect(controller.sportEvents.first.totalScore, 1);
  });

  test('provides supported app translations', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      ['en', 'hr', 'de', 'es', 'fr', 'it', 'ja', 'zh'],
    );

    expect(
      const AppLocalizations(Locale('hr')).t('hub.chooseGame'),
      'Odaberi igru',
    );
    expect(
      const AppLocalizations(Locale('de')).t('common.language'),
      'Sprache',
    );
    expect(const AppLocalizations(Locale('ja')).t('game.darts.name'), 'ダーツ');
  });

  test('tracks the most frequently hit dartboard number', () {
    const player = PlayerScore(
      name: 'Player 1',
      avatarColorValue: 0xFF0F8B6B,
      remaining: 301,
      totalScored: 140,
      isWinner: false,
      turns: [
        [
          DartHit(
            label: 'T20',
            score: 60,
            band: SegmentBand.triple,
            number: 20,
          ),
          DartHit(
            label: 'S20',
            score: 20,
            band: SegmentBand.single,
            number: 20,
          ),
          DartHit(
            label: 'T19',
            score: 57,
            band: SegmentBand.triple,
            number: 19,
          ),
        ],
        [
          DartHit(
            label: 'S20',
            score: 20,
            band: SegmentBand.single,
            number: 20,
          ),
        ],
      ],
    );

    expect(player.bestNumber, 20);
    expect(player.bestNumberHits, 3);
  });
}
