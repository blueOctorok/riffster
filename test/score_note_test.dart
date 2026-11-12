import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/score_note.dart';

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

  test('half speed is judged in real time, not in song time', () {
    final written = [_note(midi: 64)];

    // 60 ms of song time at half speed is 120 real milliseconds early.
    expect(
      scoreMoment(
        written: written,
        playedAtMs: 1000 - 60,
        playedMidi: 64,
        speed: 0.5,
      ),
      ScoreMark.early,
    );
    // 130 ms of song time is 260 real milliseconds: a different beat.
    expect(windowHasPassed(dueAtMs: 0, positionMs: 125, speed: 0.5), isFalse);
    expect(windowHasPassed(dueAtMs: 0, positionMs: 130, speed: 0.5), isTrue);
  });
}
