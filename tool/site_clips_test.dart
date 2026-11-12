// Films the app for the website. Each clip plays a run one frame at a
// time, with the notes played by a script, and hands every frame to
// ffmpeg, which packs them into an MP4 in riffster-site/public/media.
//
// It is the real app drawing itself, so a clip never drifts from what
// the app looks like. Nothing is plugged in: the script tells the run
// "this note was played, this many milliseconds off the beat".
//
// Run it from the project root, with FFMPEG set to an ffmpeg program:
//
//   FFMPEG=build/ffmpeg/node_modules/ffmpeg-static/ffmpeg.exe \
//     flutter test tool/site_clips_test.dart
//
// It lives in tool/ and not in test/ because it checks nothing.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/app.dart';
import 'package:riffster/data/demo_song.dart';
import 'package:riffster/data/settings_store.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_song.dart';
import 'package:riffster/music/chord_catalog.dart';
import 'package:riffster/music/chord_lane.dart';
import 'package:riffster/music/practice_run.dart';
import 'package:riffster/theme/neck_theme.dart';
import 'package:riffster/theme/riffster_theme.dart';
import 'package:riffster/widgets/chord_palette.dart';
import 'package:riffster/widgets/practice/transport_dock.dart';
import 'package:riffster/widgets/stage/stage_metrics.dart';
import 'package:riffster/widgets/stage/stage_view.dart';

import '../test/support/app_fonts.dart';

const _framesPerSecond = 60;
const _frame = Duration(microseconds: 1000000 ~/ _framesPerSecond);
const _mediaFolder = 'riffster-site/public/media';

/// The inside of the app's 1280 by 720 window.
const _window = Size(1264, 681);

/// Where the stage sits when it is filmed alone, padding and all.
const _stagePadding = EdgeInsets.fromLTRB(28, 24, 28, 44);

const _shot = Key('shot');
const _filming = Timeout(Duration(minutes: 30));
final _onWindows = TargetPlatformVariant.only(TargetPlatform.windows);

/// How each moment of the song is played, by its index. A number is how
/// many milliseconds off the beat, and null leaves the note unplayed. A
/// moment that is not listed is played dead on time.
typedef Playing = Map<int, int?>;

/// A good take: a little human wobble, and one note dragged late.
const _goodTake = <int, int?>{
  0: -18,
  1: 12,
  2: -6,
  3: 22,
  4: -30,
  5: 9,
  6: 150,
  7: -12,
  8: 16,
  9: -8,
  10: 5,
};

/// A rougher take that shows every mark: early, a miss, and late.
const _roughTake = <int, int?>{
  0: -10,
  1: -140,
  2: 14,
  3: null,
  4: -8,
  5: 20,
  6: 135,
  7: -16,
  8: 6,
  9: 11,
  10: -4,
};

/// Plays the scripted notes as the clock reaches them.
class _ScriptedPlayer {
  _ScriptedPlayer(this.run, this.playing);

  final PracticeRun run;
  final Playing playing;
  final _played = <int>{};

  void playWhatIsDue() {
    final moments = run.timeline.moments;
    for (var index = 0; index < moments.length; index++) {
      if (_played.contains(index)) continue;
      final offsetMs = playing.containsKey(index) ? playing[index] : 0;
      if (offsetMs == null) continue;
      final dueMs = moments[index].timeMs + offsetMs;
      if (run.positionMs < dueMs) continue;
      _played.add(index);
      // A frame lands a few milliseconds after the note was due. Saying
      // how long ago it was plucked keeps the timing exact, the same
      // way the app corrects for a cable's delay.
      run.pluck(
        moments[index].notes.first.midi,
        latencyMs: run.positionMs - dueMs,
      );
    }
  }
}

/// One clip being written. Frames go straight down a pipe to ffmpeg, so
/// a twelve-second clip never sits on disk as 700 pictures.
class _Film {
  _Film(this.tester, this.name, {required this.crop, required this.scale});

  final WidgetTester tester;
  final String name;

  /// The part of the screen to keep, in the app's own units.
  final Rect crop;

  /// Pixels per unit. Above 1 keeps the clip sharp on a dense screen.
  final double scale;

  Process? _ffmpeg;
  final _complaints = StringBuffer();

  // The video format stores color at half size, so both sides of the
  // picture have to be even numbers.
  int get _width => (crop.width * scale / 2).round() * 2;
  int get _height => (crop.height * scale / 2).round() * 2;

  String get _path => '$_mediaFolder/$name.mp4';

