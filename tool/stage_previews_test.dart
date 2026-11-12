// Draws the app in a handful of fixed moments and saves each as a PNG
// in build/stage_previews, so the look can be checked without plugging
// in an instrument and playing a run by hand.
//
// Run it with:  flutter test tool/stage_previews_test.dart
//
// It lives in tool/ and not in test/ because it checks nothing. It only
// makes pictures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/app.dart';
import 'package:riffster/audio/guitar_ear.dart';
import 'package:riffster/data/demo_song.dart';
import 'package:riffster/data/settings_store.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_song.dart';
import 'package:riffster/music/chord_catalog.dart';
import 'package:riffster/music/chord_lane.dart';
import 'package:riffster/music/practice_run.dart';
import 'package:riffster/music/timing_check.dart';
import 'package:riffster/theme/neck_theme.dart';
import 'package:riffster/theme/riffster_theme.dart';
import 'package:riffster/widgets/practice/timing_check_dialog.dart';
import 'package:riffster/widgets/stage/stage_metrics.dart';
import 'package:riffster/widgets/stage/stage_view.dart';

import '../test/support/app_fonts.dart';

const _frame = Duration(milliseconds: 8);

/// The inside of the app's 1280 by 720 window, once Windows has taken
/// its title bar and borders.
const _window = Size(1264, 681);

/// How one moment of the song is played in a preview, by its index. A
/// number is how many milliseconds off the beat, and null leaves the
/// note unplayed. A moment that is not listed is played on time.
typedef Playing = Map<int, int?>;

const _mixed = <int, int?>{1: -130, 3: null, 5: 140};

/// A test pretends to be a phone unless told otherwise, and a phone
/// gets taller buttons than a desktop. The pictures should match what
/// Windows will show.
final _onWindows = TargetPlatformVariant.only(TargetPlatform.windows);

/// Plays [run] until the song clock reaches [untilMs].
void _playTo(PracticeRun run, double untilMs, {Playing playing = const {}}) {
  final moments = run.timeline.moments;
  final done = <int>{};
  run.play();
  while (run.playing && run.positionMs < untilMs) {
    run.advance(_frame);
    for (var index = 0; index < moments.length; index++) {
      if (done.contains(index)) continue;
      final offset = playing.containsKey(index) ? playing[index] : 0;
      if (offset == null) continue;
      if (run.positionMs < moments[index].timeMs + offset) continue;
      done.add(index);
      run.pluck(moments[index].notes.first.midi, latencyMs: 0);
    }
  }
}

/// Stops partway into the count: a little into its second beat.
void _countIn(PracticeRun run) {
  run.play();
  final target = run.positionMs + run.timeline.beatMs * 1.34;
  while (run.positionMs < target) {
    run.advance(_frame);
  }
}

Future<void> _save(ui.Image image, String name) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('build/stage_previews/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Saves what is on screen. [closeUp] also saves that corner at twice
/// the size, to judge the things a full view is too small to show.
Future<void> _snap(WidgetTester tester, String name, {Rect? closeUp}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  // Encoding a PNG is real work on another thread. A widget test runs
  // on a fake clock, and runAsync is the door out of it.
  await tester.runAsync(() async {
    await _save(await boundary.toImage(), name);
    if (closeUp == null) return;
    final large = await boundary.toImage(pixelRatio: 2);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      large,
      Rect.fromLTWH(
        closeUp.left * 2,
        closeUp.top * 2,
        closeUp.width * 2,
        closeUp.height * 2,
      ),
      Offset.zero & (closeUp.size * 2),
      Paint(),
    );
    final cut = await recorder.endRecording().toImage(
      (closeUp.width * 2).round(),
      (closeUp.height * 2).round(),
    );
    await _save(cut, '${name}_close');
  });
}

const _shot = Key('shot');

