import '../models/tab_note.dart';
import 'chord_book.dart';

const _pitchNames = [
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

/// Interval sets measured from the root. A name is used only when the
/// sounding pitch classes match one of these exactly. A close voicing
/// with an extra note stays unlabeled.
const _qualities = <({String suffix, Set<int> intervals})>[
  (suffix: 'maj7', intervals: {0, 4, 7, 11}),
  (suffix: '7', intervals: {0, 4, 7, 10}),
  (suffix: 'm7', intervals: {0, 3, 7, 10}),
  (suffix: 'm7b5', intervals: {0, 3, 6, 10}),
  (suffix: '', intervals: {0, 4, 7}),
  (suffix: 'm', intervals: {0, 3, 7}),
  (suffix: 'dim', intervals: {0, 3, 6}),
  (suffix: 'aug', intervals: {0, 4, 8}),
  (suffix: 'sus2', intervals: {0, 2, 7}),
  (suffix: 'sus4', intervals: {0, 5, 7}),
  (suffix: '5', intervals: {0, 7}),
];

/// Name for notes that sound together, or null when the shape is unknown.
///
/// Octaves collapse, so two Cs and an E and a G are still C major. The
/// lowest note is the bass. When the bass is not the root, the name is
/// written "Am/C". Pitches have to match a quality exactly. When they do
/// not, a chord-book grip can still name the stack. That is how a tab that
/// only wrote the fretted notes of an open G still reads as G.
String? chordName(Iterable<TabNote> sounding) {
  final notes = sounding.toList();
  if (notes.length < 2) return null;

  final fromPitches = _nameFromPitches(notes);
  if (fromPitches != null) return fromPitches;
  return matchingGrip(notes)?.name;
}

String? _nameFromPitches(List<TabNote> notes) {
  final classes = notes.map((note) => note.midi % 12).toSet();
  if (classes.length < 2) return null;

  final bass = notes
      .reduce((a, b) => a.midi <= b.midi ? a : b)
      .midi %
      12;
  final roots = [bass, ...classes.where((pitch) => pitch != bass)];

  for (final root in roots) {
    final intervals = classes.map((pitch) => (pitch - root) % 12).toSet();
    for (final quality in _qualities) {
      if (!_samePitches(intervals, quality.intervals)) continue;
      final name = '${_pitchNames[root]}${quality.suffix}';
      if (root == bass) return name;
      return '$name/${_pitchNames[bass]}';
    }
  }
  return null;
}

bool _samePitches(Set<int> sounding, Set<int> shape) {
  return sounding.length == shape.length && sounding.containsAll(shape);
}
