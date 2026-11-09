import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/music/chord_course.dart';
import 'package:riffster/music/chord_lane.dart';

void main() {
  test('a dropped chord is the same grip the course teaches', () {
    final block = chordBlocks.firstWhere((item) => item.label == 'G');
    final built = songFromLane([LaneChord(block)]);
    final course = chordCourse.firstWhere((song) => song.title == 'G');

    expect(built.title, 'G');
    expect(built.notes.length, course.notes.length);
    expect(built.notes.first.timeMs, course.notes.first.timeMs);
    expect(built.notes.first.finger, course.notes.first.finger);
    expect(built.notes.first.midi, course.notes.first.midi);
  });

  test('the next chord starts when the one before it ends', () {
    final g = chordBlocks.firstWhere((item) => item.label == 'G');
    final c = chordBlocks.firstWhere((item) => item.label == 'C');
    final first = LaneChord(g, durationMs: 1500);
    final built = songFromLane([first, LaneChord(c)]);

    expect(built.title, 'G · C');
    expect(built.notes.first.timeMs, 500);
    expect(
      built.notes.firstWhere((note) => note.midi == 48).timeMs,
      2000,
    );
  });

  test('a finger on the same fret can stay for the next shape', () {
    final em = chordBlocks.firstWhere((item) => item.label == 'Em');
    final e = chordBlocks.firstWhere((item) => item.label == 'E');
    final g = chordBlocks.firstWhere((item) => item.label == 'G');
    final c = chordBlocks.firstWhere((item) => item.label == 'C');

    expect(fingerStays(em.grip, e.grip), isTrue);
    expect(fingerStays(g.grip, c.grip), isFalse);
  });

  test('barre and sevenths are shelves of the same book', () {
    expect(
      chordBlocks
          .where((block) => block.shelf == ChordShelf.barre)
          .map((block) => block.label),
      ['Bm barre'],
    );
    expect(
      chordBlocks
          .where((block) => block.shelf == ChordShelf.seventh)
          .map((block) => block.label),
      ['Em7', 'F#7'],
    );
  });
}