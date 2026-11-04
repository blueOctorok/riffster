import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/chord_book.dart';
import 'package:riffster/music/chord_name.dart';
import 'package:riffster/music/position_fingering.dart';

TabNote _note({
  required int string,
  required int fret,
  required int midi,
  FrettingFinger? finger,
}) {
  return TabNote(
    timeMs: 0,
    string: string,
    fret: fret,
    durationMs: 400,
    midi: midi,
    finger: finger,
  );
}

void main() {
  test('a tab that only wrote the fretted notes of an open G is still G', () {
    final notes = assignPositionFingers([
      _note(string: 1, fret: 3, midi: 67),
      _note(string: 5, fret: 2, midi: 47),
      _note(string: 6, fret: 3, midi: 43),
    ]);

    expect(chordName(notes), 'G');
    expect(notes[0].finger, FrettingFinger.ring);
    expect(notes[1].finger, FrettingFinger.indexFinger);
    expect(notes[2].finger, FrettingFinger.middle);
  });

  test('a finger stored in the file wins over the chord book', () {
    final notes = assignPositionFingers([
      _note(string: 1, fret: 3, midi: 67, finger: FrettingFinger.pinky),
      _note(string: 5, fret: 2, midi: 47),
      _note(string: 6, fret: 3, midi: 43),
    ]);

    expect(notes[0].finger, FrettingFinger.pinky);
    expect(notes[1].finger, FrettingFinger.indexFinger);
    expect(notes[2].finger, FrettingFinger.middle);
  });

  test('a different fret on an open string is not that grip', () {
    // Low E 3, A 2, D 2, high e 3. The D string is fretted, so this is
    // not the open G even though three of the notes match.
    final notes = [
      _note(string: 1, fret: 3, midi: 67),
      _note(string: 4, fret: 2, midi: 52),
      _note(string: 5, fret: 2, midi: 47),
      _note(string: 6, fret: 3, midi: 43),
    ];

    expect(matchingGrip(notes), isNull);
    expect(chordName(notes), 'Em/G');
  });

  test('two fretted notes are not enough to assume the open strings', () {
    final fragment = [
      _note(string: 4, fret: 2, midi: 52),
      _note(string: 5, fret: 2, midi: 47),
    ];
    expect(matchingGrip(fragment), isNull);
    // B and E are a fifth. They are not an Em just because Em uses those frets.
    expect(chordName(fragment), 'E5/B');

    final em = assignPositionFingers([
      _note(string: 1, fret: 0, midi: 64),
      _note(string: 2, fret: 0, midi: 59),
      _note(string: 3, fret: 0, midi: 55),
      _note(string: 4, fret: 2, midi: 52),
      _note(string: 5, fret: 2, midi: 47),
      _note(string: 6, fret: 0, midi: 40),
    ]);
    expect(chordName(em), 'Em');
    expect(em[3].finger, FrettingFinger.ring);
    expect(em[4].finger, FrettingFinger.middle);
  });

  test('F#7 and the barre Bm use the book fingers', () {
    final fSharp = assignPositionFingers([
      _note(string: 2, fret: 5, midi: 64),
      _note(string: 3, fret: 3, midi: 58),
      _note(string: 4, fret: 2, midi: 52),
      _note(string: 5, fret: 4, midi: 49),
      _note(string: 6, fret: 2, midi: 42),
    ]);
    expect(chordName(fSharp), 'F#7');
    expect(fSharp[0].finger, FrettingFinger.pinky);
    expect(fSharp[1].finger, FrettingFinger.middle);
    expect(fSharp[2].finger, FrettingFinger.indexFinger);
    expect(fSharp[3].finger, FrettingFinger.ring);
    expect(fSharp[4].finger, FrettingFinger.indexFinger);

    final barre = assignPositionFingers([
      _note(string: 1, fret: 7, midi: 71),
      _note(string: 2, fret: 7, midi: 66),
      _note(string: 3, fret: 7, midi: 62),
      _note(string: 4, fret: 9, midi: 59),
      _note(string: 5, fret: 9, midi: 54),
      _note(string: 6, fret: 7, midi: 47),
    ]);
    expect(chordName(barre), 'Bm');
    expect(barre[0].finger, FrettingFinger.indexFinger);
    expect(barre[3].finger, FrettingFinger.pinky);
    expect(barre[4].finger, FrettingFinger.ring);
    expect(barre[5].finger, FrettingFinger.indexFinger);
  });
}
