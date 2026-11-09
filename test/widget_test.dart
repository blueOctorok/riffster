import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/app.dart';
import 'package:riffster/theme/neck_theme.dart';

void main() {
  testWidgets('practice screen shows the demo song', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RiffsterApp());

    expect(find.text('0:00 / 0:04'), findsOneWidget);

    await tester.drag(find.byKey(const Key('position')), const Offset(500, 0));
    await tester.pump();

    expect(find.text('0:00 / 0:04'), findsNothing);
    expect(find.textContaining('/ 0:04'), findsOneWidget);
  });

  testWidgets('chords lays every grip out and drops one on the staff', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RiffsterApp());
    await tester.tap(find.widgetWithText(OutlinedButton, 'Chords'));
    await tester.pump();

    expect(find.text('Changes'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Warm-up'), findsNothing);
    expect(find.byKey(const Key('chord-block-open-G')), findsOneWidget);
    expect(find.byKey(const Key('chord-block-open-Em')), findsOneWidget);
    expect(find.byKey(const Key('chord-block-barre-Bm E-shape')), findsNothing);
    expect(find.byKey(const Key('chord-block-seventh-Em7')), findsNothing);
    expect(find.text('Drop a chord here'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('chord-lane')));
    final from = tester.getCenter(find.byKey(const Key('chord-block-open-G')));
    final onto = tester.getCenter(find.byKey(const Key('chord-lane')));
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveTo(onto);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.text('G'), findsWidgets);
    expect(find.text('Drop a chord here'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'G' &&
            widget.style?.fontSize == 28,
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('group-barre')));
    await tester.tap(find.byKey(const Key('group-barre')));
    await tester.pump();
    expect(find.byKey(const Key('chord-block-barre-F')), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.byKey(const Key('barre-quality-Minor')));
    await tester.pump();
    expect(
      find.byKey(const Key('chord-block-barre-Bm E-shape')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chord-block-open-G')), findsNothing);
  });

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
