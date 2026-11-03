import 'fretting_finger.dart';

/// One sounded note from a tab.
///
/// [string] follows the tab staff: 1 is the top line (high E on a
/// standard guitar) and 6 is the bottom line (low E).
class TabNote {
  const TabNote({
    required this.timeMs,
    required this.string,
    required this.fret,
    required this.durationMs,
    required this.midi,
    this.finger,
  });

  /// When this note should be played, from the start of the song.
  final int timeMs;

  final int string;
  final int fret;

  /// How long the note lasts. The scroll uses this only as a hint for now.
  final int durationMs;

  /// MIDI note number. The iRig score will compare a pitch against this.
  final int midi;

  /// Null on an open string. The same fret can be a different finger
  /// higher up the neck, so this is stored on the note rather than guessed.
  final FrettingFinger? finger;
}
