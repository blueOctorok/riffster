import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/music/riff_text.dart';

void main() {
  test('a name and a length become a pitch at a time', () {
    // 100 bpm, so a beat is 600 ms.
    final read = readRiffText('E1:1 G1:.5 A1:.5 Bb1:2', tempoBpm: 100);

    expect(read.pitches.map((pitch) => pitch.midi), [28, 31, 33, 34]);
    expect(read.pitches.map((pitch) => pitch.timeMs), [0, 600, 900, 1200]);
    // A note sounds for most of its length, with a little air after.
    expect(read.pitches.first.durationMs, 510);
  });

  test('octaves change at C, and sharps and flats move a semitone', () {
    final read = readRiffText('B1:1 C2:1 C#2:1 Db2:1', tempoBpm: 100);

    expect(read.pitches.map((pitch) => pitch.midi), [35, 36, 37, 37]);
  });

  test('a rest takes its time and makes no note', () {
    final read = readRiffText('-:1 E1:1 -:1.5 E1:.5', tempoBpm: 100);

    expect(read.pitches.map((pitch) => pitch.timeMs), [600, 2100]);
  });

  test('a length can be a fraction, and three thirds are one beat', () {
    final read = readRiffText(
      'A1:2/3 A1:1/3 A1:1/3 A1:1/3 A1:1/3 A1:2 | A1:4',
      tempoBpm: 100,
    );

    expect(read.pitches.map((pitch) => pitch.timeMs), [
      0,
      400,
      600,
      800,
      1000,
      1200,
      2400,
    ]);
  });

  test('every bar line gives a bar of the right length', () {
    final four = readRiffText('E1:4 | E1:2 E1:2 |', tempoBpm: 120);
    expect(four.bars.map((bar) => (bar.startMs, bar.endMs, bar.beats)), [
      (0, 2000, 4),
      (2000, 4000, 4),
    ]);

    final three = readRiffText('E1:3 | E1:3', tempoBpm: 120, beatsPerBar: 3);
    expect(three.bars.map((bar) => (bar.startMs, bar.endMs, bar.beats)), [
      (0, 1500, 3),
      (1500, 3000, 3),
    ]);
  });

  test('a bar that does not add up is a mistake, and says which bar', () {
    expect(
      () => readRiffText('E1:4 | E1:1 E1:1 E1:1', tempoBpm: 100),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Bar 2 holds 3.0 beats'),
        ),
      ),
    );
  });

  test('anything that is not a note is a mistake', () {
    expect(() => readRiffText('H1:4', tempoBpm: 100), throwsFormatException);
    expect(() => readRiffText('E1', tempoBpm: 100), throwsFormatException);
  });
}
