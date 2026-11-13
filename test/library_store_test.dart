import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/data/demo_song.dart';
import 'package:riffster/data/library_item.dart';
import 'package:riffster/data/library_store.dart';
import 'package:riffster/data/originals.dart';
import 'package:riffster/data/song_file.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/models/tab_song.dart';

TabSong _song(String title, {Instrument instrument = Instrument.bass}) {
  return TabSong(
    title: title,
    tempoBpm: 100,
    instrument: instrument,
    bars: const [SongBar(startMs: 0, endMs: 2400)],
    notes: const [
      TabNote(timeMs: 0, string: 4, fret: 0, durationMs: 500, midi: 28),
      TabNote(
        timeMs: 600,
        string: 4,
        fret: 3,
        durationMs: 500,
        midi: 31,
        finger: FrettingFinger.ring,
      ),
    ],
  );
}

List<LibraryItem> _yours(LibraryStore library) {
  return [
    for (final item in library.items)
      if (item.source == SongSource.yours) item,
  ];
}

/// A folder that is deleted when the test ends.
Future<Directory> _tempFolder() async {
  final folder = await Directory.systemTemp.createTemp('riffster-library');
  addTearDown(() => folder.delete(recursive: true));
  return folder;
}

void main() {
  test('a song survives being written to a file and read back', () {
    final song = warmUpFor(Instrument.bass);
    // Through text and back, as it would go to disk.
    final read = songFromJson(jsonDecode(jsonEncode(songToJson(song))))!;

    expect(read.title, song.title);
    expect(read.instrument, song.instrument);
    expect(read.tempoBpm, song.tempoBpm);
    expect(read.bars.map((bar) => (bar.startMs, bar.endMs, bar.beats)), [
      for (final bar in song.bars) (bar.startMs, bar.endMs, bar.beats),
    ]);
    expect(read.notes, hasLength(song.notes.length));
    for (var i = 0; i < song.notes.length; i++) {
      final was = song.notes[i];
      final now = read.notes[i];
      expect(
        (
          now.timeMs,
          now.string,
          now.fret,
          now.durationMs,
          now.midi,
          now.finger,
        ),
        (
          was.timeMs,
          was.string,
          was.fret,
          was.durationMs,
          was.midi,
          was.finger,
        ),
      );
    }
  });

  test('a file that is not a song reads as nothing', () {
    final good = songToJson(_song('Good'));

    expect(songFromJson('not a map'), isNull);
    expect(songFromJson({...good, 'instrument': 'banjo'}), isNull);
    expect(songFromJson({...good}..remove('notes')), isNull);
    // One note cut short.
    expect(
      songFromJson({
        ...good,
        'notes': [
          [0, 4, 0],
        ],
      }),
      isNull,
    );
  });

  test('the library opens with the songs that come with the app', () {
    final library = LibraryStore.inMemory();

    expect(library.items, hasLength(builtInSongs.length));
    expect(_yours(library), isEmpty);
  });

  test('a saved song is listed first, and saving it again replaces it', () {
    final library = LibraryStore.inMemory();
    library.save(_song('Zebra'));
    library.save(_song('Apple'));
    library.save(_song('Zebra'));

    expect(library.items.take(2).map((item) => item.song.title), [
      'Apple',
      'Zebra',
    ]);
    expect(_yours(library), hasLength(2));
    // The same title on the other instrument is another song.
    library.save(_song('Zebra', instrument: Instrument.guitar));
    expect(_yours(library), hasLength(3));
  });

  test('the best score is kept for each speed', () {
    final library = LibraryStore.inMemory();
    final id = libraryIdOf(_song('Mine'));
    library.save(_song('Mine'));
    expect(library.bestScores(id), isEmpty);

    library.recordRun(id, speed: 0.7, accuracy: 0.80);
    library.recordRun(id, speed: 1, accuracy: 0.55);
    // Better at 70%, and worse at full speed.
    library.recordRun(id, speed: 0.7, accuracy: 0.96);
    library.recordRun(id, speed: 1, accuracy: 0.40);

    // Fastest first.
    expect(library.bestScores(id), [
      (speedPercent: 100, onTimePercent: 55),
      (speedPercent: 70, onTimePercent: 96),
    ]);
  });

  test('a song that came with the app keeps scores too', () {
    final library = LibraryStore.inMemory();
    final id = builtInSongs.first.id;

    library.recordRun(id, speed: 0.5, accuracy: 1);

    expect(library.bestScores(id), [(speedPercent: 50, onTimePercent: 100)]);
  });

  test('a song that is not in the library keeps no score', () {
    final library = LibraryStore.inMemory();

    library.recordRun('warm-up-bass', speed: 1, accuracy: 1);

    expect(library.bestScores('warm-up-bass'), isEmpty);
  });

  test('removing a song takes its scores, and leaves the built-in ones', () {
    final library = LibraryStore.inMemory();
    library.save(_song('Mine'));
    final mine = _yours(library).single;
    library.recordRun(mine.id, speed: 1, accuracy: 0.9);

    library.remove(mine);
    library.remove(builtInSongs.first);

    expect(_yours(library), isEmpty);
    expect(library.bestScores(mine.id), isEmpty);
    expect(library.items, hasLength(builtInSongs.length));
  });

  test('songs and scores are still there when the app opens again', () async {
    final folder = await _tempFolder();
    final first = await LibraryStore.openIn(folder);
    final id = libraryIdOf(_song('Mine'));
    await first.save(_song('Mine'));
    await first.save(_song('Gone soon'));
    await first.recordRun(id, speed: 0.7, accuracy: 0.9);
    await first.recordRun(builtInSongs.first.id, speed: 1, accuracy: 0.5);
    await first.remove(
      _yours(first).firstWhere((item) => item.song.title == 'Gone soon'),
    );

    final second = await LibraryStore.openIn(folder);

    expect(_yours(second).single.song.title, 'Mine');
    expect(_yours(second).single.song.notes.last.finger, FrettingFinger.ring);
    expect(second.bestScores(id), [(speedPercent: 70, onTimePercent: 90)]);
    expect(second.bestScores(builtInSongs.first.id), [
      (speedPercent: 100, onTimePercent: 50),
    ]);
    // One file per song, and one for the scores.
    expect(
      folder.listSync().map((file) => file.uri.pathSegments.last).toSet(),
      {'$id.json', 'scores.json'},
    );
  });

  test('a damaged file is skipped and the rest still open', () async {
    final folder = await _tempFolder();
    final first = await LibraryStore.openIn(folder);
    await first.save(_song('Mine'));
    await File('${folder.path}/broken.json').writeAsString('{"title": ');
    await File('${folder.path}/scores.json').writeAsString('not json');

    final second = await LibraryStore.openIn(folder);

    expect(_yours(second).single.song.title, 'Mine');
    expect(second.bestScores(libraryIdOf(_song('Mine'))), isEmpty);
  });
}
