import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/music/chord_book.dart';
import 'package:riffster/music/chord_chart.dart';

void main() {
  test('an open C reads x 3 2 0 1 0 from the nut', () {
    final chart = chartFor(openC);

    expect(chart.startFret, 0);
    expect(chart.strings.map((string) => string.fret), [null, 3, 2, 0, 1, 0]);
    expect(chart.strings[1].finger, FrettingFinger.ring);
    expect(chart.strings[2].finger, FrettingFinger.middle);
    expect(chart.strings[4].finger, FrettingFinger.indexFinger);
    expect(chart.strings.map((string) => string.pitch), [
      null,
      'C',
      'E',
      'G',
      'C',
      'E',
    ]);
  });

  test('a barre up the neck starts at its lowest fret', () {
    final chart = chartFor(barreBm);

    expect(chart.startFret, 7);
    expect(chart.barres, hasLength(1));
    expect(chart.barres.single.finger, FrettingFinger.indexFinger);
    expect(chart.barres.single.fret, 7);
    expect(chart.barres.single.firstColumn, 0);
    expect(chart.barres.single.lastColumn, 5);
  });

  test('a shape past the fourth fret keeps every dot in the window', () {
    final chart = chartFor(fSharp7);

    expect(chart.startFret, 2);
    expect(chart.fretCount, 4);
    expect(chart.strings[4].fret, 5);
    expect(chart.strings[4].finger, FrettingFinger.pinky);
  });
}
