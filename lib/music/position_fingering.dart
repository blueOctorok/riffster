import '../models/fretting_finger.dart';
import '../models/tab_note.dart';
import 'chord_book.dart';

const _fingersByOffset = <FrettingFinger>[
  FrettingFinger.indexFinger,
  FrettingFinger.middle,
  FrettingFinger.ring,
  FrettingFinger.pinky,
];

/// Notes closer than this are one gesture. The index finger can move to a
/// new string if the player has longer than this.
const _stringHopMs = 450;

/// A fret stays in the hand this long after it was played. Longer than that,
/// and it is no longer reserving a finger.
const _handMemoryMs = 1200;

/// Fills fingers the file left blank.
///
/// A chord the book knows takes that grip's fingers, so an open G in a
/// song is the same hand the practice screen will teach. Anything the book
/// does not know gives the lower strings the earlier fingers. Two notes
/// share a finger only when that finger can really hold both, or when the
/// lowest fret is a wide barre. A melody is different: an empty fret is a
/// small reach, so the next finger takes the next note that is actually
/// played. That keeps the pinky off a fret that sits one fret above the
/// middle finger. A fast hop across strings on the same fret gives each
/// string its own finger, because one finger cannot jump and come back at
/// that speed. A stored finger is kept. Open strings stay hollow. A shape
/// the hand cannot cover stays hollow.
List<TabNote> assignPositionFingers(List<TabNote> notes) {
  if (notes.isEmpty) return notes;

  final times = notes.map((note) => note.timeMs).toSet().toList()..sort();
  final beats = <List<int>>[
    for (final time in times)
      [
        for (var i = 0; i < notes.length; i++)
          if (notes[i].timeMs == time) i,
      ],
  ];

  final assigned = List<FrettingFinger?>.filled(notes.length, null);
  // Melody notes still close enough to reserve a finger.
  final live = <int>[];
  for (final beat in beats) {
    if (_isChord(notes, beat)) {
      _assignChord(notes, beat, assigned);
      live.clear();
      continue;
    }

    final now = notes[beat.first].timeMs;
    live.removeWhere((index) {
      final note = notes[index];
      final stillRinging = note.timeMs + note.durationMs >= now;
      return !stillRinging && now - note.timeMs > _handMemoryMs;
    });

    final pending = [
      for (final index in beat)
        if (notes[index].finger == null && notes[index].fret > 0) index,
    ];
    if (pending.isEmpty) continue;

    var packed = _packFrets([
      for (final index in live) notes[index].fret,
      for (final index in pending) notes[index].fret,
    ]);
    // The new note does not fit the frets still in the hand, so the hand
    // moves. Drop the oldest fret until the shape fits.
    while (packed == null && live.isNotEmpty) {
      live.removeAt(0);
      packed = _packFrets([
        for (final index in live) notes[index].fret,
        for (final index in pending) notes[index].fret,
      ]);
    }
    if (packed == null) continue;
    // A lower fret can arrive after a higher one. Notes still in the hand
    // take the new finger, so a 9 played just before a 7 becomes the middle
    // finger instead of staying the index.
    for (final index in [...live, ...pending]) {
      final finger = packed[notes[index].fret];
      if (finger != null) assigned[index] = finger;
    }
    live.addAll(pending);
  }
  _spreadStringHops(notes, beats, assigned);

  return [
    for (var i = 0; i < notes.length; i++)
      assigned[i] == null ? notes[i] : notes[i].withFinger(assigned[i]!),
  ];
}

/// Two fretted notes that still need a finger are a chord. A finger the
/// file already stored does not count, so it cannot pull a melody note out
/// of the phrase it belongs to.
bool _isChord(List<TabNote> notes, List<int> indexes) {
  var needing = 0;
  for (final index in indexes) {
    final note = notes[index];
    if (note.finger == null && note.fret > 0) needing++;
  }
  return needing >= 2;
}

void _assignChord(List<TabNote> notes, List<int> indexes, List<FrettingFinger?> assigned) {
  final pending = [
    for (final index in indexes)
      if (notes[index].finger == null && notes[index].fret > 0) index,
  ];
  if (pending.isEmpty) return;

  // A known grip wins over the guess. The book is also what chord practice
  // will show, so the song and the practice screen stay on one hand.
  final grip = matchingGrip([for (final index in indexes) notes[index]]);
  if (grip != null) {
    for (final index in pending) {
      final finger = grip.fingerOn(notes[index].string);
      if (finger != null) assigned[index] = finger;
    }
    return;
  }

  if (_span([for (final index in pending) notes[index].fret]) > 4) return;

  // Each fretted note starts alone. Notes join a finger only when every
  // string between them is the same fret. A higher fret in between, as in
  // an open D, means two fingers.
  var holds = [for (final index in pending) <int>[index]];
  holds = _mergeMatchingFrets(notes, indexes, holds);
  final lowest = pending.map((index) => notes[index].fret).reduce((a, b) => a < b ? a : b);
  holds = _mergeLowestBarre(notes, holds, lowest, wideOnly: true);
  // Five different frets and only four fingers: the lowest fret becomes
  // the barre so the rest of the chord still fits.
  if (holds.length > 4) {
    holds = _mergeLowestBarre(notes, holds, lowest, wideOnly: false);
  }

  holds.sort((a, b) {
    final fretOrder = notes[a.first].fret.compareTo(notes[b.first].fret);
    if (fretOrder != 0) return fretOrder;
    return _bassString(notes, b).compareTo(_bassString(notes, a));
  });

  for (var i = 0; i < holds.length && i < 4; i++) {
    for (final index in holds[i]) {
      assigned[index] = _fingersByOffset[i];
    }
  }
}

