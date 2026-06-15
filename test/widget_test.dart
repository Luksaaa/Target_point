import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target_point/main.dart';
import 'package:target_point/l10n/app_localizations.dart';
import 'package:target_point/models/game_state_controller.dart';
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
    await tester.enterText(find.byType(TextField).at(2), 'Marko, Luka, Borna');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Beer race'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Marko'), findsOneWidget);
  });

  testWidgets('records a dartboard hit in the current turn', (tester) async {
    await pumpApp(tester);

    expect(find.text('Target Point'), findsOneWidget);
    expect(find.text('Marko'), findsWidgets);
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

    await tester.tapAt(tester.getCenter(find.byType(Dartboard)));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Undo'));
    await tester.pump();

    expect(find.text('BULL'), findsNothing);
    expect(find.text('Turn total: 0'), findsOneWidget);
  });

  testWidgets('renders on a narrow mobile viewport', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));

    expect(find.text('Marko'), findsWidgets);
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
    final controller = GameStateController();

    expect(controller.currentUser.displayName, 'Guest');
    expect(controller.currentUser.initials, 'G');
    expect(controller.currentPlayer.name, 'Marko');

    controller.updateUserProfile('Luka Guest', 0xFF1A6EB4);

    expect(controller.currentUser.displayName, 'Luka Guest');
    expect(controller.currentUser.initials, 'L');
    expect(controller.currentPlayer.name, 'Marko');
  });

  test('includes board games and party competitions as presets', () {
    final gameNames = sportGames.map((game) => game.name).toSet();

    expect(gameNames.contains('Chess'), isTrue);
    expect(gameNames.contains('Catan'), isTrue);
    expect(gameNames.contains('Monopoly'), isTrue);
    expect(gameNames.contains('Beer Pong'), isTrue);
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

  test('can create and select a player group preset', () {
    final controller = GameStateController();

    controller.createPlayerGroup('Duo Night', ['Luka', 'Borna']);

    expect(controller.selectedPlayerGroup?.name, 'Duo Night');
    expect(controller.players.map((player) => player.name), ['Luka', 'Borna']);
    expect(controller.playerGroups.length, 2);
  });
}
