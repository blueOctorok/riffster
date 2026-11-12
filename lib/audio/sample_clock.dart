import 'dart:math' as math;

/// Says when a given sample was heard, on the app's own clock.
///
/// Sound reaches the app in chunks, and a chunk can sit in a queue
/// while the screen is busy. Timing a pluck by when its chunk showed
/// up would make the score depend on what the screen was doing.
///
/// Samples are the steadier clock. The sound card hands them out at
/// an exact rate, so sample 48,000 was heard one second after sample
/// 0. All that is missing is where sample 0 sits on the app's clock.
///
/// A chunk can arrive late and never early. So the chunk that got
/// through quickest is the honest one, and the rest are that plus a
/// delay. This keeps the quickest arrival of the last few seconds.
/// Only the last few, because the sound card's clock and the PC's
/// clock drift apart by a few milliseconds a minute.
class SampleClock {
  SampleClock(this.sampleRate);

  static const _memoryMicros = 2000000;

  final int sampleRate;

  // The quickest arrival is kept in two buckets that take turns, so
  // an old one can be dropped without keeping every arrival.
  var _newer = double.infinity;
  var _older = double.infinity;
  var _newerSince = 0;

  /// A chunk just arrived. [samplesHeard] counts every sample so far,
  /// this chunk included, and [atMicros] is the app clock right now.
  void arrived({required int samplesHeard, required int atMicros}) {
    if (atMicros - _newerSince >= _memoryMicros) {
      _older = _newer;
      _newer = double.infinity;
      _newerSince = atMicros;
    }
    _newer = math.min(_newer, atMicros - _microsOf(samplesHeard));
  }

  /// The app-clock time, in microseconds, that [sample] was heard.
  double microsAt(int sample) => _microsOf(sample) + math.min(_newer, _older);

  double _microsOf(int samples) => samples * 1e6 / sampleRate;
}