  Future<Process> _start() async {
    Directory(_mediaFolder).createSync(recursive: true);
    final ffmpeg = await Process.start(_ffmpegProgram(), [
      '-y', '-loglevel', 'error',
      // What comes down the pipe: bare pixels, this size, this fast.
      '-f', 'rawvideo', '-pix_fmt', 'rgba',
      '-s', '${_width}x$_height', '-r', '$_framesPerSecond',
      '-i', '-',
      // What goes out: H.264, which every browser and phone plays.
      '-an', '-c:v', 'libx264', '-preset', 'slow', '-crf', '21',
      '-vf', 'scale=out_color_matrix=bt709:out_range=tv',
      '-pix_fmt', 'yuv420p',
      '-colorspace', 'bt709', '-color_primaries', 'bt709',
      '-color_trc', 'bt709', '-color_range', 'tv',
      // Puts the index at the front, so it plays before it finishes
      // downloading.
      '-movflags', '+faststart',
      _path,
    ]);
    // An unread error pipe fills up and stalls ffmpeg.
    ffmpeg.stderr.transform(utf8.decoder).listen(_complaints.write);
    ffmpeg.stdout.drain<void>();
    return ffmpeg;
  }

  /// Adds what is on screen right now as the next frame.
  Future<void> addFrame() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_shot),
    );
    await tester.runAsync(() async {
      final whole = await boundary.toImage(pixelRatio: scale);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImage(
        whole,
        Offset(-crop.left * scale, -crop.top * scale),
        Paint(),
      );
      final cut = await recorder.endRecording().toImage(_width, _height);
      final pixels = await cut.toByteData(format: ui.ImageByteFormat.rawRgba);
      whole.dispose();
      cut.dispose();
      final ffmpeg = _ffmpeg ??= await _start();
      ffmpeg.stdin.add(pixels!.buffer.asUint8List());
      // Waits until ffmpeg has taken the frame, so frames do not pile
      // up in memory faster than they are encoded.
      await ffmpeg.stdin.flush();
    });
  }

  /// Ends the clip, and saves the frame at [posterAt] as its still.
  Future<void> finish({required Duration posterAt}) async {
    await tester.runAsync(() async {
      final ffmpeg = _ffmpeg!;
      await ffmpeg.stdin.close();
      final code = await ffmpeg.exitCode;
      if (code != 0) throw StateError('ffmpeg failed on $name: $_complaints');
      final seconds = posterAt.inMilliseconds / 1000;
      final still = await Process.run(_ffmpegProgram(), [
        '-y', '-loglevel', 'error',
        '-ss', '$seconds', '-i', _path,
        '-frames:v', '1', '-q:v', '3',
        '$_mediaFolder/$name.jpg',
      ]);
      if (still.exitCode != 0) {
        throw StateError('No still for $name: ${still.stderr}');
      }
    });
  }
}

String _ffmpegProgram() {
  final program = Platform.environment['FFMPEG'];
  if (program == null) {
    throw StateError('Set FFMPEG to the path of an ffmpeg program.');
  }
  return program;
}

/// Films the stage alone: a short rest, the count, the run, and a
/// moment to read the last result.
///
/// [skipCountMs] leaves the start of a long count out of the clip.
Future<void> _filmStage(
  WidgetTester tester,
  String name, {
  required TabSong song,
  required NeckTheme neck,
  required Playing playing,
  required double scale,
  Rect? crop,
  double skipCountMs = 0,
}) async {
  await tester.binding.setSurfaceSize(
    Size(_window.width, StageMetrics.height + _stagePadding.vertical),
  );
  final run = PracticeRun(song);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: riffsterTheme(),
      home: RepaintBoundary(
        key: _shot,
        child: ColoredBox(
          color: RiffColors.room,
          child: Padding(
            padding: _stagePadding,
            child: StageView(run: run, neck: neck),
          ),
        ),
      ),
    ),
  );
  final film = _Film(
    tester,
    name,
    crop: crop ?? tester.getRect(find.byType(StageView)),
    scale: scale,
  );
  final player = _ScriptedPlayer(run, playing);

  // The stage has no timer of its own here, so this moves its clock.
  Future<void> step({bool filmed = true}) async {
    run.advance(_frame);
    player.playWhatIsDue();
    await tester.pump();
    if (filmed) await film.addFrame();
  }

  if (skipCountMs == 0) {
    for (var rest = 0; rest < _framesPerSecond ~/ 2; rest++) {
      await step();
    }
  }
  run.play();
  final filmFromMs = run.positionMs + skipCountMs;
  while (run.needsFrames) {
    await step(filmed: run.positionMs >= filmFromMs);
  }
  for (var hold = 0; hold < _framesPerSecond ~/ 2; hold++) {
    await step();
  }
  await film.finish(posterAt: const Duration(milliseconds: 5200));
  run.dispose();
}

