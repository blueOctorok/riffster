import 'package:riffster/import/imported_score.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/models/tab_song.dart';

/// Quarter notes at 100 bpm, one for each entry. An entry is the notes
/// that sound together, each as (string, fret).
List<TabNote> _quarters(List<int> tuning, List<List<(int, int)>> beats) {
  return [
    for (var beat = 0; beat < beats.length; beat++)
      for (final (string, fret) in beats[beat])
        TabNote(
          timeMs: beat * 600,
          string: string,
          fret: fret,
          durationMs: 500,
          midi: tuning[string - 1] + fret,
        ),
  ];
}

/// A made-up file with one of every kind of part the picker has to
/// sort: a bass, two guitars, a voice, and a five-string bass.
ImportedScore sampleScore() {
  final guitar = Instrument.guitar.openStringMidi;
  final bass = Instrument.bass.openStringMidi;
  const fiveString = [43, 38, 33, 28, 23];
  return ImportedScore(
    title: 'Night Drive',
    tempoBpm: 100,
    bars: const [
      SongBar(startMs: 0, endMs: 2400),
      SongBar(startMs: 2400, endMs: 4800),
    ],
    tracks: [
      ImportedTrack(
        name: 'Bass',
        tuning: bass,
        notes: _quarters(bass, [
          [(3, 0)],
          [(3, 0)],
          [(3, 3)],
          [(2, 0)],
          [(4, 3)],
          [(4, 3)],
          [(3, 2)],
          [(3, 0)],
        ]),
      ),
      ImportedTrack(
        name: 'Lead guitar',
        tuning: guitar,
        notes: _quarters(guitar, [
          [(1, 0)],
          [(1, 3)],
          [(1, 5)],
          [(1, 3)],
          [(2, 3)],
          [(1, 0)],
          [(2, 3)],
          [(2, 1)],
        ]),
      ),
      ImportedTrack(
        name: 'Rhythm guitar',
        tuning: guitar,
        notes: _quarters(guitar, [
          [(5, 0), (4, 2), (3, 2), (2, 1)],
          [],
          [(5, 0), (4, 2), (3, 2), (2, 1)],
          [],
          [(6, 3), (5, 2), (4, 0), (3, 0)],
          [],
          [(6, 3), (5, 2), (4, 0), (3, 0)],
          [],
        ]),
      ),
      ImportedTrack(
        name: 'Vocals',
        tuning: const [],
        notes: [
          // A part with no strings: pitch and time are all it has.
          for (final (beat, midi) in [69, 72, 76, 74, 72, 71, 69, 67].indexed)
            TabNote(
              timeMs: beat * 600,
              string: 0,
              fret: 0,
              durationMs: 500,
              midi: midi,
            ),
        ],
      ),
      ImportedTrack(
        name: 'Low bass',
        tuning: fiveString,
        notes: _quarters(fiveString, [
          [(5, 0)],
          [(5, 3)],
          [(4, 0)],
          [(4, 3)],
        ]),
      ),
    ],
  );
}
