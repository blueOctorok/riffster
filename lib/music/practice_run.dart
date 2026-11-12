import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/tab_song.dart';
import 'score_note.dart';
import 'song_timeline.dart';

/// A stretch of the song that repeats. The clock wraps from [endMs]
/// back to [startMs].
@immutable
class LoopRange {
  const LoopRange(this.startMs, this.endMs) : assert(endMs > startMs);

  final int startMs;
  final int endMs;

  int get lengthMs => endMs - startMs;

  bool holds(int timeMs) => timeMs >= startMs && timeMs < endMs;

  @override
  bool operator ==(Object other) =>
      other is LoopRange && other.startMs == startMs && other.endMs == endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);
}

/// The bar that is counted before playing begins. Nothing is judged
/// inside it.
class CountIn {
  const CountIn(this.startMs, this.endMs);

  static const beats = 4;

  final double startMs;
  final double endMs;

  /// How far through the count the clock is, in beats. 0 is the first
  /// beat, and 4 or more means the count is over.
  double beatAt(double positionMs) {
    return (positionMs - startMs) / (endMs - startMs) * beats;
  }
}

/// Something that just happened to a moment, kept only long enough to
/// animate.
///
/// This is the whole animation system. Nothing here moves. An effect is
/// a fact: this moment got this mark at this time. The painter works out
/// what a burst or a shaking string looks like from "now minus [atMs]",
/// so an animation is arithmetic on a number and needs no object of its
/// own per note.
class StageEffect {
  const StageEffect({
    required this.moment,
    required this.mark,
    required this.atMs,
    required this.pass,
  });

  /// Longer than any animation that reads an effect.
  static const lifeMs = 900.0;

  final SongMoment moment;
  final ScoreMark mark;

  /// On the run's own clock, [PracticeRun.nowMs]. That clock keeps
  /// going at full speed when the song is slowed down.
  final double atMs;

  /// Which trip around the loop the moment belonged to.
  final int pass;
}

/// How the judged part of a run has gone so far.
class RunSummary {
  RunSummary(Iterable<ScoreMark> marks) {
    for (final mark in marks) {
      switch (mark) {
        case ScoreMark.hit:
          onTime++;
        case ScoreMark.early:
          early++;
        case ScoreMark.late:
          late++;
        case ScoreMark.miss:
          missed++;
      }
    }
  }

  var onTime = 0;
  var early = 0;
  var late = 0;
  var missed = 0;

  int get judged => onTime + early + late + missed;

  /// The share of judged moments that were on time, from 0 to 1.
  double get accuracy => judged == 0 ? 0 : onTime / judged;
}

/// Tells the painters a frame has gone by.
class FrameSignal extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// One sitting with a song: the clock, the marks, and what just happened.
///
/// Two kinds of listener hang off a run. [frames] fires on every frame
/// and is for the painters, so a frame repaints the stage and nothing
/// else. The run itself fires only when something a button or a label
/// shows has changed: playing, a new mark, the speed, the loop.
///
/// The run has no timer. Whoever owns it calls [advance] with the time
/// that went by, which is also how a test moves the clock.
class PracticeRun extends ChangeNotifier {
  PracticeRun(TabSong song) : _timeline = SongTimeline(song) {
    _positionMs = restMs.toDouble();
  }

  /// The clock runs this far past the last note, so its result can be
  /// read before the run is called over.
  static const runOutMs = 800;

  static const slowestSpeed = 0.5;

  final frames = FrameSignal();

  SongTimeline _timeline;
  late double _positionMs;
  var _nowMs = 0.0;
  var _playing = false;
  var _finished = false;
  var _speed = 1.0;
  LoopRange? _loop;
  var _loopPass = 0;
  CountIn? _countIn;

  /// Moments before this are left as they are. It is the end of the
  /// latest count-in, or the spot the slider was dropped on.
  var _judgedFromMs = double.negativeInfinity;

  /// The next moment the clock has not yet walked past. Everything
  /// before it has been judged, so the miss check never looks back.
  var _sweepIndex = 0;

  /// The same walk for the last notes of the pass the loop just left.
  /// They may still be inside their window when the clock wraps.
  int? _tailSweepIndex;

  var _marks = <SongMoment, ScoreMark>{};
  var _lastPassMarks = <SongMoment, ScoreMark>{};

  /// A first note played a touch early lands before the loop wraps.
  /// Its mark waits here and becomes part of the next pass.
  var _nextPassMarks = <SongMoment, ScoreMark>{};
  final _effects = <StageEffect>[];
  RunSummary? _summary;
  var _dirty = false;

