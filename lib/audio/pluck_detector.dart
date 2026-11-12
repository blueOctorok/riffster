import 'dart:math' as math;
import 'dart:typed_data';

import '../models/instrument.dart';
import 'pitch.dart';

/// One note the player started.
class Pluck {
  const Pluck(this.midi, this.atSample);

  /// Null when a sound clearly began and no single pitch did. That is
  /// what a strummed chord looks like from here. If the pitch becomes
  /// clear later, a second pluck with the same [atSample] carries it.
  final int? midi;

  /// The sample the note began on, counted from the first sample the
  /// detector was given, at the input's own rate.
  final int atSample;

  @override
  String toString() => 'Pluck($midi at $atSample)';
}

/// Listening does not need the full sample rate. Thinning the audio
/// makes every pitch search cheaper. This is the lowest rate it is
/// thinned to: below it, the edge of a pluck starts to blur.
const _slowestRate = 12000;

/// The highest note still has to span this many samples per cycle,
/// or neighbouring frets land on the same whole number of samples.
const _samplesPerShortestCycle = 16;

/// Loud enough to be a string and not the room. A real pluck on the
/// cable is around a fifth of full scale.
const _floor = 0.03;

/// How much sharper than the last moment a sound must be to count as
/// a new pluck while a note is still ringing.
const _jump = 1.8;

/// The level is read this many times a second.
const _hopsPerSecond = 500;

/// After a pluck, the string needs this long before another one can
/// be told apart from the first one's own attack.
const _refractoryMs = 40;

/// A sound that still has no pitch after the wait is searched this
/// often. Every 4 hops is every 8 ms.
const _slowSearchEveryHops = 4;

enum _State { silent, identifying, holding }

/// Turns a stream of samples into plucks.
///
/// "When" and "what" are answered separately, because they cannot be
/// known at the same moment:
///
/// - When: the level jumps. That is known within a couple of
///   milliseconds, and it is the time a pluck is scored at.
/// - What: the wave has to repeat before its pitch can be read, and a
///   low bass E takes 24 ms to repeat once. So the pitch arrives
///   later, and is stamped with the earlier time.
///
/// Timing a note when its pitch is finally known would mark every low
/// note late, by an amount that depends on the fret.
///
/// A note can also start with no jump at all: a hammer-on, or a line
/// played with no gaps. So a ringing note is re-read every half
/// cycle. A different pitch is a new note. So is a wave that stops
/// repeating and then settles again, which is the same string plucked
/// a second time.
class PluckDetector {
  PluckDetector({required this.sampleRate, required Instrument instrument})
    : _lowestMidi = instrument.lowestMidi,
      _highestMidi = instrument.highestMidi,
      _thin = math.max(
        1,
        math.min(
          sampleRate ~/ _slowestRate,
          sampleRate ~/
              (hertzOfMidi(instrument.highestMidi) * _samplesPerShortestCycle),
        ),
      ) {
    _rate = sampleRate / _thin;
    // Half a semitone of room at each end, so a string that is a
    // little flat or sharp is still inside the range.
    _shortest = (_rate / hertzOfMidi(_highestMidi + 0.5)).floor();
    _longest = (_rate / hertzOfMidi(_lowestMidi - 0.5)).ceil();
    _hop = math.max(1, _rate ~/ _hopsPerSecond);
    _refractoryHops = _refractoryMs * _hopsPerSecond ~/ 1000;
    _longWindow = 2 * _longest;
    _keep = 5 * _longest;
    _giveUp = _longWindow + 12 * _hop;
    _heard = Float64List(4 * _keep);
    // One full cycle of the lowest note, and the two newest hops.
    final ring = (_longest / _hop).ceil() + 2;
    _levels = Float64List(ring);
    _edges = Float64List(ring);
  }

  final int sampleRate;
  final int _lowestMidi;
  final int _highestMidi;

  /// Every this-many input samples become one thinned sample.
  final int _thin;
  late final double _rate;
  late final int _shortest;
  late final int _longest;
  late final int _hop;
  late final int _refractoryHops;

  /// The most sound a pitch search ever needs: two cycles of the
  /// lowest note.
  late final int _longWindow;

  /// How much sound is kept to look back over.
  late final int _keep;

  /// A pluck with no pitch after this long is reported without one.
  late final int _giveUp;

  /// The newest thinned samples. `_heard[0]` is thinned sample [_base].
  late final Float64List _heard;
  var _base = 0;
  var _count = 0;
  var _samplesIn = 0;

