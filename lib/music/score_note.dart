import '../models/tab_note.dart';

/// What the playhead decided about one sound from the guitar.
enum ScoreMark { hit, miss, early, late }

/// How far from the note's centre still counts as on time, in song
/// milliseconds. This is the time a note takes to reach the line from
/// its first touch, so striking as the gold line meets the circle is on
/// time, and so is striking while the line is anywhere on it. Song time
/// keeps that circle the same size when the song is slowed.
const onTimeMs = 120;

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
/// The window is song time. At half speed the note crosses the line in
/// twice as many real milliseconds, and it is still the same circle, so
/// the same part of it counts.
ScoreMark scoreMoment({
  required List<TabNote> written,
  required num playedAtMs,
  int? playedMidi,
  int windowMs = onTimeMs,
}) {
  if (written.isEmpty) return ScoreMark.miss;

  final dueAtMs = written.first.timeMs;
  final timing = _timing((playedAtMs - dueAtMs).toDouble(), windowMs: windowMs);
  if (timing == ScoreMark.miss) return ScoreMark.miss;
  if (written.length >= 2) return timing;

  if (playedMidi == null || playedMidi != written.first.midi) {
    return ScoreMark.miss;
  }
  return timing;
}

ScoreMark _timing(double deltaMs, {required int windowMs}) {
  final distance = deltaMs.abs();
  if (distance <= windowMs) return ScoreMark.hit;
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
/// unplayed. The same song-time window as [scoreMoment], so a slowed
/// song keeps the note open for as long as it is on screen.
bool windowHasPassed({required int dueAtMs, required num positionMs}) {
  return positionMs - dueAtMs > sameBeatMs;
}