  var _streak = 0;
  var _bestStreak = 0;
  var _strayNotes = 0;
  var _timingSumMs = 0.0;
  var _timingCount = 0;
  int? _heardMidi;
  ScoreMark? _lastMark;
  double? _lastTimingMs;

  SongTimeline get timeline => _timeline;
  TabSong get song => _timeline.song;

  /// The song clock, in milliseconds. Below zero during the count-in.
  double get positionMs => _positionMs;

  /// Real time since the run was made. Effects are timed on this.
  double get nowMs => _nowMs;

  bool get playing => _playing;

  /// True from the end of the song until Play, Restart, or the slider.
  bool get finished => _finished;

  double get speed => _speed;
  LoopRange? get loop => _loop;

  /// How many times the loop has wrapped. 0 on the first trip.
  int get loopPass => _loopPass;

  /// The count that is running, or null when nothing is being counted.
  CountIn? get countIn {
    final countIn = _countIn;
    if (!_playing || countIn == null || _positionMs >= countIn.endMs) {
      return null;
    }
    return countIn;
  }

  Map<SongMoment, ScoreMark> get marks => _marks;
  Map<SongMoment, ScoreMark> get lastPassMarks => _lastPassMarks;
  List<StageEffect> get effects => _effects;

  /// Moments played in a row without a miss.
  int get streak => _streak;
  int get bestStreak => _bestStreak;

  /// Sounds that matched nothing: a wrong pitch, or a note in a gap.
  int get strayNotes => _strayNotes;

  /// The pitch of the latest sound, whether or not it was judged.
  int? get heardMidi => _heardMidi;

  /// How the latest sound was judged. Null when it was only heard.
  ScoreMark? get lastMark => _lastMark;

  /// How far off the beat the latest sound was, in real milliseconds.
  /// Above zero is late. Null when it was not played against a note.
  double? get lastTimingMs => _lastTimingMs;

  RunSummary get summary => _summary ??= RunSummary(_marks.values);

  /// How far off the beat the played notes have been on average, in
  /// real milliseconds. Above zero is late. Null before the first one.
  double? get averageTimingMs {
    return _timingCount == 0 ? null : _timingSumMs / _timingCount;
  }

  /// True while the stage has something to animate.
  bool get needsFrames => _playing || _effects.isNotEmpty;

  /// Where the clock waits before Play: one bar ahead of the first note
  /// it will judge. Inside a loop that is the loop's first note.
  int get restMs {
    final loop = _loop;
    if (loop == null) return _timeline.restMs;
    final moments = _timeline.moments;
    final first = _timeline.firstAtOrAfter(loop.startMs);
    final firstMs = first < moments.length && loop.holds(moments[first].timeMs)
        ? moments[first].timeMs
        : loop.startMs;
    return firstMs - _timeline.countInMs;
  }

  /// The last spot the slider can reach.
  int get lastMs => _loop?.endMs ?? _timeline.lengthMs;

  /// Puts a different song on the stage. [keepPlace] is for a lane that
  /// is being edited while it plays: the clock stays where it is.
  void load(TabSong song, {bool keepPlace = false}) {
    final place = _positionMs;
    _timeline = SongTimeline(song);
    _loop = null;
    _finished = false;
    _countIn = null;
    _resetScore();
    if (keepPlace) {
      _positionMs = place.clamp(restMs, lastMs).toDouble();
      _judgeFrom(_positionMs);
    } else {
      _playing = false;
      _positionMs = restMs.toDouble();
    }
    _changed();
  }

  void toggle() => _playing ? pause() : play();

  /// Backs up one bar, counts it in, and plays. From the end of the
  /// count forward, every note is judged fresh. Notes behind it keep
  /// the marks they already have.
  void play() {
    if (_playing || _timeline.moments.isEmpty) return;
    if (_finished || _positionMs >= lastMs) {
      _resetScore();
      _positionMs = restMs.toDouble();
    }
    _finished = false;
    final startMs = math.max(
      restMs.toDouble(),
      _positionMs - _timeline.countInMs,
    );
    final countIn = CountIn(startMs, startMs + _timeline.countInMs);
    _countIn = countIn;
    _positionMs = startMs;
    _judgeFrom(countIn.endMs);
    _playing = true;
    _changed();
  }

  void pause() {
    if (!_playing) return;
    _playing = false;
    _countIn = null;
    _changed();
  }

  /// Clears the score and plays again from the first count.
  void restart() {
    _playing = false;
    _finished = false;
    _resetScore();
    _positionMs = restMs.toDouble();
    // An empty lane has nothing to play, and still has to redraw.
    if (_timeline.moments.isEmpty) return _changed();
    play();
  }

