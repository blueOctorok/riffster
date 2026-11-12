import 'instrument.dart';
import 'tab_note.dart';

/// One bar of a song, in song time. [beats] is how many beats it holds.
class SongBar {
  const SongBar({required this.startMs, required this.endMs, this.beats = 4});

  final int startMs;
  final int endMs;
  final int beats;
}

/// A song the stage can scroll.
///
/// This is the list a Guitar Pro file becomes. The screen never
/// reads a .gp file itself.
class TabSong {
  const TabSong({
    required this.title,
    required this.tempoBpm,
    required this.notes,
    this.instrument = Instrument.guitar,
    this.bars = const [],
  });

  final String title;
  final int tempoBpm;
  final List<TabNote> notes;

  /// Whose strings the notes sit on. The staff draws this many lines.
  final Instrument instrument;

  /// Where the bar lines fall. Empty when the song has no steady bars,
  /// such as a chord lane whose chords ring for any length you drag.
  final List<SongBar> bars;

  /// End of the last note, in milliseconds.
  int get lengthMs {
    var end = 0;
    for (final note in notes) {
      final noteEnd = note.timeMs + note.durationMs;
      if (noteEnd > end) end = noteEnd;
    }
    return end;
  }

  /// This song with bars of four beats at its one tempo, from zero
  /// through the last note.
  ///
  /// A song we write by rule has no file to say where its bars are, so
  /// the tempo says it. The last bar is whole even when the notes stop
  /// inside it.
  TabSong withCommonTimeBars() {
    final barMs = 4 * 60000 / tempoBpm;
    final count = (lengthMs / barMs).ceil();
    return TabSong(
      title: title,
      tempoBpm: tempoBpm,
      notes: notes,
      instrument: instrument,
      bars: [
        for (var bar = 0; bar < count; bar++)
          SongBar(
            startMs: (bar * barMs).round(),
            endMs: ((bar + 1) * barMs).round(),
          ),
      ],
    );
  }
}