/// Opens the whole app on [instrument] and returns the run on its stage.
Future<PracticeRun> _openApp(
  WidgetTester tester,
  Instrument instrument,
) async {
  // The screen makes a recorder as soon as it is built. No recording
  // plugin exists in a test, so its one call is answered with nothing.
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.record/messages'),
    (call) async => null,
  );
  await tester.binding.setSurfaceSize(_window);
  final store = SettingsStore.inMemory(instrument: instrument);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shot,
      child: RiffsterApp(key: UniqueKey(), store: store),
    ),
  );
  await tester.pump();
  return tester.widget<StageView>(find.byType(StageView)).run;
}

void main() {
  final bass = warmUpFor(Instrument.bass);

  testWidgets('the whole app, one good run', (tester) async {
    await tester.runAsync(loadAppFonts);
    final run = await _openApp(tester, Instrument.bass);
    // The clip stops under the play controls. The row below them says
    // "Looking for an input…", which is true of a test and would only
    // puzzle someone watching.
    final dock = tester.getRect(find.byType(TransportDock));
    final film = _Film(
      tester,
      'app-run',
      crop: Rect.fromLTRB(0, 0, _window.width, dock.bottom + 8),
      scale: 1.5,
    );
    final player = _ScriptedPlayer(run, _goodTake);

    // The app's own frame timer moves the run here, so a frame is
    // only time going by. The second pump draws what a pluck changed.
    Future<void> step() async {
      await tester.pump(_frame);
      player.playWhatIsDue();
      await tester.pump();
      await film.addFrame();
    }

    for (var rest = 0; rest < 40; rest++) {
      await step();
    }
    run.play();
    while (!run.finished) {
      await step();
    }
    // Long enough for the result card to slide up and be read.
    for (var hold = 0; hold < _framesPerSecond * 3; hold++) {
      await step();
    }
    await film.finish(posterAt: const Duration(milliseconds: 6400));
  }, variant: _onWindows, timeout: _filming);

  testWidgets('close on the playhead, every mark', (tester) async {
    await tester.runAsync(loadAppFonts);
    await _filmStage(
      tester,
      'stage-marks',
      song: bass,
      neck: ebonyNeck,
      playing: _roughTake,
      crop: Rect.fromLTWH(
        _stagePadding.left,
        _stagePadding.top,
        560,
        StageMetrics.height,
      ),
      scale: 2,
    );
  }, variant: _onWindows, timeout: _filming);

  for (final neck in neckThemes) {
    testWidgets('the ${neck.name} board', (tester) async {
      await tester.runAsync(loadAppFonts);
      await _filmStage(
        tester,
        'neck-${neck.name.toLowerCase()}',
        song: bass,
        neck: neck,
        playing: _goodTake,
        scale: 1.5,
      );
    }, variant: _onWindows, timeout: _filming);
  }

  testWidgets('guitar chord changes', (tester) async {
    await tester.runAsync(loadAppFonts);
    final changes = songFromLane([
      for (final name in ['G', 'C', 'D', 'Em', 'F'])
        LaneChord(
          chordBlocks.firstWhere((block) => block.label == name),
          durationMs: 1400,
        ),
    ]);
    await _filmStage(
      tester,
      'guitar-changes',
      song: changes,
      neck: rosewoodNeck,
      playing: const {0: -14, 1: 20, 2: -128, 3: 10, 4: -6},
      scale: 1.5,
      // The lane counts in slowly. Half of it is enough to watch.
      skipCountMs: 2000,
    );
  }, variant: _onWindows, timeout: _filming);

  testWidgets('the first row of the chord book, as a still', (tester) async {
    await tester.runAsync(loadAppFonts);
    await _openApp(tester, Instrument.guitar);
    await tester.tap(find.text('Chords'));
    await tester.pump();
    final book = tester.getRect(find.byType(ChordPalette));
    // The whole width of the book, and as tall as its first card.
    final firstCard = tester.getRect(
      find
          .descendant(
            of: find.byType(ChordPalette),
            matching: find.byType(Draggable<LaneDrag>),
          )
          .first,
    );
    final cards = Rect.fromLTRB(
      book.left,
      book.top,
      book.right,
      firstCard.bottom,
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_shot),
    );
    await tester.runAsync(() async {
      const scale = 2.0;
      final whole = await boundary.toImage(pixelRatio: scale);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImage(
        whole,
        Offset(-cards.left * scale, -cards.top * scale),
        Paint(),
      );
      final cut = await recorder.endRecording().toImage(
        (cards.width * scale).round(),
        (cards.height * scale).round(),
      );
      final png = await cut.toByteData(format: ui.ImageByteFormat.png);
      File('$_mediaFolder/chord-book-row.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }, variant: _onWindows, timeout: _filming);
}
