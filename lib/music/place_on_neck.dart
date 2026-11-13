import '../models/instrument.dart';
import '../models/tab_note.dart';

/// A note before anyone has said where on the neck it is played.
typedef Pitch = ({int timeMs, int durationMs, int midi});

/// The highest fret a note is ever placed on. Some necks go to 24, but
/// every bass and every guitar has these.
const topPlacedFret = 20;

/// The frets one hand covers without moving: a finger for each.
const _handSpan = 4;

/// Moving the hand at all costs this much.
const _shiftCost = 1.0;

/// And this much more for every fret it travels. One long move is then
/// cheaper than several short ones, which is how a player thinks too.
const _shiftCostPerFret = 0.25;

/// Crossing to another string, for every string crossed.
const _crossingCost = 0.15;

/// A small pull toward the nut, for every fret a note sits above it.
/// It only settles a choice the hand does not care about.
const _fretHeightCost = 0.02;

/// The lowest and highest notes [instrument] can be given a place for.
({int lowest, int highest}) placedRange(Instrument instrument) {
  final open = instrument.openStringMidi;
  return (lowest: open.last, highest: open.first + topPlacedFret);
}

/// Picks a string and a fret for every pitch of a line, so the hand
/// moves as little as possible.
///
/// Most notes can be played in several places. D on a bass is the open
/// D string, the 5th fret of the A string, or the 10th of the E string.
/// Choosing one note at a time goes wrong, because the easy place for
/// this note can leave the hand far from the next one. So every way of
/// playing the whole line is weighed, and the cheapest one wins.
///
/// That sounds like too many ways to count, and it would be. The trick
/// is that the cost of a move depends only on where the hand is and
/// where it goes next. So for each note, and each place it could be
/// played, only the cheapest way of having got there is kept. The line
/// is walked once, and the answer is read back from the last note. This
/// is called dynamic programming.
///
/// [pitches] is one note at a time, in the order played. Throws an
/// [ArgumentError] for a pitch the neck does not have. Fingers are not
/// chosen here.
List<TabNote> placeOnNeck(
  List<Pitch> pitches, {
  required Instrument instrument,
}) {
  // The cheapest way to reach each place the latest note can be played.
  var routes = <_Route>[];
  for (final pitch in pitches) {
    final spots = _spotsFor(pitch.midi, instrument);
    if (spots.isEmpty) {
      throw ArgumentError.value(
        pitch.midi,
        'midi',
        'is not on the ${instrument.label.toLowerCase()} neck',
      );
    }
    final before = routes;
    routes = [for (final spot in spots) _cheapestRouteTo(spot, before)];
  }
  if (routes.isEmpty) return const [];

  // Each route remembers the one it grew from, so following those links
  // back from the cheapest ending spells out the whole line in reverse.
  final spots = <_Spot>[];
  for (
    _Route? route = routes.reduce((a, b) => a.cost <= b.cost ? a : b);
    route != null;
    route = route.before
  ) {
    spots.add(route.spot);
  }
  final placed = spots.reversed.toList();
  return [
    for (var i = 0; i < pitches.length; i++)
      TabNote(
        timeMs: pitches[i].timeMs,
        string: placed[i].string,
        fret: placed[i].fret,
        durationMs: pitches[i].durationMs,
        midi: pitches[i].midi,
      ),
  ];
}

/// One way to play one note: the string, the fret, and where the hand
/// is while it does.
class _Spot {
  const _Spot(this.string, this.fret, this.hand);

  /// The staff string: 1 is the top line.
  final int string;
  final int fret;

  /// The fret under the index finger.
  final int hand;
}

/// A way of playing the line up to one note, and what it cost.
class _Route {
  const _Route(this.spot, this.cost, this.before);

  final _Spot spot;
  final double cost;
  final _Route? before;
}

List<_Spot> _spotsFor(int midi, Instrument instrument) {
  final open = instrument.openStringMidi;
  final spots = <_Spot>[];
  for (var index = 0; index < open.length; index++) {
    final fret = midi - open[index];
    if (fret < 0 || fret > topPlacedFret) continue;
    // A fretted note can sit under any of the four fingers, which is
    // four places the hand could be. An open string needs no finger, so
    // the hand can be anywhere at all.
    final lowestHand = fret == 0 ? 1 : (fret - _handSpan + 1).clamp(1, fret);
    final highestHand = fret == 0 ? topPlacedFret - _handSpan + 1 : fret;
    for (var hand = lowestHand; hand <= highestHand; hand++) {
      spots.add(_Spot(index + 1, fret, hand));
    }
  }
  return spots;
}

_Route _cheapestRouteTo(_Spot spot, List<_Route> before) {
  final own = spot.fret * _fretHeightCost;
  if (before.isEmpty) return _Route(spot, own, null);
  _Route? best;
  var bestCost = double.infinity;
  for (final route in before) {
    final cost = route.cost + _moveCost(route.spot, spot);
    if (cost < bestCost) {
      bestCost = cost;
      best = route;
    }
  }
  return _Route(spot, bestCost + own, best);
}

double _moveCost(_Spot from, _Spot to) {
  final crossing = (to.string - from.string).abs() * _crossingCost;
  final frets = (to.hand - from.hand).abs();
  if (frets == 0) return crossing;
  final shift = _shiftCost + frets * _shiftCostPerFret;
  // An open string rings by itself, so the hand can travel while it
  // does. Players shift on an open string for exactly this reason. It
  // is still a move, only an easier one.
  return crossing + (to.fret == 0 ? shift / 2 : shift);
}
