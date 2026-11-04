import '../models/tab_note.dart';
import '../models/tab_song.dart';
import 'chord_book.dart';

/// Open-string MIDI numbers, staff string 1 (high e) through string 6.
const _openMidi = [64, 59, 55, 50, 45, 40];

/// How long one chord sits before the next one in a change.
const _stepMs = 2000;

/// The chord sits this far ahead of the playhead, so the line is not
/// drawn through the dots while you are looking at the shape.
const _leadMs = 500;

/// Original chord practice. Every grip is the one the importer uses, so
/// a finger learned here is the finger a song will show. The last step is
/// a short change we wrote. No copyrighted song is included.
final chordCourse = <TabSong>[
  _one(openEm, 'Em'),
  _one(openE, 'E'),
  _one(openAm, 'Am'),
  _one(openC, 'C'),
  _one(openG, 'G'),
  _one(openD, 'D'),
  _one(openA, 'A'),
  _one(openDm, 'Dm'),
  _one(openEm7, 'Em7'),
  _one(fSharp7, 'F#7'),
  _one(openBm, 'Bm'),
  _one(barreBm, 'Bm barre'),
  _change('G · D · Em · C', [openG, openD, openEm, openC]),
];

TabSong _one(ChordGrip grip, String title) {
  return TabSong(title: title, tempoBpm: 60, notes: _notes(grip, _leadMs));
}

TabSong _change(String title, List<ChordGrip> grips) {
  return TabSong(
    title: title,
    tempoBpm: 60,
    notes: [
      for (var i = 0; i < grips.length; i++)
        ..._notes(grips[i], _leadMs + i * _stepMs),
    ],
  );
}

List<TabNote> _notes(ChordGrip grip, int timeMs) {
  return [
    for (var string = 1; string <= 6; string++)
      if (grip.frets[string - 1] != null)
        TabNote(
          timeMs: timeMs,
          string: string,
          fret: grip.frets[string - 1]!,
          durationMs: _stepMs,
          midi: _openMidi[string - 1] + grip.frets[string - 1]!,
          finger: grip.frets[string - 1] == 0 ? null : grip.fingerOn(string),
        ),
  ];
}
