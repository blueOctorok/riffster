import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/import/imported_score.dart';
import 'package:riffster/import/open_guitar_pro.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_song.dart';
import 'package:riffster/theme/riffster_theme.dart';

import 'support/app_fonts.dart';
import 'support/sample_score.dart';

/// Opens [score] the way the app does once the file has been read. The
/// song the picker is closed with lands in the returned list.
Future<List<TabSong?>> _choose(
  WidgetTester tester,
  Instrument playing, {
  ImportedScore? score,
}) async {
  final songs = <TabSong?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: riffsterTheme(),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => songs.add(
            await choosePart(
              context,
              score ?? sampleScore(),
              playing: playing,
              fallbackTitle: 'file',
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return songs;
}

Future<void> _press(WidgetTester tester, String part) async {
  final row = find.byKey(Key('part-$part'));
  // The list scrolls, and a tap on a row that is out of view lands on
  // the dimmed page behind the dialog and closes it.
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

List<int> _pitches(TabSong song) => [for (final note in song.notes) note.midi];

void main() {
  testWidgets('on bass, the bass part opens as it is written', (tester) async {
    final songs = await _choose(tester, Instrument.bass);
    expect(find.text('WRITTEN FOR BASS'), findsOneWidget);

    await _press(tester, 'Bass');

    final song = songs.single!;
    expect(song.title, 'Night Drive — Bass');
    expect(song.instrument, Instrument.bass);
    expect(song.bars, hasLength(2));
    expect(
      [for (final note in song.notes) (note.string, note.fret)],
      [(3, 0), (3, 0), (3, 3), (2, 0), (4, 3), (4, 3), (3, 2), (3, 0)],
    );
  });

  testWidgets('on bass, a guitar part opens as a melody on the bass', (
    tester,
  ) async {
    final songs = await _choose(tester, Instrument.bass);
    expect(find.text('PLAY ITS MELODY ON BASS'), findsOneWidget);

    await _press(tester, 'Lead guitar');

    final song = songs.single!;
    expect(song.title, 'Night Drive — Lead guitar on bass');
    expect(song.instrument, Instrument.bass);
    expect(song.bars, hasLength(2));
    // The guitar plays E G A G D E D C up at the top of its neck. On
    // the bass the same names come out two octaves down.
    expect(_pitches(song), [40, 43, 45, 43, 38, 40, 38, 36]);
    final bass = Instrument.bass.openStringMidi;
    for (final note in song.notes) {
      expect(bass[note.string - 1] + note.fret, note.midi);
    }
  });

  testWidgets('High puts the melody an octave up', (tester) async {
    final songs = await _choose(tester, Instrument.bass);

    await tester.tap(find.byKey(const Key('register-high')));
    await tester.pump();
    await _press(tester, 'Lead guitar');

    expect(_pitches(songs.single!), [52, 55, 57, 55, 50, 52, 50, 48]);
    expect(songs.single!.title, 'Night Drive — Lead guitar on bass, high');
  });

  testWidgets('a strummed part gives the top note of each chord', (
    tester,
  ) async {
    final songs = await _choose(tester, Instrument.bass);

    await _press(tester, 'Rhythm guitar');

    // Four chords of four notes each became four single notes.
    expect(songs.single!.notes.map((note) => note.timeMs), [
      0,
      1200,
      2400,
      3600,
    ]);
  });

  testWidgets('a voice has no strings, and still gives a melody', (
    tester,
  ) async {
    final songs = await _choose(tester, Instrument.bass);

    await _press(tester, 'Vocals');

    expect(songs.single!.notes, hasLength(8));
    expect(songs.single!.instrument, Instrument.bass);
  });

  testWidgets('a five-string part is listed, and cannot be pressed', (
    tester,
  ) async {
    final songs = await _choose(tester, Instrument.bass);
    expect(find.text('5 strings · not supported yet'), findsOneWidget);

    await _press(tester, 'Low bass');

    // Still open, and nothing was chosen.
    expect(find.text('Which part is yours?'), findsOneWidget);
    expect(songs, isEmpty);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(songs.single, isNull);
  });

  testWidgets('on guitar, only the guitar parts can be chosen', (tester) async {
    final songs = await _choose(tester, Instrument.guitar);

    expect(find.text('WRITTEN FOR GUITAR'), findsOneWidget);
    expect(find.text('PLAY ITS MELODY ON BASS'), findsNothing);
    expect(
      find.text('A bass part · switch to Bass to play it'),
      findsOneWidget,
    );

    await _press(tester, 'Bass');
    expect(songs, isEmpty);

    await _press(tester, 'Rhythm guitar');
    expect(songs.single!.title, 'Night Drive — Rhythm guitar');
    expect(songs.single!.instrument, Instrument.guitar);
  });

  testWidgets('a file with one part for this instrument opens without asking', (
    tester,
  ) async {
    final whole = sampleScore();
    final onlyBass = ImportedScore(
      title: whole.title,
      tempoBpm: whole.tempoBpm,
      tracks: [whole.tracks.first],
    );

    final songs = await _choose(tester, Instrument.bass, score: onlyBass);

    expect(find.text('Which part is yours?'), findsNothing);
    expect(songs.single!.title, 'Night Drive — Bass');
  });

  testWidgets('a file with one part for the other instrument still asks', (
    tester,
  ) async {
    final whole = sampleScore();
    final onlyBass = ImportedScore(
      title: whole.title,
      tempoBpm: whole.tempoBpm,
      tracks: [whole.tracks.first],
    );

    final songs = await _choose(tester, Instrument.guitar, score: onlyBass);

    // Opening it on the bass staff would change instruments without a
    // word. The picker says what the part is instead.
    expect(find.text('Which part is yours?'), findsOneWidget);
    expect(songs, isEmpty);
  });

  testWidgets('the picker fits the window with every kind of part in it', (
    tester,
  ) async {
    // A list too wide or too tall fails this test by itself: Flutter
    // reports the overflow as an error.
    await tester.runAsync(loadAppFonts);
    tester.view.physicalSize = const Size(1264, 681);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _choose(tester, Instrument.bass);

    expect(find.text('Cancel'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
