import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/data/library_item.dart';
import 'package:riffster/data/originals.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/music/place_on_neck.dart';

void main() {
  test('the app comes with riffs, melodies, and old tunes', () {
    int count(SongSource source) {
      return builtInSongs.where((item) => item.source == source).length;
    }

    // A dozen riffs and three melodies.
    expect(count(SongSource.original), 15);
    expect(count(SongSource.oldTune), 3);
    expect(count(SongSource.yours), 0);
  });

  test('no two songs share a name', () {
    final ids = [for (final item in builtInSongs) item.id];

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every song is whole bars of notes on the bass neck', () {
    final bass = Instrument.bass;
    for (final item in builtInSongs) {
      final song = item.song;
      final reason = song.title;
      expect(song.instrument, bass, reason: reason);
      expect(song.notes, isNotEmpty, reason: reason);
      expect(item.about, isNotEmpty, reason: reason);
      // The last note ends inside the last bar, so nothing spills.
      expect(song.lengthMs, lessThanOrEqualTo(song.bars.last.endMs));
      expect(song.lengthMs, greaterThan(song.bars.last.startMs));
      for (final note in song.notes) {
        expect(note.fret, inInclusiveRange(0, topPlacedFret), reason: reason);
        expect(
          bass.openStringMidi[note.string - 1] + note.fret,
          note.midi,
          reason: reason,
        );
      }
    }
  });

  test('a riff stays where a beginner can reach it', () {
    // The melodies go up the neck on purpose. Everything else should
    // sit in the first seven frets.
    const melodies = {'Open Window', 'Paper Boats', 'Last Train Out'};
    for (final item in builtInSongs) {
      if (melodies.contains(item.song.title)) continue;
      final highest = item.song.notes
          .map((note) => note.fret)
          .reduce((a, b) => a > b ? a : b);
      expect(highest, lessThanOrEqualTo(7), reason: item.song.title);
    }
  });
}
