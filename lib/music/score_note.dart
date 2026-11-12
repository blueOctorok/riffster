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

/// Scores one sound against the notes at a single moment.
///
/// The mic cannot see the fretboard, so a single note is judged by its MIDI
/// pitch. The same pitch on another string still hits. A chord is two or
/// more notes at that moment: only the timing counts, until single notes
/// are fair. An empty moment is a miss.
///
/// [speed] is how fast the song clock runs against a real clock. Practice
/// at half speed stretches the song, not the player's reflexes, so the gap
/// is turned back into real milliseconds before it is judged.
ScoreMark scoreMoment({
  required List<TabNote> written,
  required num playedAtMs,
  int? playedMidi,
  double speed = 1,
}) {
  if (written.isEmpty) return ScoreMark.miss;

  final dueAtMs = written.first.timeMs;
  final timing = _timing((playedAtMs - dueAtMs) / speed);
  if (timing == ScoreMark.miss) return ScoreMark.miss;
  if (written.length >= 2) return timing;

  if (playedMidi == null || playedMidi != written.first.midi) {
    return ScoreMark.miss;
  }
  return timing;
}

ScoreMark _timing(double deltaMs) {
  final distance = deltaMs.abs();
  if (distance <= onTimeMs) return ScoreMark.hit;
  if (distance > sameBeatMs) return ScoreMark.miss;
  return deltaMs < 0 ? ScoreMark.early : ScoreMark.late;
}

/// The word shown for a mark.
String markLabel(ScoreMark mark) {
  return switch (mark) {
    ScoreMark.hit => 'Hit',
    ScoreMark.miss => 'Miss',
    ScoreMark.early => 'Early',
    ScoreMark.late => 'Late',
  };
}

/// True once a moment has been played: on time, early, or late.
bool isPlayed(ScoreMark? mark) => mark != null && mark != ScoreMark.miss;

/// The mark a moment keeps when a new sound is judged against it.
///
/// A hit, an early, or a late stays. A miss can still become one of those
/// if the real pluck arrives a little late.
ScoreMark keepBetterMark(ScoreMark? existing, ScoreMark next) {
  return isPlayed(existing) ? existing! : next;
}

/// True when the playhead has left a moment too far behind to play it.
///
/// Silence has no pitch, so the clock is what says a note went by
/// unplayed. [speed] is the same real-time correction as in [scoreMoment].
bool windowHasPassed({
  required int dueAtMs,
  required num positionMs,
  double speed = 1,
}) {
  return (positionMs - dueAtMs) / speed > sameBeatMs;
}
