import '../models/fretting_finger.dart';
import '../models/tab_note.dart';

/// One grip a player can hold, and the name that grip goes by.
///
/// [frets] and [fingers] run from staff string 1 (high e) to string 6
/// (low E). A null fret is a string this grip does not play. 0 is open,
/// and an open string has no finger. The practice screen reads this same
/// list, so a finger learned there is the finger a song will show.
class ChordGrip {
  const ChordGrip({required this.name, required this.frets, required this.fingers});

  final String name;
  final List<int?> frets;
  final List<FrettingFinger?> fingers;

  FrettingFinger? fingerOn(int string) => fingers[string - 1];
}

const _i = FrettingFinger.indexFinger;
const _m = FrettingFinger.middle;
const _r = FrettingFinger.ring;
const _p = FrettingFinger.pinky;

/// Familiar chord-chart order in the comments is low E to high e.
const chordBook = <ChordGrip>[
  // 3 2 0 0 0 3
  ChordGrip(name: 'G', frets: [3, 0, 0, 0, 2, 3], fingers: [_r, null, null, null, _i, _m]),
  // x 3 2 0 1 0
  ChordGrip(name: 'C', frets: [0, 1, 0, 2, 3, null], fingers: [null, _i, null, _m, _r, null]),
  // x x 0 2 3 2
  ChordGrip(name: 'D', frets: [2, 3, 2, 0, null, null], fingers: [_m, _r, _i, null, null, null]),
  // 0 2 2 1 0 0
  ChordGrip(name: 'E', frets: [0, 0, 1, 2, 2, 0], fingers: [null, null, _i, _r, _m, null]),
  // 0 2 2 0 0 0
  ChordGrip(name: 'Em', frets: [0, 0, 0, 2, 2, 0], fingers: [null, null, null, _r, _m, null]),
  // 0 2 2 0 3 0
  ChordGrip(name: 'Em7', frets: [0, 3, 0, 2, 2, 0], fingers: [null, _r, null, _m, _i, null]),
  // x 0 2 2 2 0
  ChordGrip(name: 'A', frets: [0, 2, 2, 2, 0, null], fingers: [null, _r, _m, _i, null, null]),
  // x 0 2 2 1 0
  ChordGrip(name: 'Am', frets: [0, 1, 2, 2, 0, null], fingers: [null, _i, _r, _m, null, null]),
  // x x 0 2 3 1
  ChordGrip(name: 'Dm', frets: [1, 3, 2, 0, null, null], fingers: [_i, _r, _m, null, null, null]),
  // 2 4 2 3 5 x
  ChordGrip(name: 'F#7', frets: [null, 5, 3, 2, 4, 2], fingers: [null, _p, _m, _i, _r, _i]),
  // x 2 4 4 3 2
  ChordGrip(name: 'Bm', frets: [2, 3, 4, 4, 2, null], fingers: [_i, _m, _r, _r, _i, null]),
  // 7 9 9 7 7 7
  ChordGrip(name: 'Bm', frets: [7, 7, 7, 9, 9, 7], fingers: [_i, _i, _i, _p, _r, _i]),
];

/// The grip these notes are holding, or null when none fits.
///
/// Every fretted note the grip needs has to be here, at that fret. A note
/// the file did write has to agree, including an open string the grip
/// mutes. Open strings the file left out still count when the grip has
/// three or more fretted notes. That is the written 3-2-3 open G: the tab
/// often skips the strings you just let ring. Two fretted notes are not
/// enough, because Em's two 2nds also sit inside other chords.
ChordGrip? matchingGrip(Iterable<TabNote> notes) {
  final played = <int, int>{};
  for (final note in notes) {
    if (note.string < 1 || note.string > 6) return null;
    played[note.string] = note.fret;
  }

  ChordGrip? best;
  var bestFretted = -1;
  for (final grip in chordBook) {
    if (!_matches(grip, played)) continue;
    final fretted = _frettedCount(grip);
    // Two grips can share notes. The one that asks for more fingers is
    // the shape the player is actually holding.
    if (fretted > bestFretted) {
      best = grip;
      bestFretted = fretted;
    }
  }
  return best;
}

bool _matches(ChordGrip grip, Map<int, int> played) {
  for (var string = 1; string <= 6; string++) {
    final wanted = grip.frets[string - 1];
    final heard = played[string];
    final required = wanted != null && wanted > 0;
    if (required && heard != wanted) return false;
    if (heard == null) continue;
    if (wanted == null || heard != wanted) return false;
  }

  if (_frettedCount(grip) >= 3) return true;
  for (var string = 1; string <= 6; string++) {
    if (grip.frets[string - 1] == 0 && !played.containsKey(string)) return false;
  }
  return true;
}

int _frettedCount(ChordGrip grip) {
  var count = 0;
  for (final fret in grip.frets) {
    if (fret != null && fret > 0) count++;
  }
  return count;
}