/// Joins notes a single finger can hold: same fret, and no different fret
/// sounding on a string between them.
List<List<int>> _mergeMatchingFrets(
  List<TabNote> notes,
  List<int> chord,
  List<List<int>> holds,
) {
  var merged = holds;
  var changed = true;
  while (changed) {
    changed = false;
    for (var i = 0; i < merged.length; i++) {
      for (var j = i + 1; j < merged.length; j++) {
        final together = [...merged[i], ...merged[j]];
        if (!_sameFretWithClearGap(notes, chord, together)) continue;
        merged = [
          for (var k = 0; k < merged.length; k++)
            if (k == i) together else if (k != j) merged[k],
        ];
        changed = true;
        break;
      }
      if (changed) break;
    }
  }
  return merged;
}

bool _sameFretWithClearGap(List<TabNote> notes, List<int> chord, List<int> hold) {
  final fret = notes[hold.first].fret;
  if (hold.any((index) => notes[index].fret != fret)) return false;
  final strings = hold.map((index) => notes[index].string).toList()..sort();
  for (var string = strings.first + 1; string < strings.last; string++) {
    final between = chord.where((index) => notes[index].string == string);
    if (between.any((index) => notes[index].fret != fret)) return false;
  }
  return true;
}

/// The lowest fret of a wide chord is an index barre, higher notes and all.
/// [wideOnly] keeps a small shape, such as open D, on separate fingers.
List<List<int>> _mergeLowestBarre(
  List<TabNote> notes,
  List<List<int>> holds,
  int lowest, {
  required bool wideOnly,
}) {
  final barre = <int>[];
  final rest = <List<int>>[];
  for (final hold in holds) {
    if (notes[hold.first].fret == lowest) {
      barre.addAll(hold);
    } else {
      rest.add(hold);
    }
  }
  if (barre.length < 2) return holds;
  final strings = barre.map((index) => notes[index].string);
  final span = strings.reduce((a, b) => a > b ? a : b) - strings.reduce((a, b) => a < b ? a : b);
  if (wideOnly && span < 3) return holds;
  return [barre, ...rest];
}

int _bassString(List<TabNote> notes, List<int> hold) {
  return hold.map((index) => notes[index].string).reduce((a, b) => a > b ? a : b);
}

/// Lowest fret is the index finger. The next played fret uses the next
/// finger when it is adjacent or one fret away. A wider hole skips a finger,
/// which is the pinky reaching four frets up. Null means the hand cannot
/// hold the shape, so the caller starts a new position.
Map<int, FrettingFinger>? _packFrets(List<int> frets) {
  if (frets.isEmpty) return {};
  final unique = frets.toSet().toList()..sort();
  if (unique.length > 4 || unique.last - unique.first > 4) return null;

  final packed = <int, FrettingFinger>{unique.first: _fingersByOffset[0]};
  var finger = 0;
  for (var i = 1; i < unique.length; i++) {
    final gap = unique[i] - unique[i - 1];
    final step = gap <= 2 ? 1 : gap - 1;
    finger += step;
    if (finger > 3) return null;
    packed[unique[i]] = _fingersByOffset[finger];
  }
  return packed;
}

/// A flurry on one fret, across strings, cannot be one finger hopping.
/// The first string keeps the phrase finger. Each new string takes the next
/// finger, and a return to a string reuses the finger already working there.
/// Notes that ring together stay on the phrase finger, because that is a barre.
void _spreadStringHops(
  List<TabNote> notes,
  List<List<int>> beats,
  List<FrettingFinger?> assigned,
) {
  final melody = <int>[
    for (final beat in beats)
      if (!_isChord(notes, beat))
        for (final index in beat)
          if (assigned[index] != null) index,
  ];

  var start = 0;
  while (start < melody.length) {
    var end = start;
    while (end + 1 < melody.length && _sameFretHop(notes, melody[end], melody[end + 1])) {
      end++;
    }
    final run = melody.sublist(start, end + 1);
    final strings = run.map((index) => notes[index].string).toSet();
    if (strings.length > 1) _spreadRun(notes, run, assigned);
    start = end + 1;
  }
}

bool _sameFretHop(List<TabNote> notes, int previous, int next) {
  final before = notes[previous];
  final after = notes[next];
  if (before.fret != after.fret) return false;
  if (after.timeMs - before.timeMs > _stringHopMs) return false;
  // Still sounding when the next note starts: one finger is holding both.
  return before.timeMs + before.durationMs <= after.timeMs + 30;
}

void _spreadRun(List<TabNote> notes, List<int> run, List<FrettingFinger?> assigned) {
  final start = _fingersByOffset.indexOf(assigned[run.first]!);
  var cursor = start;
  final direction = start == 3 ? -1 : 1;
  final byString = <int, FrettingFinger>{};
  for (final index in run) {
    final string = notes[index].string;
    final held = byString[string];
    if (held != null) {
      assigned[index] = held;
      continue;
    }
    final finger = _fingersByOffset[cursor];
    byString[string] = finger;
    assigned[index] = finger;
    final next = cursor + direction;
    if (next >= 0 && next <= 3) cursor = next;
  }
}

int _span(List<int> frets) {
  var low = frets.first;
  var high = frets.first;
  for (final fret in frets) {
    if (fret < low) low = fret;
    if (fret > high) high = fret;
  }
  return high - low;
}
