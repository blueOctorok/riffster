import 'dart:math' as math;
import 'dart:typed_data';

/// Below this, the repeating period is not trusted.
const _periodThreshold = 0.15;

/// How many samples one cycle of the wave takes, or null when the
/// window has no clear pitch. The answer can fall between two samples.
///
/// The window is [length] samples of [samples], beginning at [start].
///
/// This is the YIN period picker. Slide a copy of the wave along
/// itself and measure how different the two are at each shift. At a
/// shift of exactly one cycle they line up and the difference drops.
/// The first shift where that happens is the note.
///
/// "First" is the point. A string's octave overtone is often louder
/// than its root. The deepest dip could be that overtone's, an octave
/// too high. The first deep dip is the note the player fretted.
///
/// Only shifts up to half the window are tried, so every answer has
/// been seen to repeat at least once. A window too short for a low
/// note returns null instead of guessing, and the caller asks again
/// once more sound has arrived.
double? periodIn(
  Float64List samples, {
  required int start,
  required int length,
  required int shortest,
  required int longest,
}) {
  final maxLag = math.min(longest, length ~/ 2);
  if (maxLag <= shortest) return null;
  final compared = length - maxLag;

  var runningSum = 0.0;
  var before = 1.0;
  var lowest = 1.0;
  int? found;
  for (var lag = 1; lag <= maxLag; lag++) {
    var difference = 0.0;
    for (var i = start; i < start + compared; i++) {
      final delta = samples[i] - samples[i + lag];
      difference += delta * delta;
    }
    runningSum += difference;
    // Dividing by the average so far makes "low" mean low for this
    // wave. Without it a quiet note and a loud one need two thresholds.
    final dip = runningSum == 0 ? 1.0 : difference * lag / runningSum;

    if (found == null) {
      if (lag >= shortest && dip < _periodThreshold) {
        found = lag;
        lowest = dip;
      } else {
        before = dip;
      }
    } else if (dip < lowest) {
      before = lowest;
      lowest = dip;
      found = lag;
    } else {
      // The dip has turned back up, so [found] is its bottom. The true
      // bottom sits between samples. A parabola through the three
      // points around it says where.
      final curve = before - 2 * lowest + dip;
      final nudge = curve <= 0 ? 0.0 : (before - dip) / (2 * curve);
      return found + nudge.clamp(-0.5, 0.5);
    }
  }
  // Still falling at the last shift tried. The real bottom may be
  // past the end of the window, so this is not an answer yet.
  return null;
}

/// The pitch, in hertz, of a MIDI note. [midi] may sit between notes.
double hertzOfMidi(num midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

/// Where a pitch of [hertz] sits on the MIDI scale. The answer can fall
/// between two notes: 37.4 is a C#2 that is 40 cents sharp.
double midiOfHertz(double hertz) {
  return 69 + 12 * (math.log(hertz / 440) / math.ln2);
}

/// The MIDI note of a wave that repeats every [period] samples.
int midiOfPeriod(double period, double sampleRate) {
  return midiOfHertz(sampleRate / period).round();
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
