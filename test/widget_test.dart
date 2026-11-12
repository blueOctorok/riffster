import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/app.dart';
import 'package:riffster/data/settings_store.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/theme/neck_theme.dart';
import 'package:riffster/widgets/stage/stage_view.dart';

import 'support/app_fonts.dart';

/// Opens the app in a window of [size], as a player who has already
/// answered the first-launch question with [instrument].
Future<SettingsStore> _open(
  WidgetTester tester, {
  Instrument? instrument = Instrument.guitar,
  Size size = const Size(1264, 681),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = SettingsStore.inMemory(instrument: instrument);
  await tester.pumpWidget(RiffsterApp(store: store));
  return store;
}

StageView _stage(WidgetTester tester) {
  return tester.widget<StageView>(find.byKey(const Key('staff')));
}

void main() {
  testWidgets('the first launch asks which instrument, then remembers', (
    tester,
  ) async {
    final store = await _open(tester, instrument: null);

    expect(find.text('What are you playing?'), findsOneWidget);
    expect(find.text('Warm-up'), findsNothing);

    await tester.tap(find.byKey(const Key('choose-bass')));
    await tester.pumpAndSettle();

    expect(store.instrument, Instrument.bass);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('100 bpm · Bass'), findsOneWidget);
    expect(_stage(tester).run.song.instrument, Instrument.bass);
    // The chord book is guitar shapes, so a bass does not offer it.
    expect(find.text('Chords'), findsNothing);

    // The keyboard works straight away, with nothing clicked first.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_stage(tester).run.playing, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
  });

  testWidgets('the whole song screen fits the window without scrolling', (
    tester,
  ) async {
    // Measured with the real typefaces. The test font's letters are
    // wide squares, which wrap text the app shows on one line.
    await tester.runAsync(loadAppFonts);
    await _open(tester, instrument: Instrument.bass);

    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, 0);
    // A test pretends to be a phone unless told otherwise, and a phone
    // gets taller buttons than a desktop. This one has to measure what
    // Windows will really show.
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('play counts one bar in before the first note', (tester) async {
    await _open(tester);
    final run = _stage(tester).run;

    expect(find.text('Riffster'), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    // At rest the clock waits one bar ahead of the first note.
    expect(run.positionMs, -2400);
    expect(find.byTooltip('Play (Space)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byTooltip('Pause (Space)'), findsOneWidget);
    expect(run.countIn, isNotNull);
    expect(run.positionMs, closeTo(-1700, 20));

    await tester.pump(const Duration(milliseconds: 1800));
    expect(run.countIn, isNull);
    expect(run.positionMs, closeTo(100, 20));

    await tester.tap(find.byKey(const Key('play')));
    await tester.pump();
    expect(run.playing, isFalse);
    // Let the last effects fade so no timer is left running.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the end of a run shows how it went, and Again restarts', (
    tester,
  ) async {
    await _open(tester, instrument: Instrument.bass);
    final run = _stage(tester).run;
    final moments = run.timeline.moments;

    // Play the first bar on time and leave the rest unplayed.
    run.play();
    var next = 0;
    while (!run.finished) {
      run.advance(const Duration(milliseconds: 10));
      if (next < 4 && run.positionMs >= moments[next].timeMs) {
        run.pluck(moments[next].notes.first.midi, latencyMs: 0);
        next++;
      }
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-summary')).hitTestable(), findsOneWidget);
    expect(find.text('36%'), findsWidgets);
    expect(find.textContaining('Missed notes were in bars 2, 3.'), findsOne);

    await tester.tap(find.text('Again'));
    await tester.pump();
    expect(run.playing, isTrue);
    expect(run.summary.judged, 0);
    expect(find.byKey(const Key('run-summary')).hitTestable(), findsNothing);

    run.pause();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the keys drive the run: space, speed, and loop', (tester) async {
    await _open(tester);
    final run = _stage(tester).run;

    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    expect(run.speed, 0.8);
    expect(find.text('80%'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(run.speed, 0.9);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pump();
    // The guitar warm-up is two bars, and a new loop covers both.
    expect(run.loop?.startMs, 0);
    expect(run.loop?.endMs, 4800);
    expect(find.text('Looping'), findsOneWidget);

    await tester.tap(find.byTooltip('Faster (+)').last);
    await tester.pump();
    expect(run.speed, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(run.playing, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(run.playing, isFalse);
  });

  testWidgets('a loop can be narrowed to a range of bars', (tester) async {
    await _open(tester, instrument: Instrument.bass);
    final run = _stage(tester).run;

    await tester.tap(find.byKey(const Key('loop')));
    await tester.pump();
    // Three bars of 2400 ms.
    expect(run.loop?.endMs, 7200);

    // The steppers read: from bar, to bar, speed. Each has a minus and
    // a plus, so the first plus moves the loop's start one bar later.
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(run.loop?.startMs, 2400);
    expect(run.loop?.endMs, 7200);

    await tester.tap(find.byIcon(Icons.remove_rounded).at(1));
    await tester.pump();
    expect(run.loop?.endMs, 4800);
  });

  testWidgets('the slider jumps to a later part of the song', (tester) async {
    await _open(tester);

    expect(find.text('0:00 / 0:04'), findsOneWidget);

    await tester.drag(find.byKey(const Key('position')), const Offset(300, 0));
    await tester.pump();

    expect(find.text('0:00 / 0:04'), findsNothing);
    expect(find.textContaining('/ 0:04'), findsOneWidget);
    expect(_stage(tester).run.positionMs, greaterThan(1000));
  });

  testWidgets('switching instrument swaps the warm-up and the strings', (
    tester,
  ) async {
    final store = await _open(tester);
    expect(_stage(tester).run.song.instrument, Instrument.guitar);

    await tester.tap(find.byKey(const Key('instrument-bass')));
    await tester.pump();

    expect(store.instrument, Instrument.bass);
    expect(_stage(tester).run.song.instrument, Instrument.bass);
    expect(find.text('100 bpm · Bass'), findsOneWidget);
  });

  testWidgets('chords lays every grip out and drops one on the staff', (
    tester,
  ) async {
    await _open(tester);
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

    // Bring the lane to the bottom edge of the window, which leaves the
    // chord cards above it on screen to drag from.
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('chord-lane'))),
      alignment: 1,
    );
    await tester.pump();
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
    // The dropped chord is now the song on the stage, named after itself.
    expect(_stage(tester).run.song.title, 'G');
    expect(_stage(tester).run.timeline.moments, hasLength(1));

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

    // Back to the song, which kept its place.
    await tester.ensureVisible(find.text('Song'));
    await tester.tap(find.text('Song'));
    await tester.pump();
    expect(find.text('Warm-up'), findsOneWidget);
  });

  testWidgets('maple turns the staff into a light neck and is remembered', (
    tester,
  ) async {
    final store = await _open(tester);
    expect(_stage(tester).neck, ebonyNeck);

    // The test font is wider than the real one, which can push the
    // bottom row just under the edge of the window.
    await tester.ensureVisible(find.text('Maple'));
    await tester.tap(find.text('Maple'));
    await tester.pump();

    expect(_stage(tester).neck, mapleNeck);
    expect(store.neck, mapleNeck);
    expect(find.text('Warm-up'), findsOneWidget);
  });
}
