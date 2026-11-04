import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/app.dart';
import 'package:riffster/theme/neck_theme.dart';

void main() {
  testWidgets('practice screen shows the demo song', (tester) async {
    await tester.pumpWidget(const RiffsterApp());

    expect(find.text('Riffster'), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('the slider jumps to a later part of the song', (tester) async {
    await tester.pumpWidget(const RiffsterApp());

    expect(find.text('0:00 / 0:04'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pump();

    expect(find.text('0:00 / 0:04'), findsNothing);
    expect(find.textContaining('/ 0:04'), findsOneWidget);
  });

  testWidgets(
    'the chord course steps through grips and comes back to the song',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const RiffsterApp());
      await tester.tap(find.text('Chords'));
      await tester.pump();

      expect(find.text('Em'), findsOneWidget);
      expect(find.text('1 / 13'), findsOneWidget);
      expect(find.text('Warm-up'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('E'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(find.text('Em'), findsOneWidget);

      await tester.tap(find.text('Song'));
      await tester.pump();
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Chords'), findsOneWidget);
    },
  );

  testWidgets('maple turns the staff into a light neck', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RiffsterApp());
    await tester.tap(find.text('Maple'));
    await tester.pump();

    final decoration =
        tester.widget<DecoratedBox>(find.byKey(const Key('staff'))).decoration
            as BoxDecoration;
    expect(decoration.color, mapleNeck.wood);
    expect(find.text('Warm-up'), findsOneWidget);
  });
}
