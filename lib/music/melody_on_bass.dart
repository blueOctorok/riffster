import '../models/instrument.dart';
import '../models/tab_note.dart';
import 'place_on_neck.dart';

/// How high a melody sits. A bass melody often sings better an octave
/// up, on the D and G strings.
enum Register {
  low(label: 'Low'),
  high(label: 'High');

  const Register({required this.label});

  final String label;
}

const _octave = 12;

/// Turns any part into a line for a four-string bass.
///
/// Only the pitches and times of [part] are read, so it can be a guitar,
/// a voice, or a keyboard. Three things happen, in this order.
///
/// A chord becomes its top note, because the top of a chord is the note
/// the ear follows.
///
/// The whole line then moves by octaves to where the most notes fit the
/// neck. An octave is the same note name higher or lower, so the key
/// never changes and the tune stays the tune. [Register.high] takes the
/// octave above, when that loses nothing.
///
/// A note that still falls off the neck is moved an octave by itself.
List<TabNote> melodyOnBass(
  List<TabNote> part, {
  Register register = Register.low,
}) {
  final line = _topLine(part);
  final range = placedRange(Instrument.bass);
  final shift = _octaveShift(line, register, range);
  return placeOnNeck([
    for (final note in line)
      (
        timeMs: note.timeMs,
        durationMs: note.durationMs,
        midi: _foldedInto(range, note.midi + shift),
      ),
  ], instrument: Instrument.bass);
}

/// The highest note at each time, in time order.
List<TabNote> _topLine(List<TabNote> notes) {
  final top = <int, TabNote>{};
  for (final note in notes) {
    final sofar = top[note.timeMs];
    if (sofar == null || note.midi > sofar.midi) top[note.timeMs] = note;
  }
  return top.values.toList()..sort((a, b) => a.timeMs.compareTo(b.timeMs));
}

/// How many semitones to move the whole line: always whole octaves.
int _octaveShift(
  List<TabNote> line,
  Register register,
  ({int lowest, int highest}) range,
) {
  int fitting(int shift) {
    return line.where((note) {
      final midi = note.midi + shift;
      return midi >= range.lowest && midi <= range.highest;
    }).length;
  }

  // Ten octaves is every note there is, so the best one is in here.
  // Walking up from the bottom and only taking a strictly better count
  // leaves the lowest of any octaves that tie.
  var best = -5 * _octave;
  for (var shift = best + _octave; shift <= 5 * _octave; shift += _octave) {
    if (fitting(shift) > fitting(best)) best = shift;
  }
  final above = best + _octave;
  final canGoUp = fitting(above) == fitting(best);
  return register == Register.high && canGoUp ? above : best;
}

int _foldedInto(({int lowest, int highest}) range, int midi) {
  var folded = midi;
  while (folded < range.lowest) {
    folded += _octave;
  }
  while (folded > range.highest) {
    folded -= _octave;
  }
  return folded;
}
