import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/music/chord_course.dart';
import 'package:riffster/music/chord_name.dart';

void main() {
  test('a course chord uses the same fingers as the book', () {
    final g = chordCourse.firstWhere((song) => song.title == 'G');

    expect(chordName(g.notes), 'G');
    expect(
      g.notes.firstWhere((note) => note.string == 1).finger,
      FrettingFinger.ring,
    );
    expect(
      g.notes.firstWhere((note) => note.string == 5).finger,
      FrettingFinger.indexFinger,
    );
    expect(
      g.notes.firstWhere((note) => note.string == 6).finger,
      FrettingFinger.middle,
    );
    expect(g.notes.firstWhere((note) => note.string == 4).finger, isNull);
  });

  test('the barre step is the index barre, with its own title', () {
    final barre = chordCourse.firstWhere((song) => song.title == 'Bm barre');

    expect(chordName(barre.notes), 'Bm');
    expect(
      barre.notes.firstWhere((note) => note.string == 6).finger,
      FrettingFinger.indexFinger,
    );
    expect(
      barre.notes.firstWhere((note) => note.string == 5).finger,
      FrettingFinger.ring,
    );
    expect(
      barre.notes.firstWhere((note) => note.string == 4).finger,
      FrettingFinger.pinky,
    );
  });

  test('the last step is an original four-chord change', () {
    final change = chordCourse.last;
    final times = change.notes.map((note) => note.timeMs).toSet().toList()
      ..sort();

    expect(change.title, 'G · D · Em · C');
    expect(times, hasLength(4));
    expect(
      chordName(change.notes.where((note) => note.timeMs == times[0])),
      'G',
    );
    expect(
      chordName(change.notes.where((note) => note.timeMs == times[1])),
      'D',
    );
    expect(
      chordName(change.notes.where((note) => note.timeMs == times[2])),
      'Em',
    );
    expect(
      chordName(change.notes.where((note) => note.timeMs == times[3])),
      'C',
    );
  });
}