  var _boxSum = 0.0;
  var _boxFill = 0;
  var _previous = 0.0;

  /// The loudest sample and the steepest step in the hop being filled.
  var _hopLevel = 0.0;
  var _hopEdge = 0.0;
  var _hopFill = 0;
  var _hopIndex = 0;
  late final Float64List _levels;
  late final Float64List _edges;

  var _state = _State.silent;
  var _onsetHop = -1 << 30;

  /// Where the note being worked on began, in thinned samples.
  var _onsetAt = 0;

  /// Sound before this belongs to the attack or to the note before.
  var _listenFrom = 0;

  /// True when the note being worked on is new even if it turns out
  /// to be the pitch already ringing. False when one check simply read
  /// a different pitch, which may only have been a wobble.
  var _newEvenIfSame = false;

  /// True when a pluck with no pitch must not be sent, or already was.
  var _placeholderSent = false;

  /// The cycle length of the note that was ringing, when this one
  /// began as a change of pitch. Null when it began with a pluck.
  double? _changedFrom;
  int? _candidate;
  int? _heldMidi;
  var _heldPeriod = 0.0;

  /// Where the clean sound of the ringing note starts.
  var _heldSince = 0;
  var _nextTrackAt = 0;

  /// How many input samples have been given so far.
  int get samplesHeard => _samplesIn;

  /// Feeds the next samples, each from -1 to 1, and returns the plucks
  /// that became known. Usually that is none.
  List<Pluck> hear(List<double> samples) {
    final found = <Pluck>[];
    for (final sample in samples) {
      _samplesIn++;
      // Averaging each group is the cheapest filter there is. It dulls
      // the top of the range, and a pitch search does not look there.
      _boxSum += sample;
      if (++_boxFill < _thin) continue;
      final thinned = _boxSum / _thin;
      _boxSum = 0;
      _boxFill = 0;

      if (_count - _base == _heard.length) {
        _heard.setRange(0, _keep, _heard, _heard.length - _keep);
        _base = _count - _keep;
      }
      _heard[_count - _base] = thinned;
      _count++;

      // The level says how loud. The step between two samples says how
      // sharp, and a fresh pluck is sharp even when it is no louder
      // than the note already ringing.
      _hopLevel = math.max(_hopLevel, thinned.abs());
      _hopEdge = math.max(_hopEdge, (thinned - _previous).abs());
      _previous = thinned;
      if (++_hopFill == _hop) _endHop(found);
    }
    return found;
  }

  void _endHop(List<Pluck> found) {
    final hop = _hopIndex++;
    final ring = _levels.length;
    final edge = _hopEdge;
    _levels[hop % ring] = _hopLevel;
    _edges[hop % ring] = edge;
    _hopLevel = 0;
    _hopEdge = 0;
    _hopFill = 0;

    // A low note swings from nothing to its peak inside one cycle, so
    // "how loud is it" only means something over a whole cycle. Both
    // of these are the largest value over the last cycle of the
    // lowest note. [reference] leaves out the two newest hops, so an
    // attack is compared with the sound before it began.
    var level = 0.0;
    var reference = 0.0;
    for (var back = 0; back < ring; back++) {
      final at = (hop - back) % ring;
      level = math.max(level, _levels[at]);
      if (back >= 2) reference = math.max(reference, _edges[at]);
    }

    // Going quiet needs half the level that starting does. With one
    // threshold, a note fading through it would start and stop over
    // and over.
    if (level < _floor / 2) {
      _state = _State.silent;
      _heldMidi = null;
      return;
    }
    if (level < _floor) return;

    final struck = _state == _State.silent || edge > _jump * reference;
    if (struck && hop - _onsetHop >= _refractoryHops) {
      _onsetHop = hop;
      // The first few milliseconds are the pick or the finger, not
      // the string. The pitch is read from what follows.
      _identifyFrom(
        _count + _hop,
        onsetAt: _count - _hop,
        newEvenIfSame: true,
        placeholder: true,
      );
      return;
    }

    switch (_state) {
      case _State.silent:
        break;
      case _State.identifying:
        _identify(found, hop);
      case _State.holding:
        if (_count >= _nextTrackAt) _track();
    }
  }

  void _identifyFrom(
    int listenFrom, {
    required int onsetAt,
    required bool newEvenIfSame,
    required bool placeholder,
    double? changedFrom,
  }) {
    _state = _State.identifying;
    _listenFrom = listenFrom;
    _onsetAt = onsetAt;
    _newEvenIfSame = newEvenIfSame;
    _placeholderSent = !placeholder;
    _changedFrom = changedFrom;
    _candidate = null;
  }

