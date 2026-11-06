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
    final note = _note(midi: 64);
    final marks = <TabNote, ScoreMark>{};

    applyPlayedMark(marks, [note], ScoreMark.miss);
    applyPlayedMark(marks, [note], ScoreMark.hit);

    expect(marks[note], ScoreMark.hit);

    applyPlayedMark(marks, [note], ScoreMark.miss);
    expect(marks[note], ScoreMark.hit);
  });

  test('a note that scrolls past its window with no pluck is a miss', () {
    final waiting = _note(midi: 64, timeMs: 1000);
    final gone = _note(midi: 59, timeMs: 0);
    final marks = <TabNote, ScoreMark>{};

    expireUnplayed(marks, [waiting, gone], 250);
    expect(marks.containsKey(waiting), isFalse);
    expect(marks.containsKey(gone), isFalse);

    expireUnplayed(marks, [waiting, gone], 251);
    expect(marks[gone], ScoreMark.miss);
    expect(marks.containsKey(waiting), isFalse);
  });
}