  /// Moves the clock. Notes from here forward can be played again.
  ///
  /// While paused the marks are left on the staff, so a finished run
  /// can be dragged back and looked over. [play] wipes them from the
  /// count forward, which is the moment they stop being true.
  void seek(double timeMs) {
    _positionMs = timeMs.clamp(restMs, lastMs).toDouble();
    _finished = false;
    _countIn = null;
    if (_playing) _judgeFrom(_positionMs);
    _changed();
  }

  /// How fast the song clock runs. 1 is the written tempo. Timing is
  /// still judged in real milliseconds, so slow practice is not easier
  /// to be "on time" in. It only gives the hands longer to get there.
  set speed(double value) {
    final next = value.clamp(slowestSpeed, 1.0).toDouble();
    if (next == _speed) return;
    _speed = next;
    _changed();
  }

  /// Moves the speed by tenths: 1 is one step faster, -1 one slower.
  ///
  /// Rounded to a whole tenth first. Adding 0.1 over and over drifts,
  /// because 0.1 has no exact form in binary, and 70% turns into
  /// 69.99999%.
  void nudgeSpeed(int steps) => speed = ((_speed * 10).round() + steps) / 10;

  /// Repeats one stretch of the song, or null to play straight through.
  /// A playhead that is outside the new loop goes to the loop's count.
  set loop(LoopRange? range) {
    if (range == _loop) return;
    _loop = range;
    _loopPass = 0;
    _tailSweepIndex = null;
    _lastPassMarks = {};
    _nextPassMarks = {};
    if (range != null &&
        (_positionMs < restMs || _positionMs >= range.endMs)) {
      _playing = false;
      _countIn = null;
      _positionMs = restMs.toDouble();
      _judgeFrom(_positionMs);
    }
    _changed();
  }

  /// Moves every clock forward by [elapsed] of real time.
  void advance(Duration elapsed) {
    final stepMs = elapsed.inMicroseconds / 1000;
    _nowMs += stepMs;
    if (_playing) _step(stepMs * _speed);
    final hadEffects = _effects.isNotEmpty;
    _effects.removeWhere((effect) => _nowMs - effect.atMs > StageEffect.lifeMs);
    // The last effect fading out is when the owner can stop its timer.
    if (hadEffects && _effects.isEmpty) _dirty = true;
    if (_dirty) return _changed();
    frames.tick();
  }

  /// A note was started. [midi] is null when the sound had no single
  /// pitch, which is how a strum is heard. [latencyMs] is how long ago,
  /// in real time, the string was actually plucked.
  void pluck(int? midi, {required double latencyMs}) {
    if (midi != null) _heardMidi = midi;
    _lastTimingMs = null;
    // The sound is late. Judge the moment the string was plucked. The
    // delay is real time, and the song clock may be running slow.
    _lastMark = _playing ? _judge(_positionMs - latencyMs * _speed, midi) : null;
    _changed();
  }

  @override
  void dispose() {
    frames.dispose();
    super.dispose();
  }

  void _step(double songMs) {
    _positionMs += songMs;
    final loop = _loop;
    if (loop != null) {
      while (_positionMs >= loop.endMs) {
        _wrap(loop);
      }
      final tail = _tailSweepIndex;
      if (tail != null) {
        final next = _sweep(
          _lastPassMarks,
          from: tail,
          untilMs: loop.endMs,
          positionMs: _positionMs + loop.lengthMs,
          pass: _loopPass - 1,
        );
        final done =
            next >= _timeline.moments.length ||
            _timeline.moments[next].timeMs >= loop.endMs;
        _tailSweepIndex = done ? null : next;
      }
    }
    _sweepIndex = _sweep(
      _marks,
      from: _sweepIndex,
      untilMs: loop?.endMs ?? double.infinity,
      positionMs: _positionMs,
      pass: _loopPass,
    );
    if (loop == null && _positionMs >= _timeline.lengthMs + runOutMs) {
      _positionMs = (_timeline.lengthMs + runOutMs).toDouble();
      _playing = false;
      _finished = true;
      _countIn = null;
      _dirty = true;
    }
  }

  /// The loop has reached its end. The marks just made become "last
  /// pass", and the clock goes back to the loop's start without a count,
  /// so the loop stays in time.
  void _wrap(LoopRange loop) {
    _positionMs -= loop.lengthMs;
    _tailSweepIndex = _sweepIndex;
    _lastPassMarks = _marks;
    _marks = _nextPassMarks;
    _nextPassMarks = {};
    _loopPass++;
    _judgedFromMs = loop.startMs.toDouble();
    _sweepIndex = _timeline.firstAtOrAfter(loop.startMs);
    _dirty = true;
  }

