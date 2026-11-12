import 'dart:collection';

import '../models/tab_note.dart';
import '../models/tab_song.dart';
import 'barre.dart';
import 'chord_name.dart';
import 'score_note.dart';

/// Every note that starts at one time. A chord is one moment, and so is
/// a single note. The clock judges a moment as a whole.
class SongMoment {
  const SongMoment({
    required this.timeMs,
    required this.notes,
    this.chordName,
    this.barre,
  });

  final int timeMs;
  final List<TabNote> notes;

  /// Worked out once here, so the stage does not name the same chord
  /// again on every frame.
  final String? chordName;
  final IndexBarre? barre;
}

/// A song laid out in time order, with the questions a run keeps asking
/// answered by a search instead of a walk through every note.
///
/// A long file is thousands of notes. The stage only needs the few near
/// the playhead, sixty times a second. Sorting once and then cutting the
/// list in half until the spot is found (a binary search) keeps that cost
/// the same for a ten-second riff and a ten-minute song.
class SongTimeline {
  SongTimeline(this.song)
    : moments = _momentsOf(song),
      lengthMs = song.lengthMs,
      longestNoteMs = song.notes.fold(
        0,
        (longest, note) =>
            note.durationMs > longest ? note.durationMs : longest,
      );

  final TabSong song;
  final List<SongMoment> moments;
  final int lengthMs;

  /// How far back a sustain tail can reach. The stage looks this far
  /// behind the left edge so a long note is not dropped while it rings.
  final int longestNoteMs;

  int get firstNoteMs => moments.isEmpty ? 0 : moments.first.timeMs;

  double get beatMs => 60000 / song.tempoBpm;

  /// One bar of four beats: the count before the first note.
  int get countInMs => (beatMs * 4).round();

  /// Where the clock waits before Play. One bar ahead of the first note,
  /// so that note is off to the right and not already on the playhead.
  int get restMs => firstNoteMs - countInMs;

  /// Index of the first moment at or after [timeMs]. [moments].length
  /// when every moment is earlier.
  int firstAtOrAfter(num timeMs) {
    var low = 0;
    var high = moments.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (moments[middle].timeMs < timeMs) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  /// The moment closest to [timeMs], when it is still this beat.
  ///
  /// Null when the playhead is between phrases. Only the moment just
  /// before and the one just after can be the closest, so those two are
  /// the only ones compared.
  SongMoment? momentNear(num timeMs, {double speed = 1}) {
    final after = firstAtOrAfter(timeMs);
    SongMoment? best;
    var bestDistance = sameBeatMs * speed;
    for (final index in [after - 1, after]) {
      if (index < 0 || index >= moments.length) continue;
      final distance = (moments[index].timeMs - timeMs).abs();
      if (distance <= bestDistance) {
        bestDistance = distance.toDouble();
        best = moments[index];
      }
    }
    return best;
  }

  /// A gap most of the song's notes are at least this far apart by, or
  /// null for a song with fewer than two moments.
  ///
  /// The fifth-smallest gap out of every hundred is used, not the very
  /// smallest. One grace note should not set the spacing for a slow song.
  int? get tightGapMs {
    if (moments.length < 2) return null;
    final gaps = [
      for (var i = 1; i < moments.length; i++)
        moments[i].timeMs - moments[i - 1].timeMs,
    ]..sort();
    return gaps[(gaps.length * 0.05).floor()];
  }
}

List<SongMoment> _momentsOf(TabSong song) {
  // A tree map hands its keys back in order, so the moments come out
  // sorted by time whatever order the file listed the notes in.
  final byTime = SplayTreeMap<int, List<TabNote>>();
  for (final note in song.notes) {
    byTime.putIfAbsent(note.timeMs, () => []).add(note);
  }
  return [
    for (final entry in byTime.entries)
      SongMoment(
        timeMs: entry.key,
        notes: entry.value,
        chordName: chordName(entry.value, instrument: song.instrument),
        barre: indexBarre(entry.value),
      ),
  ];
}
