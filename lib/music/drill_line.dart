import '../models/fretting_finger.dart';
import '../models/instrument.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';
import 'place_on_neck.dart';
import 'position_fingering.dart';
import 'scale_line.dart';

/// How long the drill is. Every drill is in 4/4, so this is the bar count.
enum DrillBars {
  two(2, '2 bars'),
  four(4, '4 bars'),
  eight(8, '8 bars');

  const DrillBars(this.bars, this.label);

  final int bars;
  final String label;
}

/// The grid the notes sit on. The speed dock still slows the whole line.
enum NoteValue {
  quarter(1, 'Quarter'),
  eighth(2, 'Eighth'),
  sixteenth(4, '16th');

  const NoteValue(this.perBeat, this.label);

  /// Notes per beat. A sixteenth drill has four.
  final int perBeat;
  final String label;
}

/// How far the hand has to go. Each drill reads this in its own way.
enum DrillLevel {
  easy(label: 'Easy'),
  medium(label: 'Medium'),
  hard(label: 'Hard');

  const DrillLevel({required this.label});

  final String label;
}

/// One exercise the Practice stage can put on the neck.
enum DrillKind {
  fingerWarmup(label: 'Warm-up', title: 'finger warm-up'),
  stringCrossing(label: 'Crossing', title: 'string crossing'),
  octaveJumps(label: 'Octaves', title: 'octave jumps'),
  rootAndFifth(label: 'Root & 5th', title: 'root and fifth'),
  oneNoteRhythm(label: 'Rhythm', title: 'on one note'),
  scaleWalk(label: 'Walk', title: 'scale walk');

  const DrillKind({required this.label, required this.title});

  /// The word on the chip.
  final String label;

  /// The words after the root in the song title: "E finger warm-up".
  final String title;
}

/// A drill on [pitchClass], long enough for [bars] of [value].
///
/// Quarter notes at 80 fill the bar the way a scale does. Eighths and
/// sixteenths cut that same bar into smaller notes, so the length knob
/// and the note-value knob each do one job.
///
/// A warm-up and a string crossing are written as a string and a fret.
/// The placer's whole job is to avoid extra shifts and crossings, so
/// handing it those two would let it solve the exercise away. The other
/// four are pitches, and the placer picks the frets.
TabSong practiceDrill({
  required Instrument instrument,
  required int pitchClass,
  required DrillKind kind,
  DrillBars bars = DrillBars.four,
  NoteValue value = NoteValue.eighth,
  DrillLevel level = DrillLevel.easy,
  int tempoBpm = 80,
}) {
  final slots = bars.bars * 4 * value.perBeat;
  final stepMs = 60000 / tempoBpm / value.perBeat;
  final title = '${pitchNames[pitchClass]} ${kind.title}';

  final notes = switch (kind) {
    DrillKind.fingerWarmup => _onStrings(
      instrument: instrument,
      slots: slots,
      stepMs: stepMs,
      pattern: _warmup(instrument, rootFret(instrument, pitchClass), level),
      fingered: true,
    ),
    DrillKind.stringCrossing => _onStrings(
      instrument: instrument,
      slots: slots,
      stepMs: stepMs,
      pattern: _crossing(instrument, rootFret(instrument, pitchClass), level),
      fingered: false,
    ),
    _ => _placed(
      instrument: instrument,
      slots: slots,
      stepMs: stepMs,
      midis: _midis(
        instrument: instrument,
        pitchClass: pitchClass,
        kind: kind,
        level: level,
        slots: slots,
      ),
    ),
  };

  return TabSong(
    title: title,
    tempoBpm: tempoBpm,
    instrument: instrument,
    notes: notes,
  ).withCommonTimeBars();
}

const _fingers = [
  FrettingFinger.indexFinger,
  FrettingFinger.middle,
  FrettingFinger.ring,
  FrettingFinger.pinky,
];

/// One pass of 1-2-3-4 up the strings and back down, from [start].
///
/// [position] is the fret the index finger owns for this shape, so the
/// way back down keeps the same fingers. The top fret is the turn, so
/// it is played once. An open root starts on the open string and the
/// next three frets, which is index, middle, and ring.
List<({int string, int fret, int position})> _onePosition(
  Instrument instrument,
  int start,
) {
  final lowToHigh = [
    for (var string = instrument.stringCount; string >= 1; string--) string,
  ];
  final up = [
    for (final string in lowToHigh)
      for (var fret = start; fret < start + 4; fret++)
        (string: string, fret: fret, position: start),
  ];
  return [...up, ...up.reversed.skip(1)];
}

List<({int string, int fret, int position})> _warmup(
  Instrument instrument,
  int root,
  DrillLevel level,
) {
  final starts = switch (level) {
    // The root's own fret.
    DrillLevel.easy => [root],
    // Two frets higher, so the same shape has to move.
    DrillLevel.medium => [root + 2],
    // The root, then the next position up. Two shapes in one pass.
    DrillLevel.hard => [root, root + 4],
  };
  return [for (final start in starts) ..._onePosition(instrument, start)];
}

/// The same fret on a changing string. [root] is that fret, so the key
/// knob moves the hand. Easy is the two lowest strings. Medium adds a
/// third. Hard walks the whole set and back.
List<({int string, int fret, int position})> _crossing(
  Instrument instrument,
  int root,
  DrillLevel level,
) {
  final lowToHigh = [
    for (var string = instrument.stringCount; string >= 1; string--) string,
  ];
  final strings = switch (level) {
    DrillLevel.easy => lowToHigh.take(2).toList(),
    DrillLevel.medium => [...lowToHigh.take(3), lowToHigh[1]],
    DrillLevel.hard => [...lowToHigh, ...lowToHigh.reversed.skip(1)],
  };
  return [
    for (final string in strings) (string: string, fret: root, position: root),
  ];
}

