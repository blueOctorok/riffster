import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/models/tab_song.dart';
import 'package:riffster/music/practice_run.dart';
import 'package:riffster/music/score_note.dart';

/// Four quarter notes at 120 bpm: one every 500 ms, so a bar is 2000 ms.
/// The pitches climb, so a test can play a right note or a wrong one.
TabSong _fourNotes() {
  return const TabSong(
    title: 'Four',
    tempoBpm: 120,
    notes: [
      TabNote(timeMs: 0, string: 1, fret: 0, durationMs: 400, midi: 60),
      TabNote(timeMs: 500, string: 1, fret: 1, durationMs: 400, midi: 61),
      TabNote(timeMs: 1000, string: 1, fret: 2, durationMs: 400, midi: 62),
      TabNote(timeMs: 1500, string: 1, fret: 3, durationMs: 400, midi: 63),
    ],
  );
}

void _wait(PracticeRun run, int milliseconds) {
  // Small steps, the way frames arrive.
  for (var left = milliseconds; left > 0; left -= 10) {
    run.advance(Duration(milliseconds: left < 10 ? left : 10));
  }
}

void main() {
  test('a song waits one bar before its first note, then counts in', () {
    final run = PracticeRun(_fourNotes());

    expect(run.positionMs, -2000);
    expect(run.countIn, isNull);

    run.play();
    expect(run.positionMs, -2000);
    expect(run.countIn!.beatAt(run.positionMs), 0);

    _wait(run, 1250);
    // Two and a half beats in: the count is showing its third number.
    expect(run.countIn!.beatAt(run.positionMs), closeTo(2.5, 0.01));

    _wait(run, 760);
    expect(run.positionMs, closeTo(10, 0.01));
    expect(run.countIn, isNull);
  });

  test('right notes on time are hits and build a streak', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 2000);
    run.pluck(60, latencyMs: 0);
    _wait(run, 520);
    run.pluck(61, latencyMs: 20);

    expect(run.lastMark, ScoreMark.hit);
    expect(run.streak, 2);
    expect(run.summary.onTime, 2);
    expect(run.effects, hasLength(2));
    // 20 ms on the clock, minus the 20 ms the sound took to arrive.
    expect(run.averageTimingMs, closeTo(0, 0.01));
  });

  test(
    'a wrong pitch is a stray note, and the right one can still save it',
    () {
      final run = PracticeRun(_fourNotes())..play();

      _wait(run, 2000);
      run.pluck(72, latencyMs: 0);
      // A wrong note is not a verdict on a played note, so the strip
      // keeps quiet about it.
      expect(run.lastMark, isNull);
      expect(run.heardMidi, isNull);
      expect(run.strayNotes, 1);
      // The note is still open. The X waits until the bubble has gone.
      expect(run.summary.missed, 0);

      _wait(run, 40);
      run.pluck(60, latencyMs: 0);
      expect(run.summary.missed, 0);
      expect(run.summary.onTime, 1);
      expect(run.streak, 1);
    },
  );

  test('how early or late the last note was is kept for the gauge', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 2000 + 30);
    run.pluck(60, latencyMs: 0);
    expect(run.lastTimingMs, closeTo(30, 0.01));

    // 150 ms before the second note: the same beat, and early.
    _wait(run, 320);
    run.pluck(61, latencyMs: 0);
    expect(run.lastMark, ScoreMark.early);
    expect(run.lastTimingMs, closeTo(-150, 0.01));
  });

  test('an extra sound after a hit leaves the feedback strip alone', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 2000 + 30);
    run.pluck(60, latencyMs: 0);

    // The same ringing string, read a second time an octave up.
    _wait(run, 100);
    run.pluck(72, latencyMs: 0);

    expect(run.heardMidi, 60);
    expect(run.lastMark, ScoreMark.hit);
    expect(run.lastTimingMs, closeTo(30, 0.01));
    expect(run.summary.missed, 0);
    expect(run.strayNotes, 1);
  });

  test('while paused, the strip names a sound and gives no verdict', () {
    final run = PracticeRun(_fourNotes());

    run.pluck(60, latencyMs: 0);

    expect(run.heardMidi, 60);
    expect(run.lastMark, isNull);
    expect(run.lastTimingMs, isNull);
  });

  test('a sound with no pitch counts for a chord and never for a note', () {
    final single = PracticeRun(_fourNotes())..play();
    _wait(single, 2000);
    single.pluck(null, latencyMs: 0);

    expect(single.lastMark, isNull);
    expect(single.marks, isEmpty);
    expect(single.strayNotes, 0);

    final chord = PracticeRun(
      const TabSong(
        title: 'Chord',
        tempoBpm: 120,
        notes: [
          TabNote(timeMs: 0, string: 1, fret: 0, durationMs: 400, midi: 64),
          TabNote(timeMs: 0, string: 2, fret: 0, durationMs: 400, midi: 59),
        ],
      ),
    )..play();
    _wait(chord, 2000);
    chord.pluck(null, latencyMs: 0);

    expect(chord.lastMark, ScoreMark.hit);
    expect(chord.summary.onTime, 1);
  });

  test('a note the clock leaves behind is a miss and ends the streak', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 2000);
    run.pluck(60, latencyMs: 0);
    expect(run.streak, 1);

    // The second note is at 500. Its window closes 250 ms after that.
    _wait(run, 740);
    expect(run.summary.missed, 0);
    _wait(run, 20);
    expect(run.summary.missed, 1);
    expect(run.streak, 0);
    expect(run.bestStreak, 1);
  });

  test('a wrong pitch marks the note only once its window has closed', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 2000);
    run.pluck(72, latencyMs: 0);
    expect(run.summary.missed, 0);

    // The note is at 0. Its window closes 250 ms later, after the
    // circle has left the line.
    _wait(run, 240);
    expect(run.summary.missed, 0);
    _wait(run, 20);
    expect(run.summary.missed, 1);
  });

  test('a sound during the count-in is not judged', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 900);
    run.pluck(60, latencyMs: 0);

    expect(run.heardMidi, isNull);
    expect(run.lastMark, isNull);
    expect(run.strayNotes, 0);
    expect(run.marks, isEmpty);
  });

  test('the run ends a moment after the last note', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 2000 + 1900 + PracticeRun.runOutMs);

    expect(run.playing, isFalse);
    expect(run.finished, isTrue);
    expect(run.summary.missed, 4);

    // Play after the end starts a fresh run from the count.
    run.play();
    expect(run.finished, isFalse);
    expect(run.positionMs, -2000);
    expect(run.marks, isEmpty);
  });

  test('pausing in the count-in starts the count over', () {
    final run = PracticeRun(_fourNotes())..play();

    _wait(run, 1500);
    run.pause();
    expect(run.positionMs, closeTo(-500, 0.01));
    expect(run.countIn, isNull);

    run.play();
    // One bar back from here is before the rest spot, so it starts there.
    expect(run.positionMs, -2000);
  });

  test('pausing backs up one bar and keeps the marks behind it', () {
    final longer = PracticeRun(
      TabSong(
        title: 'Longer',
        tempoBpm: 120,
        notes: [
          for (var i = 0; i < 12; i++)
            TabNote(
              timeMs: i * 500,
              string: 1,
              fret: 0,
              durationMs: 400,
              midi: 60,
            ),
        ],
      ),
    )..play();
    _wait(longer, 2000);
    for (var i = 0; i < 6; i++) {
      longer.pluck(60, latencyMs: 0);
      _wait(longer, 500);
    }
    longer.pause();
    expect(longer.positionMs, closeTo(3000, 0.01));
    expect(longer.summary.onTime, 6);

    longer.play();
    expect(longer.positionMs, closeTo(1000, 0.01));
    expect(longer.countIn, isNotNull);
    // The six notes behind the pause keep their hits.
    expect(longer.summary.onTime, 6);

    // A pluck while the old notes go by again is not judged.
    _wait(longer, 500);
    longer.pluck(60, latencyMs: 0);
    expect(longer.streak, 6);
    expect(longer.summary.onTime, 6);

    _wait(longer, 1500);
    longer.pluck(60, latencyMs: 0);
    expect(longer.lastMark, ScoreMark.hit);
    expect(longer.summary.onTime, 7);
  });

  test('half speed moves the clock half as fast', () {
    final run = PracticeRun(_fourNotes())
      ..speed = 0.5
      ..play();

    _wait(run, 4000);
    expect(run.positionMs, closeTo(0, 0.01));

    // 150 real milliseconds at half speed is 75 ms of the song, which is
    // inside the circle, so it is on time. The clock itself did move
    // half as far: the note is only 75 ms of song time behind.
    _wait(run, 150);
    run.pluck(60, latencyMs: 0);
    expect(run.lastMark, ScoreMark.hit);
    expect(run.lastTimingMs, closeTo(75, 0.01));

    // The next note, struck 200 ms of the song after it was due. That is
    // past the circle, so it is late. 200 ms of the song is 400 real
    // milliseconds at this speed; the circle did not get any smaller.
    _wait(run, 1250);
    run.pluck(61, latencyMs: 0);
    expect(run.positionMs, closeTo(700, 0.01));
    expect(run.lastMark, ScoreMark.late);
    expect(run.lastTimingMs, closeTo(200, 0.01));
    expect(run.averageTimingMs, closeTo((75 + 200) / 2, 0.01));
  });

  test('a loop counts in once, then wraps with no gap', () {
    final run = PracticeRun(_fourNotes())..loop = const LoopRange(0, 2000);

    run.play();
    expect(run.positionMs, -2000);

    _wait(run, 2000 + 1990);
    expect(run.loopPass, 0);
    _wait(run, 20);
    expect(run.loopPass, 1);
    expect(run.positionMs, closeTo(10, 0.01));
    expect(run.countIn, isNull);
    expect(run.playing, isTrue);
  });

  test('the first note of a loop can be played just before the wrap', () {
    final run = PracticeRun(_fourNotes())..loop = const LoopRange(0, 2000);
    run.play();

    // 30 ms before the loop ends. The nearest note is the first one of
    // the next pass, not the last one of this pass.
    _wait(run, 2000 + 1970);
    run.pluck(60, latencyMs: 0);
    expect(run.lastMark, ScoreMark.hit);

    _wait(run, 400);
    expect(run.loopPass, 1);
    // The early hit came along into the new pass.
    expect(run.marks.values, [ScoreMark.hit]);
    // The last note of the old pass was never played. It is missed
    // after the wrap, once its own window has closed.
    expect(
      run.lastPassMarks.values.where((m) => m == ScoreMark.miss),
      hasLength(4),
    );
  });

  test('the last note of a loop can be played just after the wrap', () {
    final run = PracticeRun(
      const TabSong(
        title: 'Two',
        tempoBpm: 120,
        notes: [
          TabNote(timeMs: 400, string: 1, fret: 0, durationMs: 300, midi: 60),
          TabNote(timeMs: 1900, string: 1, fret: 3, durationMs: 100, midi: 63),
        ],
      ),
    )..loop = const LoopRange(0, 2000);
    run.play();
    // The count ends on the loop's first note, at 400.
    expect(run.positionMs, -1600);

    // The last note is at 1900 and the loop wraps at 2000. A pluck 160 ms
    // after that note arrives when the clock is already back at 60.
    _wait(run, 1600 + 2060);
    expect(run.loopPass, 1);
    run.pluck(63, latencyMs: 0);

    expect(run.lastMark, ScoreMark.late);
    expect(run.marks, isEmpty);
    expect(run.lastPassMarks.values.last, ScoreMark.late);
  });

  test('a finished run can be looked over, and Play makes the notes ahead '
      'playable again', () {
    final run = PracticeRun(_fourNotes())..play();
    _wait(run, 2000 + 1900 + PracticeRun.runOutMs);
    expect(run.summary.missed, 4);

    // Dragging back keeps every mark on the staff.
    run.seek(900);
    expect(run.finished, isFalse);
    expect(run.positionMs, 900);
    expect(run.summary.missed, 4);

    // Play judges from the slider forward. The notes behind it keep
    // their marks.
    run.play();
    expect(run.summary.missed, 2);
    _wait(run, 2000 + 110);
    run.pluck(62, latencyMs: 0);
    expect(run.lastMark, ScoreMark.hit);
  });

  test('moving the clock while it runs clears the notes ahead at once', () {
    final run = PracticeRun(_fourNotes())..play();
    _wait(run, 2000 + 1900);
    expect(run.summary.missed, 4);

    run.seek(900);

    expect(run.summary.missed, 2);
  });

  test('a lane edited while it plays keeps its place', () {
    final run = PracticeRun(_fourNotes())..play();
    _wait(run, 2600);

    run.load(_fourNotes(), keepPlace: true);

    expect(run.playing, isTrue);
    expect(run.positionMs, closeTo(600, 0.01));
    expect(run.marks, isEmpty);
  });

  test('scoredSpeed is the slowest the song was played', () {
    final run = PracticeRun(_fourNotes())..play();
    expect(run.scoredSpeed, 1);

    run.speed = 0.7;
    _wait(run, 50);
    expect(run.scoredSpeed, 0.7);

    run.speed = 1;
    _wait(run, 50);
    // Speeding back up does not raise the score's speed.
    expect(run.scoredSpeed, 0.7);

    run.restart();
    expect(run.scoredSpeed, 1);
  });

  test('judgedWholeSong is only true for one clean trip through', () {
    final run = PracticeRun(_fourNotes())..play();
    _wait(run, 2000);
    run.pluck(60, latencyMs: 0);
    for (final midi in [61, 62, 63]) {
      _wait(run, 500);
      run.pluck(midi, latencyMs: 0);
    }
    // Past the last note's length and the run-out.
    _wait(run, 400 + PracticeRun.runOutMs);
    expect(run.finished, isTrue);
    expect(run.judgedWholeSong, isTrue);

    // Starting at the third note leaves the first two unmarked.
    final mid = PracticeRun(_fourNotes());
    mid.seek(1000);
    mid.play();
    // Count-in ends on the note at 1000.
    _wait(mid, 2000);
    mid.pluck(62, latencyMs: 0);
    _wait(mid, 500);
    mid.pluck(63, latencyMs: 0);
    _wait(mid, 400 + PracticeRun.runOutMs);
    expect(mid.finished, isTrue);
    expect(mid.summary.judged, 2);
    expect(mid.judgedWholeSong, isFalse);

    // Going back after notes are marked patches a score together.
    final back = PracticeRun(_fourNotes())..play();
    _wait(back, 2000);
    back.pluck(60, latencyMs: 0);
    back.seek(0);
    back.play();
    _wait(back, 2000);
    back.pluck(60, latencyMs: 0);
    for (final midi in [61, 62, 63]) {
      _wait(back, 500);
      back.pluck(midi, latencyMs: 0);
    }
    _wait(back, 400 + PracticeRun.runOutMs);
    expect(back.finished, isTrue);
    expect(back.judgedWholeSong, isFalse);
  });
}
