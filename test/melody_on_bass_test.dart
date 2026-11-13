import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/melody_on_bass.dart';
import 'package:riffster/music/place_on_neck.dart';

/// A part as the reader sends one with no strings: pitch and time only.
List<TabNote> _part(List<List<int>> chords) {
  return [
    for (var i = 0; i < chords.length; i++)
      for (final midi in chords[i])
        TabNote(
          timeMs: i * 600,
          string: 0,
          fret: 0,
          durationMs: 500,
          midi: midi,
        ),
  ];
}

List<TabNote> _melody(List<int> midis) => _part([
  for (final midi in midis) [midi],
]);

List<int> _pitches(List<TabNote> notes) => [
  for (final note in notes) note.midi,
];

void main() {
  final bass = Instrument.bass;
  final range = placedRange(bass);

  test('a chord becomes its top note', () {
    // C major, then a single note, then G major written top note first.
    final line = melodyOnBass(
      _part([
        [48, 52, 55],
        [57],
        [62, 59, 55],
      ]),
    );

    expect(line.map((note) => note.timeMs), [0, 600, 1200]);
    expect(_pitches(line).map((midi) => midi % 12), [
      55 % 12,
      57 % 12,
      62 % 12,
    ]);
  });

  test('the line moves by whole octaves, so every note keeps its name', () {
    // A tune up where a voice sings, two octaves above the bass.
    final sung = [64, 64, 65, 67, 67, 65, 64, 62, 60, 60, 62, 64];
    final line = melodyOnBass(_melody(sung));

    final moved = {
      for (var i = 0; i < sung.length; i++) line[i].midi - sung[i],
    };
    expect(moved, hasLength(1), reason: 'every note moved the same distance');
    expect(moved.single % 12, 0);
    // The lowest octave that fits: the low C is the 3rd fret of A.
    expect(_pitches(line).reduce((a, b) => a < b ? a : b), 36);
  });

  test('high is the same line one octave up', () {
    final sung = _melody([64, 65, 67, 65, 64, 62, 60]);
    final low = melodyOnBass(sung, register: Register.low);
    final high = melodyOnBass(sung, register: Register.high);

    expect(_pitches(high), [for (final midi in _pitches(low)) midi + 12]);
  });

  test(
    'high stays low when the octave above would push notes off the neck',
    () {
      // Two and a half octaves wide. Only one octave holds all of it.
      final wide = _melody([40, 52, 64, 70]);

      expect(
        _pitches(melodyOnBass(wide, register: Register.high)),
        _pitches(melodyOnBass(wide, register: Register.low)),
      );
    },
  );

  test('a stray note is folded an octave, and the rest stay together', () {
    // Four notes close together and one squeak five octaves up. The
    // four go down an octave as a group. The squeak cannot follow them
    // onto the neck, so it alone comes down until it fits.
    final line = melodyOnBass(_melody([40, 45, 52, 57, 100]));

    expect(_pitches(line), [28, 33, 40, 45, 52]);
  });

  test('every note is on the bass neck, wherever the part came from', () {
    // From below the bass to above a piccolo, a semitone at a time.
    final everything = _melody([for (var midi = 12; midi <= 108; midi++) midi]);
    for (final register in Register.values) {
      for (final note in melodyOnBass(everything, register: register)) {
        expect(note.midi, inInclusiveRange(range.lowest, range.highest));
        expect(note.string, inInclusiveRange(1, bass.stringCount));
        expect(bass.openStringMidi[note.string - 1] + note.fret, note.midi);
      }
    }
  });
}
