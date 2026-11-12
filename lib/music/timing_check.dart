/// The timing check plays clicks and listens for a note on each one.
/// The first few are only to get ready.
const timingCheckLeadIn = 4;
const timingCheckClicks = 8;

/// 100 beats a minute. Slow enough to be easy, quick enough to keep a
/// pulse.
const timingCheckBeatMs = 600.0;

/// Fewer notes than this near a click is not enough to trust.
const _fewestNotes = 5;

/// When the middle half of the notes is spread wider than this, the
/// player was not locked to the click and the answer means nothing.
const _widestSpreadMs = 80.0;

/// A delay outside this range is a mistake, not a measurement.
const _soonestMs = -60.0;
const _latestMs = 250.0;

/// How long after a click its note arrives, in milliseconds, or null
/// when the notes were too few or too uneven to say.
///
/// Each click is paired with the note nearest to it. The answer is
/// the middle gap, not the average. One fumbled note out of eight
/// drags an average a long way and does not move the middle at all.
double? measuredDelayMs({
  required List<double> clicksMs,
  required List<double> notesMs,
}) {
  final gaps = <double>[];
  for (final click in clicksMs) {
    double? nearest;
    for (final note in notesMs) {
      final gap = note - click;
      if (gap.abs() >= timingCheckBeatMs / 2) continue;
      if (nearest == null || gap.abs() < nearest.abs()) nearest = gap;
    }
    if (nearest != null) gaps.add(nearest);
  }
  if (gaps.length < _fewestNotes) return null;

  gaps.sort();
  final spread = gaps[gaps.length * 3 ~/ 4] - gaps[gaps.length ~/ 4];
  if (spread > _widestSpreadMs) return null;

  final middle = gaps.length ~/ 2;
  final delay = gaps.length.isOdd
      ? gaps[middle]
      : (gaps[middle - 1] + gaps[middle]) / 2;
  return delay < _soonestMs || delay > _latestMs ? null : delay;
}
