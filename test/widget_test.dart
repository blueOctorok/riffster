import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/app.dart';
import 'package:riffster/data/library_item.dart';
import 'package:riffster/data/library_store.dart';
import 'package:riffster/data/settings_store.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/models/tab_song.dart';
import 'package:riffster/music/practice_run.dart';
import 'package:riffster/theme/neck_theme.dart';
import 'package:riffster/widgets/shell/app_area.dart';
import 'package:riffster/widgets/stage/stage_view.dart';

import 'support/app_fonts.dart';

/// Opens the app in a window of [size], as a player who has already
/// answered the first-launch question with [instrument], and goes to
/// [area]. Most tests are about the stage, so that is Songs unless
/// the test says otherwise.
Future<SettingsStore> _open(
  WidgetTester tester, {
  Instrument? instrument = Instrument.guitar,
  AppArea area = AppArea.songs,
  Size size = const Size(1264, 681),
  LibraryStore? library,
}) async {
  // The test font's letters are wide squares. In those, the wordmark
  // alone is wider than the rail, so the app is drawn in its own type.
  await tester.runAsync(loadAppFonts);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = SettingsStore.inMemory(instrument: instrument);
  await tester.pumpWidget(
    RiffsterApp(store: store, library: library ?? LibraryStore.inMemory()),
  );
  // The app opens on Home, or on the chooser when no instrument is set.
  if (instrument != null && area != AppArea.home) await _go(tester, area);
  return store;
}

/// Presses [area] on the rail and waits for the move to finish.
Future<void> _go(WidgetTester tester, AppArea area) async {
  await tester.tap(find.byKey(Key('area-${area.name}')));
  await tester.pumpAndSettle();
}

