import '../models/fretting_finger.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';

/// A short original phrase so the scroll can be seen before import exists.
///
/// Quarter notes at 100 bpm are 600 ms apart. MIDI numbers match a
/// standard-tuned guitar so scoring can use them later without a rewrite.
const demoSong = TabSong(
  title: 'Warm-up',
  tempoBpm: 100,
  notes: [
    TabNote(timeMs: 0, string: 3, fret: 0, durationMs: 500, midi: 55),
    TabNote(
      timeMs: 600,
      string: 3,
      fret: 2,
      durationMs: 500,
      midi: 57,
      finger: FrettingFinger.middle,
    ),
    TabNote(timeMs: 1200, string: 2, fret: 0, durationMs: 500, midi: 59),
    TabNote(
      timeMs: 1800,
      string: 2,
      fret: 1,
      durationMs: 500,
      midi: 60,
      finger: FrettingFinger.indexFinger,
    ),
    TabNote(timeMs: 2400, string: 1, fret: 0, durationMs: 500, midi: 64),
    TabNote(
      timeMs: 3000,
      string: 1,
      fret: 3,
      durationMs: 500,
      midi: 67,
      finger: FrettingFinger.pinky,
    ),
    TabNote(
      timeMs: 3600,
      string: 4,
      fret: 2,
      durationMs: 500,
      midi: 52,
      finger: FrettingFinger.ring,
    ),
    TabNote(timeMs: 3600, string: 3, fret: 0, durationMs: 500, midi: 55),
  ],
);
