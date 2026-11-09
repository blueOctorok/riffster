import '../models/fretting_finger.dart';
import 'chord_book.dart';

/// How many fret spaces a chart shows when the shape fits.
const chartFretCount = 4;

const _pitchLetters = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// One string on a chord chart, low E first.
class ChartString {
  const ChartString({required this.fret, this.finger, this.pitch});

  /// Null is muted. 0 is open. Anything else is the fret number.
  final int? fret;
  final FrettingFinger? finger;

  /// The letter name, such as F#. Null when the string is muted.
  final String? pitch;
}

/// A finger laid across more than one string at the same fret.
class ChartBarre {
  const ChartBarre({
    required this.finger,
    required this.fret,
    required this.firstColumn,
    required this.lastColumn,
  });

  final FrettingFinger finger;
  final int fret;

  /// Columns are low E at 0 through high e at 5.
  final int firstColumn;
  final int lastColumn;
}

/// A grip turned into the picture on a chord card.
///
/// [startFret] is 0 when the nut is drawn. A shape that sits higher
/// than four frets starts at its lowest fret instead, so a barre at
/// the 7th fret is not a speck at the bottom of a long neck.
class ChordChart {
  const ChordChart({
    required this.startFret,
    required this.fretCount,
    required this.strings,
    required this.barres,
  });

  final int startFret;
  final int fretCount;
  final List<ChartString> strings;
  final List<ChartBarre> barres;

  bool covers(int column) {
    final string = strings[column];
    final fret = string.fret;
    final finger = string.finger;
    if (fret == null || finger == null) return false;
    for (final barre in barres) {
      if (barre.fret == fret &&
          barre.finger == finger &&
          column >= barre.firstColumn &&
          column <= barre.lastColumn) {
        return true;
      }
    }
    return false;
  }
}

ChordChart chartFor(ChordGrip grip) {
  var lowest = 99;
  var highest = 0;
  var open = false;
  for (final fret in grip.frets) {
    if (fret == null) continue;
    if (fret == 0) {
      open = true;
      continue;
    }
    if (fret < lowest) lowest = fret;
    if (fret > highest) highest = fret;
  }

  // An open string needs the nut, or the O has nothing to sit above.
  // A shape that fits in four frets is also drawn from the nut, which
  // is how a beginner chart shows G or C. Higher shapes get a window.
  final fromNut = open || highest <= chartFretCount;
  final start = fromNut ? 0 : lowest;
  final count = fromNut
      ? (highest < chartFretCount ? chartFretCount : highest)
      : _atLeast(chartFretCount, highest - lowest + 1);

  final strings = <ChartString>[
    for (var string = 6; string >= 1; string--) _column(grip, string),
  ];

  return ChordChart(
    startFret: start,
    fretCount: count,
    strings: strings,
    barres: _barres(strings),
  );
}

ChartString _column(ChordGrip grip, int string) {
  final fret = grip.frets[string - 1];
  final finger = fret == null || fret == 0 ? null : grip.fingerOn(string);
  final pitch = fret == null
      ? null
      : _pitchLetters[(openStringMidi[string - 1] + fret) % 12];
  return ChartString(fret: fret, finger: finger, pitch: pitch);
}

List<ChartBarre> _barres(List<ChartString> strings) {
  final columns = <(FrettingFinger, int), List<int>>{};
  for (var column = 0; column < strings.length; column++) {
    final finger = strings[column].finger;
    final fret = strings[column].fret;
    if (finger == null || fret == null || fret == 0) continue;
    columns.putIfAbsent((finger, fret), () => []).add(column);
  }
  return [
    for (final entry in columns.entries)
      if (entry.value.length >= 2)
        ChartBarre(
          finger: entry.key.$1,
          fret: entry.key.$2,
          firstColumn: entry.value.reduce((a, b) => a < b ? a : b),
          lastColumn: entry.value.reduce((a, b) => a > b ? a : b),
        ),
  ];
}

int _atLeast(int floor, int value) => value < floor ? floor : value;