/// Whether the rail lets you press [area].
bool _canGo(WidgetTester tester, AppArea area) {
  final button = find.byKey(Key('area-${area.name}'));
  return tester.widget<TextButton>(button).onPressed != null;
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

    // Home, with the bass warm-up waiting on the stage.
    expect(store.instrument, Instrument.bass);
    expect(find.text('What are we playing today?'), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('100 bpm · Bass'), findsOneWidget);
    expect(find.byKey(const Key('staff')), findsNothing);
    // The chord book is guitar shapes, so a bass cannot open Build.
    expect(_canGo(tester, AppArea.build), isFalse);

    await tester.tap(find.byKey(const Key('home-stage')));
    await tester.pumpAndSettle();
    expect(_stage(tester).run.song.instrument, Instrument.bass);

    // The keyboard works as soon as the stage is up.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_stage(tester).run.playing, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
  });

  testWidgets('Home and the song screen fit the window without scrolling', (
    tester,
  ) async {
    await _open(tester, instrument: Instrument.bass, area: AppArea.home);

    double scrollRoom() {
      final area = find.byType(Scrollable).first;
      return tester.state<ScrollableState>(area).position.maxScrollExtent;
    }

    expect(scrollRoom(), 0);
    await _go(tester, AppArea.songs);
    expect(scrollRoom(), 0);
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
    await _open(tester, area: AppArea.build);

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
    await _go(tester, AppArea.songs);
    expect(find.text('Warm-up'), findsOneWidget);
  });

  testWidgets('the rail lights where you are and dims what is not built', (
    tester,
  ) async {
    await _open(tester, area: AppArea.home);

    expect(_canGo(tester, AppArea.songs), isTrue);
    expect(_canGo(tester, AppArea.build), isTrue);
    expect(_canGo(tester, AppArea.library), isTrue);
    expect(_canGo(tester, AppArea.practice), isTrue);
    expect(_canGo(tester, AppArea.create), isFalse);

    // Home has no stage, so Space has nothing to start.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _go(tester, AppArea.songs);
    expect(_stage(tester).run.playing, isFalse);

    // A song that is playing is paused when you walk away from it.
    final run = _stage(tester).run;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(run.playing, isTrue);
    await _go(tester, AppArea.home);
    expect(run.playing, isFalse);
    expect(find.byKey(const Key('staff')), findsNothing);
  });

  testWidgets('switching to bass in the chord book leaves for Songs', (
    tester,
  ) async {
    await _open(tester, area: AppArea.build);
    expect(find.byKey(const Key('chord-lane')), findsOneWidget);

    await tester.tap(find.byKey(const Key('instrument-bass')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chord-lane')), findsNothing);
    expect(find.text('100 bpm · Bass'), findsOneWidget);
    expect(_canGo(tester, AppArea.build), isFalse);
  });

  testWidgets('the input chip opens the panel, and a click away closes it', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byKey(const Key('tuner-words')), findsNothing);

    await tester.tap(find.byKey(const Key('input-chip')));
    await tester.pumpAndSettle();
    expect(find.text('Play an open string'), findsOneWidget);
    expect(find.byKey(const Key('input-cable')), findsOneWidget);

    // Far from the panel, over the stage.
    await tester.tapAt(const Offset(1100, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tuner-words')), findsNothing);
    // The click only closed the panel. It did not reach what was under it.
    expect(_stage(tester).run.playing, isFalse);
  });

  testWidgets('maple turns the staff into a light neck and is remembered', (
    tester,
  ) async {
    final store = await _open(tester);
    expect(_stage(tester).neck, ebonyNeck);

    await tester.tap(find.text('Maple'));
    await tester.pump();

    expect(_stage(tester).neck, mapleNeck);
    expect(store.neck, mapleNeck);
    expect(find.text('Warm-up'), findsOneWidget);
  });

  testWidgets('the Library lists what came with the app, and a card opens it', (
    tester,
  ) async {
    await _open(tester, instrument: Instrument.bass, area: AppArea.library);

    expect(find.text('RIFFSTER ORIGINALS'), findsOneWidget);
    expect(find.text('YOUR SONGS'), findsNothing);
    expect(find.byKey(const Key('staff')), findsNothing);

    await tester.tap(find.byKey(const Key('library-low-road-bass')));
    await tester.pumpAndSettle();

    expect(_stage(tester).run.song.title, 'Low Road');
    expect(_stage(tester).run.song.bars, hasLength(4));
  });

  testWidgets('a song played through shows its best score at that speed', (
    tester,
  ) async {
    final library = LibraryStore.inMemory();
    await _open(
      tester,
      instrument: Instrument.bass,
      area: AppArea.library,
      library: library,
    );
    await tester.tap(find.byKey(const Key('library-low-road-bass')));
    await tester.pumpAndSettle();
    final run = _stage(tester).run;

    // Slowed for a while and then let go: the run was a slowed run.
    run.speed = 0.7;
    _playThrough(run, afterBars: 1, then: () => run.speed = 1);
    await tester.pump();

    expect(library.bestScores('low-road-bass'), [
      (speedPercent: 70, onTimePercent: 100),
    ]);
    await _go(tester, AppArea.library);
    expect(find.text('AT 70%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    // Every other card still waits for its first run.
    expect(find.text('NOT PLAYED YET'), findsWidgets);
  });

  testWidgets('a run started partway through keeps no score', (tester) async {
    final library = LibraryStore.inMemory();
    await _open(
      tester,
      instrument: Instrument.bass,
      area: AppArea.library,
      library: library,
    );
    await tester.tap(find.byKey(const Key('library-low-road-bass')));
    await tester.pumpAndSettle();
    final run = _stage(tester).run;

    run.seek(run.song.bars[2].startMs.toDouble());
    _playThrough(run);
    await tester.pump();

    expect(run.finished, isTrue);
    expect(library.bestScores('low-road-bass'), isEmpty);
  });

  testWidgets('the Library shows only this instrument, and a song of your '
      'own can be removed', (tester) async {
    final library = LibraryStore.inMemory();
    library.save(
      const TabSong(
        title: 'My guitar part',
        tempoBpm: 90,
        notes: [
          TabNote(timeMs: 0, string: 1, fret: 0, durationMs: 500, midi: 64),
        ],
      ).withCommonTimeBars(),
    );
    await _open(tester, area: AppArea.library, library: library);

    // Everything that comes with the app is for bass.
    expect(find.text('YOUR SONGS'), findsOneWidget);
    expect(find.text('RIFFSTER ORIGINALS'), findsNothing);
    expect(find.text('My guitar part'), findsOneWidget);

    await tester.tap(find.byKey(const Key('remove-my-guitar-part-guitar')));
    await tester.pumpAndSettle();

    expect(find.text('My guitar part'), findsNothing);
    expect(find.textContaining('Nothing for guitar yet'), findsOneWidget);
    expect(
      library.items.where((item) => item.source == SongSource.yours),
      isEmpty,
    );
  });

  testWidgets('Practice plays a scale, and a new choice replaces it', (
    tester,
  ) async {
    await _open(tester, instrument: Instrument.bass, area: AppArea.practice);

    expect(_stage(tester).run.song.title, 'E major');
    expect(_stage(tester).run.song.notes.first.midi, 28);

    await tester.tap(find.byKey(const Key('root-A')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('line-minorPentatonic')));
    await tester.pump();

    final song = _stage(tester).run.song;
    expect(song.title, 'A minor pentatonic');
    // The open A string.
    expect(song.notes.first.midi, 33);
    expect(song.notes.last.midi, 33);
    // The blue note of the blues scale is not in the pentatonic.
    expect(song.notes.map((note) => note.midi), isNot(contains(39)));

    // The song on Songs is untouched.
    await _go(tester, AppArea.songs);
    expect(_stage(tester).run.song.title, 'Warm-up');
  });
}

/// Plays every note of [run] on time, from where it stands to the end.
/// [then] is called once, after [afterBars] bars have gone by.
void _playThrough(PracticeRun run, {int? afterBars, VoidCallback? then}) {
  final moments = run.timeline.moments;
  var next = run.timeline.firstAtOrAfter(run.positionMs);
  var pending = then;
  run.play();
  while (run.playing) {
    run.advance(const Duration(milliseconds: 8));
    while (next < moments.length && run.positionMs >= moments[next].timeMs) {
      run.pluck(moments[next].notes.first.midi, latencyMs: 0);
      next++;
    }
    if (pending != null && run.positionMs >= run.song.bars[afterBars!].endMs) {
      pending();
      pending = null;
    }
  }
}
