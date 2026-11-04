import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/chord_name.dart';
import 'package:riffster/music/position_fingering.dart';

TabNote _note({
  required int timeMs,
  required int fret,
  required int midi,
  int string = 1,
  int durationMs = 400,
  FrettingFinger? finger,
}) {
  return TabNote(
    timeMs: timeMs,
    string: string,
    fret: fret,
    durationMs: durationMs,
    midi: midi,
    finger: finger,
  );
}

void main() {
  test('a four-fret shape gets index through pinky, and a wider one stays hollow', () {
    final notes = assignPositionFingers([
      _note(timeMs: 0, fret: 7, midi: 59, string: 2),
      _note(timeMs: 300, fret: 8, midi: 60, string: 2),
      _note(timeMs: 600, fret: 9, midi: 61, string: 2),
      _note(timeMs: 900, fret: 10, midi: 62, string: 2),
      _note(timeMs: 1600, fret: 5, midi: 57, string: 2),
      _note(timeMs: 1900, fret: 10, midi: 62, string: 2),
      _note(timeMs: 0, fret: 0, midi: 64, string: 1),
      _note(timeMs: 300, fret: 7, midi: 59, string: 3, finger: FrettingFinger.pinky),
    ]);

    expect(notes[0].finger, FrettingFinger.indexFinger);
    expect(notes[1].finger, FrettingFinger.middle);
    expect(notes[2].finger, FrettingFinger.ring);
    expect(notes[3].finger, FrettingFinger.pinky);
    // Five frets later is a new hand. Each note is the index of that hand.
    expect(notes[4].finger, FrettingFinger.indexFinger);
    expect(notes[5].finger, FrettingFinger.indexFinger);
    expect(notes[6].finger, isNull);
    expect(notes[7].finger, FrettingFinger.pinky);
  });

  test('the same fret with an open string between the notes is not a barre', () {
    // Open G. The two 3rd-fret notes have the 2nd fret and open strings
    // between them, so one finger cannot hold both. The lone 2nd fret can.
    final notes = assignPositionFingers([
      _note(timeMs: 0, fret: 3, midi: 43, string: 6),
      _note(timeMs: 0, fret: 2, midi: 47, string: 5),
      _note(timeMs: 0, fret: 0, midi: 50, string: 4),
      _note(timeMs: 0, fret: 0, midi: 55, string: 3),
      _note(timeMs: 0, fret: 0, midi: 59, string: 2),
      _note(timeMs: 0, fret: 3, midi: 67, string: 1),
    ]);

    expect(notes[0].finger, isNull);
    expect(notes[1].finger, FrettingFinger.indexFinger);
    expect(notes[5].finger, isNull);
  });

  test('a stack wider than four frets is left hollow', () {
    final notes = assignPositionFingers([
      _note(timeMs: 0, fret: 1, midi: 41, string: 6),
      _note(timeMs: 0, fret: 6, midi: 58, string: 3),
    ]);

    expect(notes[0].finger, isNull);
    expect(notes[1].finger, isNull);
  });

  test('a melody uses the middle finger for the fret the pinky used to take', () {
    // Frets 7, 9, and 10. The empty 8th fret is a small reach, so the
    // middle finger takes 9 and the ring takes 10. The pinky stays free
    // for the 11, which is one fret past the old hand.
    final notes = assignPositionFingers([
      _note(timeMs: 0, fret: 9, midi: 55, string: 3, durationMs: 180),
      _note(timeMs: 180, fret: 10, midi: 59, string: 2, durationMs: 180),
      _note(timeMs: 360, fret: 10, midi: 59, string: 2, durationMs: 180),
      _note(timeMs: 540, fret: 7, midi: 64, string: 1, durationMs: 180),
      _note(timeMs: 720, fret: 11, midi: 52, string: 5, durationMs: 180),
      _note(timeMs: 900, fret: 7, midi: 64, string: 1, durationMs: 180),
      _note(timeMs: 1080, fret: 7, midi: 59, string: 2, durationMs: 180),
      _note(timeMs: 1260, fret: 7, midi: 64, string: 1, durationMs: 180),
      _note(timeMs: 1440, fret: 7, midi: 59, string: 2, durationMs: 180),
      _note(timeMs: 1620, fret: 7, midi: 55, string: 3, durationMs: 180),
    ]);

    expect(notes[0].finger, FrettingFinger.middle);
    expect(notes[1].finger, FrettingFinger.ring);
    expect(notes[2].finger, FrettingFinger.ring);
    expect(notes[3].finger, FrettingFinger.indexFinger);
    expect(notes[4].finger, FrettingFinger.pinky);
    expect(notes[5].finger, FrettingFinger.indexFinger);
    expect(notes[6].finger, FrettingFinger.middle);
    expect(notes[7].finger, FrettingFinger.indexFinger);
    expect(notes[8].finger, FrettingFinger.middle);
    expect(notes[9].finger, FrettingFinger.ring);
  });

  test('the same fret across strings is a barre, so every note is the index', () {
    final notes = assignPositionFingers([
      _note(timeMs: 0, fret: 7, midi: 59, string: 1),
      _note(timeMs: 0, fret: 7, midi: 54, string: 2),
      _note(timeMs: 0, fret: 7, midi: 50, string: 3),
    ]);

    expect(notes.every((note) => note.finger == FrettingFinger.indexFinger), isTrue);
  });

  test('a chord is named only when the pitches match a shape exactly', () {
    expect(
      chordName([
        _note(timeMs: 0, fret: 7, midi: 47, string: 6),
        _note(timeMs: 0, fret: 9, midi: 54, string: 4),
        _note(timeMs: 0, fret: 7, midi: 50, string: 3),
      ]),
      'Bm',
    );
    expect(
      chordName([
        _note(timeMs: 0, fret: 2, midi: 47, string: 5),
        _note(timeMs: 0, fret: 2, midi: 54, string: 4),
      ]),
      'B5',
    );
    expect(
      chordName([
        _note(timeMs: 0, fret: 3, midi: 48, string: 5),
        _note(timeMs: 0, fret: 2, midi: 52, string: 4),
        _note(timeMs: 0, fret: 2, midi: 57, string: 3),
      ]),
      'Am/C',
    );
    expect(
      chordName([
        _note(timeMs: 0, fret: 1, midi: 60, string: 2),
        _note(timeMs: 0, fret: 0, midi: 64, string: 1),
      ]),
      isNull,
    );
  });
}
