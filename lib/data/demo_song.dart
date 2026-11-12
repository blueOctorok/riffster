import '../models/fretting_finger.dart';
import '../models/instrument.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';

/// The phrase a new window opens on, for the instrument in hand.
TabSong warmUpFor(Instrument instrument) {
  return switch (instrument) {
    Instrument.guitar => _guitarWarmUp,
    Instrument.bass => _bassWarmUp,
  };
}

/// A short original phrase, so the stage has something to play before a
/// file is opened. Quarter notes at 100 bpm are 600 ms apart.
final _guitarWarmUp = const TabSong(
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
).withCommonTimeBars();

/// An original three-bar line for a four-string bass, in E minor. It walks
/// up through the open strings, comes back down, and lands on the low E.
/// Open strings are E1 = 28, A1 = 33, D2 = 38. Fret 2 is the middle
/// finger and fret 3 is the ring, one finger per fret from the first.
final _bassWarmUp = const TabSong(
  title: 'Warm-up',
  tempoBpm: 100,
  instrument: Instrument.bass,
  notes: [
    TabNote(timeMs: 0, string: 4, fret: 0, durationMs: 500, midi: 28),
    TabNote(
      timeMs: 600,
      string: 4,
      fret: 3,
      durationMs: 500,
      midi: 31,
      finger: FrettingFinger.ring,
    ),
    TabNote(timeMs: 1200, string: 3, fret: 0, durationMs: 500, midi: 33),
    TabNote(
      timeMs: 1800,
      string: 3,
      fret: 2,
      durationMs: 500,
      midi: 35,
      finger: FrettingFinger.middle,
    ),
    TabNote(timeMs: 2400, string: 2, fret: 0, durationMs: 500, midi: 38),
    TabNote(
      timeMs: 3000,
      string: 2,
      fret: 2,
      durationMs: 500,
      midi: 40,
      finger: FrettingFinger.middle,
    ),
    TabNote(timeMs: 3600, string: 2, fret: 0, durationMs: 500, midi: 38),
    TabNote(
      timeMs: 4200,
      string: 3,
      fret: 2,
      durationMs: 500,
      midi: 35,
      finger: FrettingFinger.middle,
    ),
    TabNote(timeMs: 4800, string: 3, fret: 0, durationMs: 500, midi: 33),
    TabNote(
      timeMs: 5400,
      string: 4,
      fret: 3,
      durationMs: 500,
      midi: 31,
      finger: FrettingFinger.ring,
    ),
    TabNote(timeMs: 6000, string: 4, fret: 0, durationMs: 1200, midi: 28),
  ],
).withCommonTimeBars();
