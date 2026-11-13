import '../models/instrument.dart';
import '../models/tab_song.dart';
import 'place_on_neck.dart';
import 'position_fingering.dart';

/// C is 0. The names match the ones a player says out loud.
const pitchNames = [
  'C',
  'C#',
  'D',
  'Eb',
  'E',
  'F',
  'F#',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];

/// A scale or an arpeggio, as semitones above its root.
///
/// The list stops before the octave. [practiceLine] adds the octave,
/// then walks back down, so the top note is played once.
enum LineKind {
  major(label: 'Major', scale: true, steps: [0, 2, 4, 5, 7, 9, 11]),
  minor(label: 'Minor', scale: true, steps: [0, 2, 3, 5, 7, 8, 10]),
  majorPentatonic(label: 'Maj pent', scale: true, steps: [0, 2, 4, 7, 9]),
  minorPentatonic(label: 'Min pent', scale: true, steps: [0, 3, 5, 7, 10]),
  blues(label: 'Blues', scale: true, steps: [0, 3, 5, 6, 7, 10]),
  majorArpeggio(label: 'Major', scale: false, steps: [0, 4, 7]),
  minorArpeggio(label: 'Minor', scale: false, steps: [0, 3, 7]),
  dominant7(label: '7', scale: false, steps: [0, 4, 7, 10]),
  major7(label: 'Maj7', scale: false, steps: [0, 4, 7, 11]),
  minor7(label: 'm7', scale: false, steps: [0, 3, 7, 10]);

  const LineKind({
    required this.label,
    required this.scale,
    required this.steps,
  });

  /// The word on the chip.
  final String label;

  /// True for a scale, false for an arpeggio. The two rows of chips
  /// are this.
  final bool scale;

  /// Semitones above the root, not including the octave.
  final List<int> steps;

  static final scales = [
    for (final kind in values)
      if (kind.scale) kind,
  ];
  static final arpeggios = [
    for (final kind in values)
      if (!kind.scale) kind,
  ];

  /// "E major", "A minor pentatonic", "G7".
  String titleFor(int pitchClass) {
    final root = pitchNames[pitchClass];
    return switch (this) {
      major => '$root major',
      minor => '$root minor',
      majorPentatonic => '$root major pentatonic',
      minorPentatonic => '$root minor pentatonic',
      blues => '$root blues',
      majorArpeggio => '$root major arpeggio',
      minorArpeggio => '$root minor arpeggio',
      dominant7 => '${root}7',
      major7 => '$root maj7',
      minor7 => '${root}m7',
    };
  }
}

/// One octave of [kind] on [pitchClass], up and back down, sitting as
/// low on [instrument] as the root allows.
///
/// Quarter notes at [tempoBpm]. The placer picks the frets, the same
/// way it places a melody from a file.
TabSong practiceLine({
  required Instrument instrument,
  required int pitchClass,
  required LineKind kind,
  int tempoBpm = 80,
}) {
  final start = _lowestRoot(instrument, pitchClass);
  // Up through the octave, then the same degrees back down. The octave
  // is the turn, so it is not played twice.
  final degrees = [...kind.steps, 12, ...kind.steps.reversed];
  final beatMs = 60000 / tempoBpm;
  final pitches = [
    for (var i = 0; i < degrees.length; i++)
      (
        timeMs: (i * beatMs).round(),
        durationMs: (beatMs * 0.85).round(),
        midi: start + degrees[i],
      ),
  ];
  return TabSong(
    title: kind.titleFor(pitchClass),
    tempoBpm: tempoBpm,
    instrument: instrument,
    notes: assignPositionFingers(
      placeOnNeck(pitches, instrument: instrument),
      instrument: instrument,
    ),
  ).withCommonTimeBars();
}

/// The lowest note of [pitchClass] the neck can play.
///
/// Pitch classes wrap every 12 semitones, and C is 0. The lowest open
/// string is some class already. The distance forward to the root is
/// how many frets above that open string the scale has to start. An E
/// scale on a bass starts on the open E. A C scale starts a minor
/// third higher, because there is no C below that E.
int _lowestRoot(Instrument instrument, int pitchClass) {
  final lowest = instrument.openStringMidi.last;
  final fretsUp = (pitchClass - lowest % 12 + 12) % 12;
  return lowest + fretsUp;
}
