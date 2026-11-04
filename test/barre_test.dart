import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/barre.dart';

TabNote _note({
  required int string,
  required int fret,
  FrettingFinger? finger,
}) {
  return TabNote(
    timeMs: 0,
    string: string,
    fret: fret,
    durationMs: 400,
    midi: 40 + fret,
    finger: finger,
  );
}

void main() {
  test('an index barre includes the fretted notes inside it', () {
    final barre = indexBarre([
      _note(string: 1, fret: 1, finger: FrettingFinger.indexFinger),
      _note(string: 2, fret: 3, finger: FrettingFinger.pinky),
      _note(string: 3, fret: 3, finger: FrettingFinger.ring),
      _note(string: 4, fret: 2, finger: FrettingFinger.middle),
      _note(string: 5, fret: 1, finger: FrettingFinger.indexFinger),
      _note(string: 6, fret: 1, finger: FrettingFinger.indexFinger),
    ]);

    expect(barre, isNotNull);
    expect(barre!.topString, 1);
    expect(barre.bottomString, 6);
  });

  test('an open string between the index fingers is not a barre', () {
    final barre = indexBarre([
      _note(string: 1, fret: 3, finger: FrettingFinger.indexFinger),
      _note(string: 2, fret: 0),
      _note(string: 6, fret: 3, finger: FrettingFinger.indexFinger),
    ]);

    expect(barre, isNull);
  });
}
