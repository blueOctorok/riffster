import '../models/fretting_finger.dart';
import '../models/tab_note.dart';

/// The strings an index-finger barre holds at one moment.
class IndexBarre {
  const IndexBarre({required this.topString, required this.bottomString});

  /// Staff string 1 is the high E, so this is the smaller string number.
  final int topString;
  final int bottomString;
}

/// The index finger is barring when it holds the same fret on two strings
/// and nothing between them is open or lower. Notes on the strings in
/// between are inside the barre, even when another finger frets them higher.
IndexBarre? indexBarre(Iterable<TabNote> sounding) {
  final held = sounding
      .where((note) => note.finger == FrettingFinger.indexFinger && note.fret > 0)
      .toList();
  if (held.length < 2) return null;

  final fret = held.first.fret;
  if (held.any((note) => note.fret != fret)) return null;

  held.sort((a, b) => a.string.compareTo(b.string));
  final top = held.first.string;
  final bottom = held.last.string;
  if (bottom <= top) return null;

  for (var string = top + 1; string < bottom; string++) {
    final between = sounding.where((note) => note.string == string);
    if (between.any((note) => note.fret < fret)) return null;
  }
  return IndexBarre(topString: top, bottomString: bottom);
}
