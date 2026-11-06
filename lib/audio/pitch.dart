import 'dart:math' as math;

/// Loud enough to be a plucked string, quiet enough to ignore the room.
const _silenceRms = 0.02;

/// Below this, the repeating period is not trusted.
const _periodThreshold = 0.15;

/// The MIDI note in [samples], or null when the window is quiet or unclear.
///
/// This is the YIN period picker. It looks for the first lag where the
/// wave repeats, which is the fundamental. A guitar's octave overtone is
/// often louder than the root, and taking the strongest repeat would hear
/// that overtone instead of the note the player fretted.
int? midiFromSamples(List<double> samples, int sampleRate) {
  if (sampleRate < 8000 || samples.length < 1024) return null;

  var energy = 0.0;
  for (final sample in samples) {
    energy += sample * sample;
  }
  if (energy / samples.length < _silenceRms * _silenceRms) return null;

  // Guitar range: below the low E, up through a high fret on the top string.
  final minLag = math.max(2, sampleRate ~/ 1200);
  final maxLag = math.min(samples.length ~/ 2, sampleRate ~/ 70);
  if (minLag >= maxLag) return null;

  final difference = List<double>.filled(maxLag + 1, 0);
  for (var lag = 1; lag <= maxLag; lag++) {
    var sum = 0.0;
    // Every other sample. The period is still obvious, and the playhead
    // does not have to wait on a full search.
    for (var i = 0; i < samples.length - lag; i += 2) {
      final delta = samples[i] - samples[i + lag];
      sum += delta * delta;
    }
    difference[lag] = sum;
  }

  final normalized = List<double>.filled(maxLag + 1, 1);
  var running = 0.0;
  for (var lag = 1; lag <= maxLag; lag++) {
    running += difference[lag];
    normalized[lag] = difference[lag] * lag / running;
  }

  var lag = minLag;
  while (lag <= maxLag && normalized[lag] > _periodThreshold) {
    lag++;
  }
  if (lag > maxLag) return null;
  while (lag + 1 <= maxLag && normalized[lag + 1] < normalized[lag]) {
    lag++;
  }

  final frequency = sampleRate / lag;
  final midi = (69 + 12 * (math.log(frequency / 440) / math.ln2)).round();
  if (midi < 28 || midi > 96) return null;
  return midi;
}

/// Note name for the heard pitch, such as E2.
String pitchName(int midi) {
  const names = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  final octave = (midi ~/ 12) - 1;
  return '${names[midi % 12]}$octave';
}
