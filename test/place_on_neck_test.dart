import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/place_on_neck.dart';

/// Quarter notes at 100 bpm, one for each pitch.
List<Pitch> _line(List<int> midis) {
  return [
    for (var i = 0; i < midis.length; i++)
      (timeMs: i * 600, durationMs: 500, midi: midis[i]),
  ];
}

List<TabNote> _onBass(List<int> midis) {
  return placeOnNeck(_line(midis), instrument: Instrument.bass);
}

/// "string:fret" for each note, which reads like a line of tab.
List<String> _tab(List<TabNote> notes) {
  return [for (final note in notes) '${note.string}:${note.fret}'];
}

void main() {
  test('every note lands on a string and fret that sound its pitch', () {
    for (final instrument in Instrument.values) {
      final range = placedRange(instrument);
      final everyPitch = [
        for (var midi = range.lowest; midi <= range.highest; midi++) midi,
      ];
      final placed = placeOnNeck(_line(everyPitch), instrument: instrument);

      expect(placed, hasLength(everyPitch.length));
      for (var i = 0; i < placed.length; i++) {
        final note = placed[i];
        expect(note.midi, everyPitch[i]);
        expect(note.timeMs, i * 600);
        expect(note.durationMs, 500);
        expect(note.fret, inInclusiveRange(0, topPlacedFret));
        expect(
          instrument.openStringMidi[note.string - 1] + note.fret,
          note.midi,
          reason: '${instrument.label} string ${note.string} fret ${note.fret}',
        );
      }
    }
  });

  test('a note with one home is put there', () {
    // The lowest E on a bass is the open E string and nowhere else.
    expect(_tab(_onBass([28])), ['4:0']);
  });

  test('a note alone goes to the place nearest the nut', () {
    // D is the open D string, the 5th fret of A, or the 10th of E.
    expect(_tab(_onBass([38])), ['2:0']);
  });

  test('a major scale is played in first position, with no shift', () {
    // C major from the 3rd fret of the A string, the way a first bass
    // book writes it: open D and open G, and nothing above the 5th fret.
    final placed = _onBass([36, 38, 40, 41, 43, 45, 47, 48]);

    expect(_tab(placed), [
      '3:3',
      '2:0',
      '2:2',
      '2:3',
      '1:0',
      '1:2',
      '1:4',
      '1:5',
    ]);
  });

  test('a line that fits one hand position stays in it', () {
    // A minor pentatonic. Starting on the open A looks cheaper for the
    // first few notes, and then the top D is out of reach. Weighing the
    // whole line finds the box at the 5th fret, where nothing moves.
    final placed = _onBass([33, 36, 38, 40, 43, 45, 48, 50]);

    expect(_tab(placed), [
      '4:5',
      '4:8',
      '3:5',
      '3:7',
      '2:5',
      '2:7',
      '1:5',
      '1:7',
    ]);
  });

  test('a repeated note is played in the same place every time', () {
    final placed = _onBass([45, 45, 45, 45]);

    expect(_tab(placed).toSet(), hasLength(1));
  });

  test('a line high on the neck stays there', () {
    // Each of these is also lower down on a thinner string. The hand
    // starts at the 12th fret, so going back for them would be two
    // moves, and staying is none.
    final placed = _onBass([55, 57, 52, 50, 52, 55]);

    expect(_tab(placed), ['1:12', '1:14', '2:14', '2:12', '2:14', '1:12']);
  });

  test('a pitch the neck does not have is an error', () {
    expect(() => _onBass([27]), throwsArgumentError);
    expect(() => _onBass([43 + topPlacedFret + 1]), throwsArgumentError);
  });

  test('no notes in is no notes out', () {
    expect(_onBass([]), isEmpty);
  });
}
