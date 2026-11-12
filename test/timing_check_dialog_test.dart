import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/audio/guitar_ear.dart';
import 'package:riffster/data/settings_store.dart';
import 'package:riffster/music/timing_check.dart';
import 'package:riffster/theme/riffster_theme.dart';
import 'package:riffster/widgets/practice/input_bar.dart';
import 'package:riffster/widgets/practice/timing_check_dialog.dart';

import 'support/app_fonts.dart';

/// The frames here are pretend time, but the dialog times a note
/// between two frames with a real stopwatch. The test itself takes
/// about a millisecond to get from the frame to the note.
const _testSlackMs = 5.0;

/// Opens the dialog over an empty page and presses Start. The delay
/// it is closed with lands in the returned list.
Future<List<double?>> _startCheck(WidgetTester tester, GuitarEar ear) async {
  final results = <double?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await showTimingCheck(context, ear)),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start'));
  // The first frame of the dialog's clock, which is its first click.
  await tester.pump();
  return results;
}

/// Runs the twelve clicks. [noteAfterMs] gives how long after each
/// click a note is played, or null to stay silent on that click.
Future<void> _playAlong(
  WidgetTester tester,
  GuitarEar ear,
  int? Function(int click) noteAfterMs,
) async {
  const beat = Duration(milliseconds: 600);
  expect(beat.inMilliseconds, timingCheckBeatMs);
  for (var click = 0; click < timingCheckLeadIn + timingCheckClicks; click++) {
    final after = Duration(milliseconds: noteAfterMs(click) ?? 0);
    await tester.pump(after);
    if (noteAfterMs(click) != null) ear.onPluck!(28, 0);
    await tester.pump(beat - after);
  }
}

HeardInput _input({
  EarSource? active,
  bool isGuitar = true,
  bool exclusive = false,
  int latencyMs = 50,
}) {
  return HeardInput(
    name: 'Rocksmith USB Guitar Adapter',
    isGuitar: isGuitar,
    speakerReady: isGuitar,
    inputs: const [],
    cablePresent: true,
    irigPresent: false,
    micPresent: true,
    active: active,
    exclusive: exclusive,
    latencyMs: latencyMs,
  );
}

/// The input bar alone, at the width it has in the app's window.
Future<void> _showBar(
  WidgetTester tester,
  HeardInput input, {
  double? measuredDelayMs,
  VoidCallback? onTimingCheck,
  VoidCallback? onClip,
}) async {
  tester.view.physicalSize = const Size(1264, 681);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: riffsterTheme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: InputBar(
            input: input,
            failed: false,
            looking: false,
            level: ValueNotifier(0),
            volume: 1,
            speakerOn: true,
            onSource: (_) {},
            onLookAgain: () {},
            onVolume: (_) {},
            onSpeaker: (_) {},
            measuredDelayMs: measuredDelayMs,
            onTimingCheck: onTimingCheck ?? () {},
            onClip: onClip,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('eight notes 30 ms behind the click measure 30 ms', (
    tester,
  ) async {
    final ear = GuitarEar();
    void screenListener(int? midi, double agoMs) {}
    ear.onPluck = screenListener;
    final results = await _startCheck(tester, ear);

    await _playAlong(tester, ear, (click) => 30);

    expect(find.textContaining('ms after the click.'), findsOneWidget);
    await tester.tap(find.text('Use it'));
    await tester.pumpAndSettle();
    expect(results.single, closeTo(30, _testSlackMs));
    // The practice screen is listening again.
    expect(ear.onPluck, screenListener);
  });

  testWidgets('a note the detector was slow to name still counts on time', (
    tester,
  ) async {
    final ear = GuitarEar();
    final results = await _startCheck(tester, ear);

    // Each note reaches the dialog 70 ms after the click and says it
    // was played 45 ms ago, so it was 25 ms behind the click.
    const beat = Duration(milliseconds: 600);
    for (var click = 0; click < timingCheckLeadIn + timingCheckClicks; click++) {
      await tester.pump(const Duration(milliseconds: 70));
      ear.onPluck!(28, 45);
      await tester.pump(beat - const Duration(milliseconds: 70));
    }

    await tester.tap(find.text('Use it'));
    await tester.pumpAndSettle();
    expect(results.single, closeTo(25, _testSlackMs));
  });

  testWidgets('silence gives no number, and Again runs it once more', (
    tester,
  ) async {
    final ear = GuitarEar();
    final results = await _startCheck(tester, ear);

    await _playAlong(tester, ear, (click) => null);

    expect(find.textContaining('No notes were heard'), findsOneWidget);
    expect(find.text('Use it'), findsNothing);

    await tester.tap(find.text('Again'));
    await tester.pump();
    await _playAlong(tester, ear, (click) => 12);
    expect(find.textContaining('ms after the click.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results.single, isNull);
  });

  testWidgets('notes all over the beat are called uneven, not measured', (
    tester,
  ) async {
    final ear = GuitarEar();
    await _startCheck(tester, ear);

    await _playAlong(tester, ear, (click) => click.isEven ? 20 : 280);

    expect(find.textContaining('too uneven to measure'), findsOneWidget);
    expect(find.text('Use it'), findsNothing);
  });

  testWidgets('the timing check is offered once an input is open', (
    tester,
  ) async {
    var asked = 0;
    await _showBar(tester, _input(), onTimingCheck: () => asked++);
    expect(find.byKey(const Key('timing-check')), findsNothing);

    await _showBar(
      tester,
      _input(active: EarSource.cable),
      onTimingCheck: () => asked++,
    );
    await tester.tap(find.text('Timing check'));
    expect(asked, 1);

    // The room mic is listed, and cannot be measured: it would hear
    // the click.
    await _showBar(
      tester,
      _input(active: EarSource.mic, isGuitar: false),
      onTimingCheck: () => asked++,
    );
    await tester.tap(find.text('Timing check'));
    expect(asked, 1);
  });

  testWidgets('a measured cable shows its delay, and nothing is cut short', (
    tester,
  ) async {
    await tester.runAsync(loadAppFonts);
    final input = _input(active: EarSource.cable, exclusive: true);
    await _showBar(tester, input, measuredDelayMs: 27.4, onClip: () {});

    expect(find.text('Timing 27 ms'), findsOneWidget);
    expect(find.text('Record clip'), findsOneWidget);
    final status = tester.renderObject<RenderParagraph>(
      find.text('${input.name} · exclusive'),
    );
    expect(status.didExceedMaxLines, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  test('a measured delay is kept for the input it was measured on', () {
    final store = SettingsStore.inMemory();
    expect(store.inputDelayMs('Rocksmith · 20'), isNull);

    store.setInputDelayMs('Rocksmith · 20', 27.5);

    expect(store.inputDelayMs('Rocksmith · 20'), 27.5);
    expect(store.inputDelayMs('Rocksmith · 50'), isNull);
  });

  test('each way of opening an input is its own route', () {
    expect(_input().route, isNull);
    expect(
      _input(active: EarSource.cable, latencyMs: 20).route,
      isNot(_input(active: EarSource.cable, latencyMs: 35).route),
    );
  });
}