  /// Walks forward from [from] and misses every moment the clock has
  /// left behind unplayed. Returns where the next walk should start.
  int _sweep(
    Map<SongMoment, ScoreMark> marks, {
    required int from,
    required num untilMs,
    required double positionMs,
    required int pass,
  }) {
    final moments = _timeline.moments;
    var index = from;
    while (index < moments.length) {
      final moment = moments[index];
      if (moment.timeMs >= untilMs) break;
      final gone = windowHasPassed(
        dueAtMs: moment.timeMs,
        positionMs: positionMs,
        speed: _speed,
      );
      if (!gone) break;
      final mark = marks[moment];
      if (!isPlayed(mark)) {
        // A wrong pitch already dimmed this one. Do not dim it twice.
        if (mark == null) _addEffect(moment, ScoreMark.miss, pass);
        marks[moment] = ScoreMark.miss;
        _streak = 0;
        _dirty = true;
      }
      index++;
    }
    return index;
  }

  /// Judges one sound. Null when it landed in the count-in, or when it
  /// had no pitch and so could only have been meant for a chord.
  ScoreMark? _judge(double playedAtMs, int? midi) {
    final target = _targetNear(playedAtMs);
    if (target == null) {
      if (playedAtMs < _judgedFromMs || midi == null) return null;
      _strayNotes++;
      return ScoreMark.miss;
    }
    final moment = target.moment;
    if (target.passShift == 0 && moment.timeMs < _judgedFromMs) return null;
    if (midi == null && moment.notes.length < 2) return null;

    final marks = switch (target.passShift) {
      -1 => _lastPassMarks,
      1 => _nextPassMarks,
      _ => _marks,
    };
    final heard = scoreMoment(
      written: moment.notes,
      playedAtMs: target.playedInPassMs,
      playedMidi: midi,
      speed: _speed,
    );
    final timingMs = (target.playedInPassMs - moment.timeMs) / _speed;
    if (heard != ScoreMark.miss) _lastTimingMs = timingMs;
    final before = marks[moment];
    marks[moment] = keepBetterMark(before, heard);
    final pass = _loopPass + target.passShift;
    if (heard == ScoreMark.miss) {
      _strayNotes++;
      if (before == null) _addEffect(moment, ScoreMark.miss, pass);
    } else if (!isPlayed(before)) {
      _streak++;
      _bestStreak = math.max(_bestStreak, _streak);
      _timingSumMs += timingMs;
      _timingCount++;
      _addEffect(moment, heard, pass);
    }
    return heard;
  }

  /// The moment a sound was most likely meant for.
  ///
  /// Inside a loop the answer can be in another pass. The first note of
  /// the loop, played a few milliseconds early, arrives while the clock
  /// is still at the loop's end. The last note, played a little late,
  /// arrives after the clock has wrapped. So the sound is tried against
  /// this pass, the next one, and the one before, and the closest wins.
  /// [passShift] says which of those it was.
  ({SongMoment moment, int passShift, double playedInPassMs})? _targetNear(
    double playedAtMs,
  ) {
    final loop = _loop;
    if (loop == null) {
      final moment = _timeline.momentNear(playedAtMs, speed: _speed);
      if (moment == null) return null;
      return (moment: moment, passShift: 0, playedInPassMs: playedAtMs);
    }

    ({SongMoment moment, int passShift, double playedInPassMs})? best;
    var bestDistance = double.infinity;
    for (final shift in [0, 1, if (_loopPass > 0) -1]) {
      final inPassMs = playedAtMs - shift * loop.lengthMs;
      final moment = _timeline.momentNear(inPassMs, speed: _speed);
      if (moment == null || !loop.holds(moment.timeMs)) continue;
      final distance = (moment.timeMs - inPassMs).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = (moment: moment, passShift: shift, playedInPassMs: inPassMs);
      }
    }
    return best;
  }

  void _addEffect(SongMoment moment, ScoreMark mark, int pass) {
    _effects.add(
      StageEffect(moment: moment, mark: mark, atMs: _nowMs, pass: pass),
    );
  }

  void _judgeFrom(double timeMs) {
    _judgedFromMs = timeMs;
    _marks.removeWhere((moment, _) => moment.timeMs >= timeMs);
    _sweepIndex = _timeline.firstAtOrAfter(timeMs);
  }

  void _resetScore() {
    _marks = {};
    _lastPassMarks = {};
    _nextPassMarks = {};
    _effects.clear();
    _loopPass = 0;
    _tailSweepIndex = null;
    _judgedFromMs = double.negativeInfinity;
    _sweepIndex = 0;
    _streak = 0;
    _bestStreak = 0;
    _strayNotes = 0;
    _timingSumMs = 0;
    _timingCount = 0;
    _lastMark = null;
    _lastTimingMs = null;
  }

  void _changed() {
    _dirty = false;
    _summary = null;
    frames.tick();
    notifyListeners();
  }
}
