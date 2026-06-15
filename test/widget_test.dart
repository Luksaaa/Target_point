import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target_point/main.dart';

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
    await tester.tap(find.widgetWithText(FilledButton, 'Undo'));
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
}