List<TabNote> _onStrings({
  required Instrument instrument,
  required int slots,
  required double stepMs,
  required List<({int string, int fret, int position})> pattern,
  required bool fingered,
}) {
  return [
    for (var i = 0; i < slots; i++)
      _fretted(
        instrument: instrument,
        spot: pattern[i % pattern.length],
        fingered: fingered,
        timeMs: (i * stepMs).round(),
        durationMs: (stepMs * 0.85).round(),
      ),
  ];
}

TabNote _fretted({
  required Instrument instrument,
  required ({int string, int fret, int position}) spot,
  required bool fingered,
  required int timeMs,
  required int durationMs,
}) {
  final fret = spot.fret;
  // Open string, then the next fingers. A fretted start uses all four,
  // counted from the fret the index finger owns.
  final offset = !fingered || fret == 0
      ? null
      : fret - (spot.position == 0 ? 1 : spot.position);
  final fingerIndex = offset != null && offset >= 0 && offset < _fingers.length
      ? offset
      : null;
  return TabNote(
    timeMs: timeMs,
    string: spot.string,
    fret: fret,
    durationMs: durationMs,
    midi: instrument.openStringMidi[spot.string - 1] + fret,
    finger: fingerIndex == null ? null : _fingers[fingerIndex],
  );
}

/// Pitches for the four drills the placer is allowed to finger.
///
/// A rhythm drill is one pitch with holes in it. The holes are rests:
/// a slot with no note. The times of the notes that do sound stay on
/// the grid, so a rest does not shove the next note early.
List<int?> _midis({
  required Instrument instrument,
  required int pitchClass,
  required DrillKind kind,
  required DrillLevel level,
  required int slots,
}) {
  final root = lowestRoot(instrument, pitchClass);
  return switch (kind) {
    DrillKind.octaveJumps => _cycled(root, _octaves(level), slots),
    DrillKind.rootAndFifth => _cycled(root, _fifths(level), slots),
    DrillKind.oneNoteRhythm => _rhythm(root, level, slots),
    DrillKind.scaleWalk => _walk(root, pitchClass, level, slots),
    _ => throw ArgumentError.value(kind, 'kind', 'is placed by fret'),
  };
}

List<int> _octaves(DrillLevel level) {
  return switch (level) {
    DrillLevel.easy => const [0, 12],
    // The jump, then the same jump from the next scale tone.
    DrillLevel.medium => const [0, 12, 2, 14],
    DrillLevel.hard => [
      for (final step in LineKind.major.steps) ...[step, step + 12],
    ],
  };
}

List<int> _fifths(DrillLevel level) {
  return switch (level) {
    DrillLevel.easy => const [0, 7],
    // Root, fifth, octave, and back to the fifth.
    DrillLevel.medium => const [0, 7, 12, 7],
    DrillLevel.hard => [
      for (final step in LineKind.major.steps) ...[step, step + 7],
    ],
  };
}

List<int?> _cycled(int root, List<int> degrees, int slots) {
  return [for (var i = 0; i < slots; i++) root + degrees[i % degrees.length]];
}

List<int?> _rhythm(int root, DrillLevel level, int slots) {
  // True sounds. Medium is on-off. Hard is two notes, a gap, and a note.
  final hits = switch (level) {
    DrillLevel.easy => const [true],
    DrillLevel.medium => const [true, false],
    DrillLevel.hard => const [true, true, false, true],
  };
  return [
    for (var i = 0; i < slots; i++)
      if (hits[i % hits.length]) root else null,
  ];
}

/// A walk along the major scale, staying inside one position.
///
/// The step is chosen by a fixed sum, not by a fresh roll. The same
/// knobs always build the same line, so playing it again is practice.
/// A new root or a new difficulty is what makes a different line.
/// Easy stays inside four semitones, medium inside seven, hard inside
/// the octave.
List<int?> _walk(int root, int pitchClass, DrillLevel level, int slots) {
  final span = switch (level) {
    DrillLevel.easy => 4,
    DrillLevel.medium => 7,
    DrillLevel.hard => 12,
  };
  const steps = {0, 2, 4, 5, 7, 9, 11};
  final tones = [
    for (var semi = 0; semi <= span; semi++)
      if (steps.contains(semi % 12)) root + semi,
  ];
  var index = 0;
  var seed = pitchClass + level.index * 13 + 1;
  final midis = <int?>[];
  for (var i = 0; i < slots; i++) {
    midis.add(tones[index]);
    seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
    if (tones.length == 1) continue;
    final step = seed.isEven ? -1 : 1;
    final next = index + step;
    index = next >= 0 && next < tones.length ? next : index - step;
  }
  return midis;
}

List<TabNote> _placed({
  required Instrument instrument,
  required int slots,
  required double stepMs,
  required List<int?> midis,
}) {
  final range = placedRange(instrument);
  final pitches = <Pitch>[];
  for (var i = 0; i < slots; i++) {
    final midi = midis[i];
    if (midi == null) continue;
    var note = midi;
    while (note > range.highest) {
      note -= 12;
    }
    while (note < range.lowest) {
      note += 12;
    }
    pitches.add((
      timeMs: (i * stepMs).round(),
      durationMs: (stepMs * 0.85).round(),
      midi: note,
    ));
  }
  return assignPositionFingers(
    placeOnNeck(pitches, instrument: instrument),
    instrument: instrument,
  );
}
