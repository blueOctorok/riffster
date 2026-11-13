import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/music/scale_line.dart';

void main() {
  test('a scale goes up an octave and comes back down to the root', () {
    final song = practiceLine(
      instrument: Instrument.bass,
      pitchClass: pitchNames.indexOf('E'),
      kind: LineKind.major,
    );

    // Open E, then the major scale, the octave, and back.
    expect(song.notes.map((note) => note.midi), [
      28,
      30,
      32,
      33,
      35,
      37,
      39,
      40,
      39,
      37,
      35,
      33,
      32,
      30,
      28,
    ]);
    expect(song.title, 'E major');
    expect(song.notes.first.midi, song.notes.last.midi);
  });

  test('every note belongs to the scale, on both instruments', () {
    for (final instrument in Instrument.values) {
      for (final kind in LineKind.values) {
        for (var pitchClass = 0; pitchClass < 12; pitchClass++) {
          final song = practiceLine(
            instrument: instrument,
            pitchClass: pitchClass,
            kind: kind,
          );
          final allowed = {...kind.steps, 12};
          final start = song.notes.first.midi;
          expect(start % 12, pitchClass, reason: song.title);
          for (final note in song.notes) {
            expect((note.midi - start) % 12, isIn(allowed), reason: song.title);
            expect(
              instrument.openStringMidi[note.string - 1] + note.fret,
              note.midi,
              reason: song.title,
            );
          }
        }
      }
    }
  });

  test('the root is the lowest one the neck has', () {
    // A bass has no C below its low E, so C starts at C2.
    final bass = practiceLine(
      instrument: Instrument.bass,
      pitchClass: 0,
      kind: LineKind.minor,
    );
    expect(bass.notes.first.midi, 36);

    // A guitar's lowest string is the E above that, so its C is C3.
    final guitar = practiceLine(
      instrument: Instrument.guitar,
      pitchClass: 0,
      kind: LineKind.minor,
    );
    expect(guitar.notes.first.midi, 48);
  });
}
