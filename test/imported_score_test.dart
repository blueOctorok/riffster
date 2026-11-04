import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/import/imported_score.dart';
import 'package:riffster/models/fretting_finger.dart';

void main() {
  test('a Guitar Pro note list keeps fingers and leaves open strings hollow', () {
    final score = ImportedScore.fromJson({
      'title': 'Import check',
      'tempoBpm': 100,
      'tracks': [
        {
          'name': 'High strings',
          'notes': [
            {
              'timeMs': 0,
              'durationMs': 600,
              'string': 1,
              'fret': 0,
              'midi': 64,
              'finger': 1,
            },
            {
              'timeMs': 600,
              'durationMs': 600,
              'string': 1,
              'fret': 3,
              'midi': 67,
              'finger': 4,
            },
            {
              'timeMs': 1200,
              'durationMs': 600,
              'string': 4,
              'fret': 2,
              'midi': 52,
              'finger': null,
            },
          ],
        },
      ],
    });

    final song = score.toSong(score.tracks.single, fallbackTitle: 'file');

    expect(song.title, 'Import check — High strings');
    expect(song.tempoBpm, 100);
    expect(song.notes[0].finger, isNull);
    expect(song.notes[1].finger, FrettingFinger.pinky);
    expect(song.notes[2].finger, isNull);
    expect(song.lengthMs, 1800);
  });
}
