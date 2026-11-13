import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/import/imported_score.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/models/instrument.dart';

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
    // Fret 2 had no finger. It is alone, so the hand moves there and the
    // index finger takes it.
    expect(song.notes[2].finger, FrettingFinger.indexFinger);
    expect(song.lengthMs, 1800);
  });

  test('a part keeps the tuning the reader sent, and none means a guitar', () {
    Map<String, Object?> part(String name, Object? tuning) {
      return {
        'name': name,
        'tuning': ?tuning,
        'notes': [
          {'timeMs': 0, 'durationMs': 600, 'string': 0, 'fret': 0, 'midi': 60},
        ],
      };
    }

    final score = ImportedScore.fromJson({
      'tracks': [
        part('Bass', [43, 38, 33, 28]),
        part('Voice', <int>[]),
        part('Old reader', null),
      ],
    });

    expect(score.tracks[0].tuning, [43, 38, 33, 28]);
    expect(score.tracks[0].instrument, Instrument.bass);
    // An empty list is a part with no strings. It is not a missing one.
    expect(score.tracks[1].tuning, isEmpty);
    expect(score.tracks[1].instrument, isNull);
    expect(score.tracks[2].instrument, Instrument.guitar);
  });
}