/// The stage alone, in the room, at the width it has in the window.
Future<void> _stageShot(
  WidgetTester tester,
  String name, {
  required TabSong song,
  required NeckTheme neck,
  void Function(PracticeRun run)? arrange,
  Rect? closeUp,
}) async {
  // The stage's own height, plus the padding around it below.
  await tester.binding.setSurfaceSize(
    Size(_window.width, StageMetrics.height + 68),
  );
  final run = PracticeRun(song);
  arrange?.call(run);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: riffsterTheme(),
      home: RepaintBoundary(
        key: _shot,
        child: ColoredBox(
          color: RiffColors.room,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 44),
            child: StageView(run: run, neck: neck),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await _snap(tester, name, closeUp: closeUp);
  run.dispose();
}

/// The whole app, as a player who chose [instrument] would see it.
Future<PracticeRun?> _openApp(
  WidgetTester tester, {
  Instrument? instrument,
  NeckTheme neck = ebonyNeck,
}) async {
  await tester.binding.setSurfaceSize(_window);
  final store = SettingsStore.inMemory(instrument: instrument)..neck = neck;
  await tester.pumpWidget(
    RepaintBoundary(
      // A new key each time, so one preview's app is never reused for
      // the next.
      key: _shot,
      child: RiffsterApp(key: UniqueKey(), store: store),
    ),
  );
  await tester.pump();
  if (instrument == null) return null;
  return tester.widget<StageView>(find.byType(StageView)).run;
}

void main() {
  const nearPlayhead = Rect.fromLTWH(28, 24, 520, StageMetrics.height);

  testWidgets('stage previews', (tester) async {
    await tester.runAsync(loadAppFonts);
    final bass = warmUpFor(Instrument.bass);
    final guitar = warmUpFor(Instrument.guitar);
    final changes = songFromLane([
      for (final name in ['G', 'C', 'D', 'Em', 'F'])
        LaneChord(
          chordBlocks.firstWhere((block) => block.label == name),
          durationMs: 1400,
        ),
    ]);

    await _stageShot(tester, 'bass_rest_ebony', song: bass, neck: ebonyNeck);
    await _stageShot(
      tester,
      'bass_count_ebony',
      song: bass,
      neck: ebonyNeck,
      arrange: _countIn,
    );
    await _stageShot(
      tester,
      'bass_run_ebony',
      song: bass,
      neck: ebonyNeck,
      closeUp: nearPlayhead,
      arrange: (run) => _playTo(run, 3640, playing: _mixed),
    );
    for (final neck in [rosewoodNeck, mapleNeck]) {
      await _stageShot(
        tester,
        'bass_run_${neck.name.toLowerCase()}',
        song: bass,
        neck: neck,
        arrange: (run) => _playTo(run, 3040, playing: _mixed),
      );
    }
    await _stageShot(
      tester,
      'guitar_rest_rosewood',
      song: guitar,
      neck: rosewoodNeck,
    );
    for (final neck in [ebonyNeck, mapleNeck]) {
      await _stageShot(
        tester,
        'guitar_run_${neck.name.toLowerCase()}',
        song: guitar,
        neck: neck,
        closeUp: neck == ebonyNeck ? nearPlayhead : null,
        arrange: (run) => _playTo(run, 2440, playing: _mixed),
      );
    }
    await _stageShot(
      tester,
      'guitar_chords_ebony',
      song: changes,
      neck: ebonyNeck,
      arrange: (run) => _playTo(run, 2000, playing: const {1: null}),
    );
  }, variant: _onWindows);

  testWidgets('screen previews', (tester) async {
    await tester.runAsync(loadAppFonts);
    // The screen makes a recorder as soon as it is built. No recording
    // plugin exists in a test, so its one call is answered with nothing.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (call) async => null,
    );

    await _openApp(tester);
    await _snap(tester, 'screen_first_launch');

    await _openApp(tester, instrument: Instrument.bass);
    await _snap(tester, 'screen_bass_rest');

    var run = (await _openApp(tester, instrument: Instrument.bass))!;
    _countIn(run);
    await tester.pump();
    await _snap(tester, 'screen_bass_count');

    run = (await _openApp(tester, instrument: Instrument.bass))!;
    _playTo(run, 3640, playing: _mixed);
    await tester.pump();
    await _snap(tester, 'screen_bass_run');

    run = (await _openApp(tester, instrument: Instrument.bass))!;
    _playTo(run, double.infinity, playing: _mixed);
    // Long enough for the card to finish sliding up.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await _snap(tester, 'screen_bass_finished');

    run = (await _openApp(
      tester,
      instrument: Instrument.guitar,
      neck: mapleNeck,
    ))!;
    run.loop = const LoopRange(0, 2400);
    _playTo(run, 1300, playing: _mixed);
    await tester.pump();
    await _snap(tester, 'screen_guitar_loop_maple');

    await _openApp(tester, instrument: Instrument.guitar);
    await tester.tap(find.text('Chords'));
    await tester.pump();
    await _snap(tester, 'screen_guitar_chords');

    // The timing check, six measured clicks in. No cable is plugged
    // in here, so the dialog is opened directly and the notes are
    // made up.
    final ear = GuitarEar();
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shot,
        child: MaterialApp(
          key: UniqueKey(),
          debugShowCheckedModeBanner: false,
          theme: riffsterTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: RiffColors.room,
              body: TextButton(
                onPressed: () => showTimingCheck(context, ear),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await _snap(tester, 'timing_check_ready');
    await tester.tap(find.text('Start'));
    await tester.pump();
    const beat = Duration(milliseconds: 600);
    for (var click = 1; click < timingCheckLeadIn + 6; click++) {
      await tester.pump(beat);
    }
    await tester.pump(const Duration(milliseconds: 200));
    await _snap(tester, 'timing_check_running');
    for (var click = 0; click < 3; click++) {
      await tester.pump(beat);
    }
    await _snap(tester, 'timing_check_uneven');
  }, variant: _onWindows);
}
