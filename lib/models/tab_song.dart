import 'tab_note.dart';

/// A song the sideways tab can scroll.
///
/// This is the list a Guitar Pro file becomes. The screen never
/// reads a .gp file itself.
class TabSong {
  const TabSong({
    required this.title,
    required this.tempoBpm,
    required this.notes,
  });

  final String title;
  final int tempoBpm;
  final List<TabNote> notes;

  /// End of the last note, in milliseconds.
  int get lengthMs {
    var end = 0;
    for (final note in notes) {
      final noteEnd = note.timeMs + note.durationMs;
      if (noteEnd > end) end = noteEnd;
    }
    return end;
  }
}