  /// Reads the pitch from everything heard since the note began. The
  /// window grows hop by hop, so a high note is known after a few
  /// milliseconds and a low one as soon as it has repeated.
  void _identify(List<Pluck> found, int hop) {
    final waiting = _count - _onsetAt >= _giveUp;
    if (waiting && !_placeholderSent) {
      found.add(Pluck(null, _onsetAt * _thin));
      _placeholderSent = true;
    }
    // Past the point of giving up, the search slows down. A chord can
    // ring unclear for seconds.
    if (waiting && hop % _slowSearchEveryHops != 0) return;

    final from = math.max(_listenFrom, _count - _longWindow);
    final read = _read(from, _count - from);
    if (read == null || read.midi != _candidate) {
      // One reading is not trusted. Two in a row that agree are.
      _candidate = read?.midi;
      return;
    }
    if (_newEvenIfSame || read.midi != _heldMidi) {
      final before = _changedFrom;
      final at = before == null
          ? _onsetAt
          : _changePoint(before, read.period);
      found.add(Pluck(read.midi, at * _thin));
    }
    _heldSince = _listenFrom;
    _hold(read);
  }

  void _hold(({int midi, double period}) read) {
    _state = _State.holding;
    _heldMidi = read.midi;
    _heldPeriod = read.period;
    // Twice per cycle is often enough to catch a change, and it keeps
    // the cost the same for a low note as for a high one.
    _nextTrackAt = _count + math.max(_hop, _heldPeriod ~/ 2);
  }

  /// Checks that the ringing note is still the same note.
  void _track() {
    final span = (_heldPeriod * 2.5).ceil();
    final from = _count - span;
    if (from < _listenFrom) return;
    final read = _read(from, span);
    if (read != null && read.midi == _heldMidi) return _hold(read);
    _identifyFrom(
      _count,
      onsetAt: _count,
      // No clear pitch means the wave stopped repeating, which is a
      // pluck. A clear but different pitch may be a bend or a wobble,
      // and is a new note only if it stays different.
      newEvenIfSame: read == null,
      placeholder: false,
      changedFrom: _heldPeriod,
    );
  }

  /// The sample where the note that was ringing gave way to the new
  /// one. [before] and [after] are the two cycle lengths.
  ///
  /// A check only notices a change some time after it happened. Move
  /// one fret with no pluck and the new wave is nearly the old one.
  /// The two slide apart slowly, the way two strings a little out of
  /// tune beat. So the moment is worked out afterwards, from the
  /// sound itself.
  ///
  /// Up to the change, each sample repeats the one a cycle of the old
  /// note earlier. From the change on, each sample is repeated a cycle
  /// of the new note later. Every place the line could be drawn is
  /// tried, and the one that breaks those two rules least is it.
  ///
  /// Adding up the whole stretch again for each place would be slow.
  /// Moving the line one sample to the right moves one sample from the
  /// "after" side to the "before" side, so each step is one number
  /// added and one taken away. That trick is a running sum.
  int _changePoint(double before, double after) {
    final first = math.max(_heldSince, _count - _keep) + before.ceil() + 1;
    final last = _count - after.ceil() - 2;
    if (first >= last) return _listenFrom;

    double brokenBefore(int at) => _squared(_sample(at) - _sample(at - before));
    double brokenAfter(int at) => _squared(_sample(at + after) - _sample(at));

    // The line starts at the far left, so everything is "after".
    var broken = 0.0;
    for (var at = first; at <= last; at++) {
      broken += brokenAfter(at);
    }
    var least = broken;
    var changedAt = first;
    for (var at = first; at <= last; at++) {
      broken += brokenBefore(at) - brokenAfter(at);
      if (broken < least) {
        least = broken;
        changedAt = at + 1;
      }
    }
    return changedAt;
  }

  /// The sound at a place that may fall between two samples. A cycle
  /// is rarely a whole number of samples long.
  double _sample(num at) {
    final whole = at.floor();
    final here = _heard[whole - _base];
    return here + (_heard[whole - _base + 1] - here) * (at - whole);
  }

  static double _squared(double value) => value * value;

  ({int midi, double period})? _read(int from, int length) {
    final period = periodIn(
      _heard,
      start: from - _base,
      length: length,
      shortest: _shortest,
      longest: _longest,
    );
    if (period == null) return null;
    final midi = midiOfPeriod(period, _rate);
    if (midi < _lowestMidi || midi > _highestMidi) return null;
    return (midi: midi, period: period);
  }
}
