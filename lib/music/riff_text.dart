import '../models/tab_song.dart';
import 'place_on_neck.dart';

/// A line of music written as text, the way the app's own riffs are.
///
/// Each note is a name, a colon, and how many beats it lasts:
///
///     E1:1 G1:.5 A1:.5 | Bb1:2 -:1 C2:1/3 ...
///
/// `E1` is the open low E of a bass, and octaves change at C, so the
/// note above B1 is C2. `-` is a rest. A length can be a fraction, for
/// triplets. `|` ends a bar, and every bar has to hold exactly
/// [beatsPerBar] beats. A bar that does not add up is a typing mistake,
/// and it is caught here instead of being heard as a riff that drifts.
///
/// Returns the pitches for [placeOnNeck], and the bars.
({List<Pitch> pitches, List<SongBar> bars}) readRiffText(
  String text, {
  required int tempoBpm,
  int beatsPerBar = 4,
}) {
  final beatMs = 60000 / tempoBpm;
  final pitches = <Pitch>[];
  final bars = <SongBar>[];
  // Where the next note starts, in beats from the top.
  var beat = 0.0;

  for (final barText in text.split('|')) {
    final tokens = barText.trim().split(RegExp(r'\s+'));
    if (tokens.first.isEmpty) continue;
    final barStart = beat;
    for (final token in tokens) {
      final (name, beats) = _nameAndBeats(token);
      if (name != '-') {
        final lengthMs = beats * beatMs;
        pitches.add((
          timeMs: (beat * beatMs).round(),
          // A little air before the next note, so two of the same pitch
          // in a row are two notes to the eye.
          durationMs: (lengthMs * 0.85).round(),
          midi: _midiOf(name),
        ));
      }
      beat += beats;
    }
    // Three thirds do not add up to exactly one in binary, so "equal"
    // has to mean "closer than anyone could type".
    final held = beat - barStart;
    if ((held - beatsPerBar).abs() > 0.001) {
      throw FormatException(
        'Bar ${bars.length + 1} holds $held beats, not $beatsPerBar',
        barText,
      );
    }
    // Snapped to the whole beat, so that rounding never piles up.
    beat = barStart + beatsPerBar;
    bars.add(
      SongBar(
        startMs: (barStart * beatMs).round(),
        endMs: (beat * beatMs).round(),
        beats: beatsPerBar,
      ),
    );
  }
  return (pitches: pitches, bars: bars);
}

(String name, double beats) _nameAndBeats(String token) {
  final parts = token.split(':');
  if (parts.length != 2) {
    throw FormatException('A note is a name, a colon, and beats', token);
  }
  final fraction = parts[1].split('/');
  final beats = fraction.length == 2
      ? double.parse(fraction[0]) / double.parse(fraction[1])
      : double.parse(parts[1]);
  return (parts[0], beats);
}

const _semitonesAboveC = {
  'C': 0,
  'D': 2,
  'E': 4,
  'F': 5,
  'G': 7,
  'A': 9,
  'B': 11,
};

final _noteName = RegExp(r'^([A-G])([#b]?)(\d)$');

/// The MIDI number of a name like `E1`, `F#2`, or `Bb1`.
int _midiOf(String name) {
  final match = _noteName.firstMatch(name);
  if (match == null) throw FormatException('Not a note name', name);
  final accidental = switch (match[2]) {
    '#' => 1,
    'b' => -1,
    _ => 0,
  };
  // MIDI counts C-1 as 0, so octave 1 starts at 24.
  final octave = int.parse(match[3]!);
  return 12 * (octave + 1) + _semitonesAboveC[match[1]]! + accidental;
}
