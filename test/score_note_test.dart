import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/models/tab_song.dart';
import 'package:riffster/music/score_note.dart';
import 'package:riffster/music/song_timeline.dart';
import 'package:riffster/widgets/stage/stage_metrics.dart';

TabNote _note({required int midi, int string = 1, int timeMs = 1000}) {
  return TabNote(
    timeMs: timeMs,
    string: string,
    fret: 0,
    durationMs: 400,
    midi: midi,
  );
}

void main() {
  test('the same pitch on another string is a hit', () {
    final written = [_note(midi: 64, string: 1)];

    expect(
      scoreMoment(written: written, playedAtMs: 1000, playedMidi: 64),
      ScoreMark.hit,
    );
  });

  test('a different pitch is a miss even when it is on time', () {
    expect(
      scoreMoment(written: [_note(midi: 64)], playedAtMs: 1000, playedMidi: 65),
      ScoreMark.miss,
    );
  });

  test(
    'an early or late right pitch is not a hit and not a different beat',
    () {
      final written = [_note(midi: 64)];

      expect(
        scoreMoment(written: written, playedAtMs: 1000 - 150, playedMidi: 64),
        ScoreMark.early,
      );
      expect(
        scoreMoment(written: written, playedAtMs: 1000 + 150, playedMidi: 64),
        ScoreMark.late,
      );
      expect(
        scoreMoment(written: written, playedAtMs: 1000 + 400, playedMidi: 64),
        ScoreMark.miss,
      );
    },
  );

  test('a chord is judged by the strum, not by each string', () {
    final chord = [
      _note(midi: 64, string: 1),
      _note(midi: 59, string: 2),
      _note(midi: 55, string: 3),
    ];

    expect(
      scoreMoment(written: chord, playedAtMs: 1040, playedMidi: 40),
      ScoreMark.hit,
    );
    expect(
      scoreMoment(written: chord, playedAtMs: 1000 + 150, playedMidi: null),
      ScoreMark.late,
    );
  });

  test('at full speed, a note touching the gold line is on time', () {
    // The slowest scroll is where a note takes longest to cross the line.
    final slowest = scrollSpeedFor(
      SongTimeline(const TabSong(title: 'Empty', tempoBpm: 100, notes: [])),
      noteDiameter: 0,
    );
    for (final instrument in Instrument.values) {
      final metrics = StageMetrics(
        instrument: instrument,
        size: const Size(1200, StageMetrics.height),
        pixelsPerSecond: slowest,
      );
      // From the circle's edge on the line to its centre on the line.
      final edgeToCentreMs = metrics.msAcross(metrics.noteRadius);

      expect(edgeToCentreMs, lessThanOrEqualTo(onTimeMs), reason: '$instrument');
      expect(
        scoreMoment(
          written: [_note(midi: 64)],
          playedAtMs: 1000 - edgeToCentreMs,
          playedMidi: 64,
        ),
        ScoreMark.hit,
        reason: '$instrument',
      );
    }
  });

  test('a hit stays, and a miss can still be saved', () {
    expect(keepBetterMark(null, ScoreMark.miss), ScoreMark.miss);
    expect(keepBetterMark(ScoreMark.miss, ScoreMark.hit), ScoreMark.hit);
    expect(keepBetterMark(ScoreMark.hit, ScoreMark.miss), ScoreMark.hit);
    expect(keepBetterMark(ScoreMark.early, ScoreMark.hit), ScoreMark.early);
  });

  test('a note is out of reach once the playhead is 250 ms past it', () {
    expect(windowHasPassed(dueAtMs: 0, positionMs: 250), isFalse);
    expect(windowHasPassed(dueAtMs: 0, positionMs: 251), isTrue);
    expect(windowHasPassed(dueAtMs: 1000, positionMs: 251), isFalse);
  });

  test('slowing the song does not shrink the circle', () {
    final written = [_note(midi: 64)];

    // 70 ms of the song is inside the circle, at any speed. It used to
    // be called early at half speed, because 70 song ms is 140 real ms
    // and the window was 120 real ms.
    expect(
      scoreMoment(written: written, playedAtMs: 1000 - 70, playedMidi: 64),
      ScoreMark.hit,
    );
    // 150 ms of the song is past the circle: early, however slow it feels.
    expect(
      scoreMoment(written: written, playedAtMs: 1000 - 150, playedMidi: 64),
      ScoreMark.early,
    );
    expect(windowHasPassed(dueAtMs: 0, positionMs: 250), isFalse);
    expect(windowHasPassed(dueAtMs: 0, positionMs: 251), isTrue);
  });
}
