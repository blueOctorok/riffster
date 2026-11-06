import '../models/tab_note.dart';

/// What the playhead decided about one sound from the guitar.
enum ScoreMark { hit, miss, early, late }

/// Close enough to the written time to count as on time.
///
/// Eighty milliseconds is wider than a machine and tighter than a loose
/// strum. The iRig will tell us if this window needs to move.
const onTimeMs = 80;

/// Still the same beat, but not on time. Farther out is a miss, not a late
/// note, because that sound belongs to a different moment.
const sameBeatMs = 250;

/// The written notes closest to [positionMs], when they are still this beat.
///
/// Empty when the playhead is between phrases. The caller scores that as a miss.
List<TabNote> notesNear(List<TabNote> notes, int positionMs) {
  int? bestTime;
  var bestDistance = sameBeatMs + 1;
  for (final note in notes) {
    final distance = (note.timeMs - positionMs).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestTime = note.timeMs;
    }
  }
  if (bestTime == null) return const [];
  return [
    for (final note in notes)
      if (note.timeMs == bestTime) note,
  ];
}

/// Scores one sound against the notes at a single moment.
///
/// The mic cannot see the fretboard, so a single note is judged by its MIDI
/// pitch. The same pitch on another string still hits. A chord is two or
/// more notes at that moment: only the timing counts, until single notes
/// are fair. An empty moment is a miss.
ScoreMark scoreMoment({
  required List<TabNote> written,
  required int playedAtMs,
  int? playedMidi,
}) {
  if (written.isEmpty) return ScoreMark.miss;

  final dueAtMs = written.first.timeMs;
  final timing = _timing(playedAtMs - dueAtMs);
  if (timing == ScoreMark.miss) return ScoreMark.miss;
  if (written.length >= 2) return timing;

  if (playedMidi == null || playedMidi != written.first.midi) {
    return ScoreMark.miss;
  }
  return timing;
}

ScoreMark _timing(int deltaMs) {
  final distance = deltaMs.abs();
  if (distance <= onTimeMs) return ScoreMark.hit;
  if (distance > sameBeatMs) return ScoreMark.miss;
  return deltaMs < 0 ? ScoreMark.early : ScoreMark.late;
}

/// Paints [mark] onto the notes that were just judged.
///
/// A hit, an early, or a late stays. A miss can still become one of those
/// if the real pluck arrives a little late. The microphone never reports
/// silence, so a miss from waiting is written by [expireUnplayed].
void applyPlayedMark(
  Map<TabNote, ScoreMark> marks,
  List<TabNote> written,
  ScoreMark mark,
) {
  for (final note in written) {
    final existing = marks[note];
    if (existing == ScoreMark.hit ||
        existing == ScoreMark.early ||
        existing == ScoreMark.late) {
      continue;
    }
    marks[note] = mark;
  }
}

/// A note the playhead has left behind, with no pluck in its window, is a miss.
///
/// Silence has no pitch. The clock is what says the note went by unplayed.
void expireUnplayed(
  Map<TabNote, ScoreMark> marks,
  List<TabNote> notes,
  int positionMs,
) {
  for (final note in notes) {
    if (marks.containsKey(note)) continue;
    if (positionMs - note.timeMs > sameBeatMs) {
      marks[note] = ScoreMark.miss;
    }
  }
}
