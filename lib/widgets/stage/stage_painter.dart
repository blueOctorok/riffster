import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../models/fretting_finger.dart';
import '../../models/tab_note.dart';
import '../../music/barre.dart';
import '../../music/practice_run.dart';
import '../../music/score_note.dart';
import '../../music/song_timeline.dart';
import '../../theme/neck_theme.dart';
import '../../theme/riffster_theme.dart';
import '../finger_colors.dart';
import 'stage_ink.dart';
import 'stage_metrics.dart';

/// Everything on the stage that moves: the strings, the playhead, the
/// notes, and what happens when a note is played.
///
/// Nothing here keeps state between frames. Each frame is drawn from two
/// numbers on the run: the song clock, which says where every note is,
/// and the real clock, which says how old every effect is. That is why
/// pausing, scrubbing, and looping need no special cases in the drawing.
class StagePainter extends CustomPainter {
  StagePainter({
    required this.run,
    required this.metrics,
    required this.neck,
    required this.ink,
  }) : super(repaint: run.frames);

  final PracticeRun run;
  final StageMetrics metrics;
  final NeckTheme neck;
  final StageInk ink;

  static const _plainString = Color(0xFFD9DCE0);
  static const _woundString = Color(0xFFC4BBA6);

  /// One brush for every wound string. A repeating gradient tiles its
  /// two-and-a-half pixel stripe along the whole line.
  static final _windings = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(2.5, 0),
      const [Color(0x00000000), Color(0x38000000), Color(0x00000000)],
      const [0, 0.5, 1],
      TileMode.repeated,
    );

  /// How much an unplayed note has grown by the time it is due.
  static const _arrivalSwell = 0.12;

  double get _position => run.positionMs;
  double get _now => run.nowMs;
  double get _radius => metrics.noteRadius;

  /// A note at the size it is when it is due, with a sliver of board
  /// left between it and its ring.
  double get _targetRadius => _radius * (1 + _arrivalSwell) + 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(StageMetrics.cornerRadius),
      ),
    );
    // Moving things slide under the nut instead of over it.
    canvas.clipRect(
      Rect.fromLTRB(StageMetrics.nutWidth - 4, 0, size.width, size.height),
    );

    final passes = _passes();
    final seen = [for (final pass in passes) ..._seenIn(pass, size)];

    _paintBars(canvas, size, passes);
    _paintOnTimeBand(canvas);
    _paintStrings(canvas, size);
    _paintPlayhead(canvas);
    _paintTargets(canvas);
    _paintLoopEnds(canvas, size, passes);
    for (final item in seen) {
      _paintTails(canvas, item);
    }
    for (final item in seen) {
      _paintMoment(canvas, item);
    }
    _paintEffects(canvas, size);
    _paintChordNames(canvas, size, seen);
    _paintRestHint(canvas);
    _paintCountIn(canvas, size);
    canvas.restore();
  }

  /// The trips around the loop that can be on screen together.
  ///
  /// With no loop there is one. Inside a loop the stage also draws the
  /// pass before, sliding away to the left with its results, and the
  /// pass after, coming in from the right with none. That is what makes
  /// the wrap invisible: the notes never jump, they just keep arriving.
  List<_Pass> _passes() {
    final loop = run.loop;
    if (loop == null) return [_Pass(0, run.marks, 0)];
    return [
      if (run.loopPass > 0)
        _Pass(-loop.lengthMs.toDouble(), run.lastPassMarks, run.loopPass - 1),
      _Pass(0, run.marks, run.loopPass),
      _Pass(loop.lengthMs.toDouble(), const {}, run.loopPass + 1),
    ];
  }

  /// The moments of [pass] that are on the stage right now.
  List<_Seen> _seenIn(_Pass pass, Size size) {
    final timeline = run.timeline;
    final clock = _position - pass.shiftMs;
    // A long note's tail is still in view after its head has left, so
    // the search starts one longest-note earlier than the left edge.
    var fromMs =
        clock - metrics.msAcross(metrics.playheadX) - timeline.longestNoteMs;
    var toMs =
        clock + metrics.msAcross(size.width - metrics.playheadX + _radius * 2);
    final loop = run.loop;
    if (loop != null) {
      fromMs = math.max(fromMs, loop.startMs.toDouble());
      toMs = math.min(toMs, loop.endMs - 1.0);
    }
    final moments = timeline.moments;
    return [
      for (
        var i = timeline.firstAtOrAfter(fromMs);
        i < moments.length && moments[i].timeMs <= toMs;
        i++
      )
        _Seen(moments[i], pass, metrics.xAt(moments[i].timeMs, clock)),
    ];
  }

  /// Bar lines look like fret wire, and each bar carries its number.
  void _paintBars(Canvas canvas, Size size, List<_Pass> passes) {
    final top = metrics.topStringY - 14;
    final bottom = metrics.bottomStringY + 14;
    // Three strokes make one wire: a shadow to its right, the metal,
    // and a thin line of light down its left side.
    final cast = Paint()
      ..strokeWidth = 3
      ..color = Color.fromRGBO(0, 0, 0, neck.isLight ? 0.2 : 0.45);
    final wire = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9A948A).withValues(alpha: 0.8);
    final shine = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF2EEE6).withValues(alpha: 0.75);
    final tick = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = neck.ink.withValues(alpha: 0.34);
    final loop = run.loop;
    final bars = run.song.bars;

    for (final pass in passes) {
      final clock = _position - pass.shiftMs;
      for (var index = 0; index < bars.length; index++) {
        final bar = bars[index];
        if (loop != null && !loop.holds(bar.startMs)) continue;
        final x = metrics.xAt(bar.startMs, clock);
        final endX = metrics.xAt(bar.endMs, clock);
        if (endX < 0 || x > size.width) continue;

        canvas.drawLine(Offset(x + 2, top), Offset(x + 2, bottom), cast);
        canvas.drawLine(Offset(x, top), Offset(x, bottom), wire);
        canvas.drawLine(Offset(x - 0.8, top), Offset(x - 0.8, bottom), shine);
        final number = ink.text(
          '${index + 1}',
          color: neck.ink.withValues(alpha: 0.62),
          size: 13,
          weight: FontWeight.w600,
        );
        number.paint(canvas, Offset(x + 8, metrics.bottomStringY + 16));

        for (var beat = 1; beat < bar.beats; beat++) {
          final beatX = x + (endX - x) * beat / bar.beats;
          canvas.drawLine(
            Offset(beatX, bottom + 4),
            Offset(beatX, bottom + 10),
            tick,
          );
        }
      }
    }
  }

  /// A faint band around the playhead, exactly as wide as "on time".
  /// A note whose center is inside it when you pluck is a hit.
  void _paintOnTimeBand(Canvas canvas) {
    final x = metrics.playheadX;
    final half = onTimeMs * run.speed / 1000 * metrics.pixelsPerSecond;
    final warmth = _streakWarmth;
    final band = RRect.fromLTRBR(
      x - half,
      metrics.topStringY - _targetRadius - 4,
      x + half,
      metrics.bottomStringY + _targetRadius + 4,
      const Radius.circular(8),
    );
    canvas.drawRRect(
      band,
      Paint()..color = _glowColor.withValues(alpha: 0.08 + 0.05 * warmth),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _glowColor.withValues(alpha: 0.26 + 0.12 * warmth),
    );
  }

  /// Gold light shows on dark wood and vanishes on blonde wood. On a
  /// light board the glow is a dark amber instead, so the gold line
  /// still has something to stand out against.
  Color get _glowColor {
    return neck.isLight ? const Color(0xFF6E4407) : RiffColors.goldLit;
  }

  void _paintStrings(Canvas canvas, Size size) {
    const startX = StageMetrics.nutWidth - 4;
    final endX = size.width;
    for (var string = 1; string <= metrics.instrument.stringCount; string++) {
      final y = metrics.stringY(string);
      final gauge = metrics.stringWidth(string);
      final wound = metrics.isWound(string);
      final metal = wound ? _woundString : _plainString;
      final swing = _swingOf(string, gauge);

      // A plucked string is drawn as a shallow arc that flips up and
      // down. A curve with one control point is close enough to the
      // real shape, and its peak is half the control point's offset.
      void stroke(double dy, double bend, Paint paint) {
        if (bend == 0) {
          canvas.drawLine(Offset(startX, y + dy), Offset(endX, y + dy), paint);
          return;
        }
        final path = Path()
          ..moveTo(startX, y + dy)
          ..quadraticBezierTo(
            (startX + endX) / 2,
            y + dy + bend * 2,
            endX,
            y + dy,
          );
        canvas.drawPath(path, paint..style = PaintingStyle.stroke);
      }

      if (swing.reach > 0.3) {
        // The blur of a string moving faster than the eye: two faint
        // copies at the farthest it travels each way.
        final blur = Paint()
          ..strokeWidth = gauge
          ..color = metal.withValues(alpha: 0.2);
        stroke(0, swing.reach, blur);
        stroke(0, -swing.reach, blur);
      }
      stroke(
        gauge / 2 + 2.5,
        swing.offset,
        Paint()
          ..strokeWidth = gauge + 1
          ..color = Color.fromRGBO(0, 0, 0, neck.isLight ? 0.24 : 0.34),
      );
      stroke(
        0,
        swing.offset,
        Paint()
          ..strokeWidth = gauge
          ..color = metal,
      );
      stroke(
        gauge * 0.26,
        swing.offset,
        Paint()
          ..strokeWidth = gauge * 0.4
          ..color = shade(metal, -0.5).withValues(alpha: 0.75),
      );
      stroke(
        -gauge * 0.22,
        swing.offset,
        Paint()
          ..strokeWidth = math.max(0.7, gauge * 0.3)
          ..color = shade(metal, 0.7),
      );
      if (wound) {
        // The wrap wire: a faint dark stripe that repeats along the
        // string. Kept faint, or the string reads as a row of beads.
        stroke(0, swing.offset, _windings..strokeWidth = gauge);
      }
    }
  }

  /// How far [string] is from rest right now, and the farthest it is
  /// still swinging. Both are zero when nothing has plucked it lately.
  ///
  /// The motion is a wave that dies away: a cosine for the back and
  /// forth, multiplied by a falling curve so each swing is smaller than
  /// the last. A thicker string swings wider.
  ({double offset, double reach}) _swingOf(int string, double gauge) {
    const swingMs = 68.0;
    const fadeMs = 150.0;
    double? age;
    for (final effect in run.effects) {
      if (effect.mark == ScoreMark.miss) continue;
      if (!effect.moment.notes.any((note) => note.string == string)) continue;
      final effectAge = _now - effect.atMs;
      if (age == null || effectAge < age) age = effectAge;
    }
    if (age == null) return (offset: 0, reach: 0);
    final reach = (2.2 + gauge * 0.6) * math.exp(-age / fadeMs);
    return (
      offset: reach * math.cos(age / swingMs * math.pi * 2),
      reach: reach,
    );
  }

  /// The playhead glows warmer as a streak builds: a step at 10, 25,
  /// and 50 in a row.
  double get _streakWarmth {
    final streak = run.streak;
    if (streak >= 50) return 1;
    if (streak >= 25) return 0.66;
    if (streak >= 10) return 0.33;
    return 0;
  }

  void _paintPlayhead(Canvas canvas) {
    final x = metrics.playheadX;
    // The arrowheads sit just clear of the outer rings.
    final top = metrics.topStringY - _targetRadius - 10;
    final bottom = metrics.bottomStringY + _targetRadius + 10;
    final warmth = _streakWarmth;
    // A slow breath in the glow once a streak is on.
    final breath = 1 + 0.18 * warmth * math.sin(_now / 1000 * math.pi * 2.2);

    final spread = 26 + 30 * warmth;
    final glow = Rect.fromLTRB(x - spread, top, x + spread, bottom);
    canvas.drawRect(
      glow,
      Paint()
        ..shader = ui.Gradient.linear(
          glow.centerLeft,
          glow.centerRight,
          [
            _glowColor.withValues(alpha: 0),
            _glowColor.withValues(
              alpha: ((0.2 + 0.3 * warmth) * breath).clamp(0, 1),
            ),
            _glowColor.withValues(alpha: 0),
          ],
          const [0, 0.5, 1],
        ),
    );
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bottom),
      Paint()
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = _glowColor.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final lineColors = neck.isLight
        ? const [RiffColors.gold, RiffColors.goldDeep, RiffColors.gold]
        : const [RiffColors.goldLit, RiffColors.gold, RiffColors.goldLit];
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bottom),
      Paint()
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(x, top),
          Offset(x, bottom),
          lineColors,
          const [0, 0.5, 1],
        ),
    );
    // A small arrowhead at each end, pointing in at the strings.
    final cap = Paint()..color = lineColors.first;
    for (final (tipY, baseY) in [(top + 9, top), (bottom - 9, bottom)]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 6, baseY)
          ..lineTo(x + 6, baseY)
          ..lineTo(x, tipY)
          ..close(),
        cap,
      );
    }
  }

  /// A ring on every string where it crosses the playhead. It is the
  /// size of a note at the moment the note is due, so "when do I pluck"
  /// has an answer the eye can use: when the note fills its ring.
  void _paintTargets(Canvas canvas) {
    // A little shade inside makes the ring read as a seat in the board.
    final seat = Paint()
      ..color = Color.fromRGBO(0, 0, 0, neck.isLight ? 0.1 : 0.22);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = (neck.isLight ? RiffColors.goldDeep : RiffColors.goldLit)
          .withValues(alpha: 0.75);
    for (var string = 1; string <= metrics.instrument.stringCount; string++) {
      final center = Offset(metrics.playheadX, metrics.stringY(string));
      canvas.drawCircle(center, _targetRadius, seat);
      canvas.drawCircle(center, _targetRadius, ring);
    }
  }

  /// A gold post where the loop starts and where it comes back around.
  void _paintLoopEnds(Canvas canvas, Size size, List<_Pass> passes) {
    final loop = run.loop;
    if (loop == null) return;
    final post = Paint()
      ..strokeWidth = 2
      ..color = RiffColors.gold.withValues(alpha: 0.7);
    final top = metrics.topStringY - 26;
    final bottom = metrics.bottomStringY + 14;
    for (final pass in passes) {
      final x = metrics.xAt(loop.startMs, _position - pass.shiftMs);
      if (x < 0 || x > size.width) continue;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), post);
      canvas.drawPath(
        Path()
          ..moveTo(x, top)
          ..lineTo(x + 9, top + 5)
          ..lineTo(x, top + 10)
          ..close(),
        Paint()..color = RiffColors.gold,
      );
    }
  }

  /// The translucent bar behind a note that shows how long to hold it.
  void _paintTails(Canvas canvas, _Seen seen) {
    final thickness = math.max(6.0, _radius * 0.44);
    final fade = _edgeFade(seen.x) * (seen.mark == ScoreMark.miss ? 0.4 : 1);
    if (fade <= 0) return;
    for (final note in seen.moment.notes) {
      final length = note.durationMs / 1000 * metrics.pixelsPerSecond;
      // Too short to see past the note itself.
      if (length < _radius + 10) continue;
      final y = metrics.stringY(note.string);
      final color = _colorOf(note);
      // A ring's tail is quieter, so an open string does not shout.
      final strength = (note.finger == null ? 0.55 : 1.0) * fade;
      final tail = RRect.fromLTRBR(
        seen.x,
        y - thickness / 2,
        seen.x + length - 4,
        y + thickness / 2,
        Radius.circular(thickness / 2),
      );
      canvas.drawRRect(
        tail.shift(const Offset(0, 2)),
        Paint()..color = Color.fromRGBO(0, 0, 0, 0.25 * strength),
      );
      canvas.drawRRect(
        tail,
        Paint()..color = color.withValues(alpha: 0.62 * strength),
      );
      // A line of light along the top edge, like the gloss on the note.
      canvas.drawLine(
        Offset(seen.x + _radius, y - thickness / 2 + 1.2),
        Offset(seen.x + length - 4 - thickness / 2, y - thickness / 2 + 1.2),
        Paint()
          ..strokeWidth = 1
          ..color = Color.fromRGBO(255, 255, 255, 0.38 * strength),
      );
    }
  }

  void _paintMoment(Canvas canvas, _Seen seen) {
    final moment = seen.moment;
    final mark = seen.mark;
    final effect = _effectOn(moment, seen.pass.number);
    final age = effect == null ? null : _now - effect.atMs;

    var alpha = _edgeFade(seen.x);
    if (alpha <= 0) return;
    var scale = 1.0;
    var nearness = 0.0;
    if (mark == ScoreMark.miss) {
      // A miss dims and drops back. With no effect left it is settled.
      final settled = age == null ? 1.0 : (age / 220).clamp(0.0, 1.0);
      alpha *= ui.lerpDouble(1, 0.42, settled)!;
      scale = ui.lerpDouble(1, 0.9, settled)!;
    } else if (mark == null) {
      nearness = _nearness(moment.timeMs + seen.pass.shiftMs);
      scale = 1 + _arrivalSwell * nearness;
    } else if (age != null && age < 260) {
      // A played note pops, then settles.
      final pop = 1 - age / 260;
      scale = 1 + 0.2 * pop * pop;
    }

    final barre = moment.barre;
    if (barre != null) _paintBarre(canvas, seen.x, barre, alpha);

    for (final note in moment.notes) {
      final center = Offset(seen.x, metrics.stringY(note.string));
      if (nearness > 0) {
        // A halo that grows as the note comes up to the line.
        canvas.drawCircle(
          center,
          _radius * scale + 3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = _colorOf(note).withValues(alpha: 0.3 * nearness * alpha),
        );
      }
      _paintDisc(canvas, center, note, scale: scale, alpha: alpha);
      if (isPlayed(mark) && age != null && age < 180) {
        canvas.drawCircle(
          center,
          _radius * scale,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * (1 - age / 180)),
        );
      }
      if (mark != null) _paintMark(canvas, center, mark, scale, alpha);
    }
  }

  /// How close an unplayed note is to its moment, from 0 to 1.
  ///
  /// It climbs through the last beat before the playhead and falls away
  /// while the note's window is still open behind it. The curve is a
  /// "smoothstep": slow, fast, slow, so the swell starts and ends gently.
  double _nearness(double timeMs) {
    final ahead = timeMs - _position;
    final reach = ahead >= 0 ? run.timeline.beatMs : sameBeatMs * run.speed;
    final linear = (1 - ahead.abs() / reach).clamp(0.0, 1.0);
    return linear * linear * (3 - 2 * linear);
  }

  /// Notes fade out as they reach the nut, so they do not pile up on it.
  double _edgeFade(double x) {
    final fromNut = (x - StageMetrics.nutWidth - _radius) / 56;
    return fromNut.clamp(0.0, 1.0);
  }

  Color _colorOf(TabNote note) {
    final finger = note.finger;
    return finger == null ? neck.ink : fingerColor[finger]!;
  }

  /// One note. A fretted note is a glass disc in its finger's color. An
  /// open string, or a note nobody has chosen a finger for, is a ring.
  void _paintDisc(
    Canvas canvas,
    Offset center,
    TabNote note, {
    required double scale,
    required double alpha,
  }) {
    final r = _radius;
    final finger = note.finger;
    // The brushes are built around zero, so the canvas moves to the note.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.drawCircle(Offset(0, r * 0.3), r * 1.45, _faded(ink.shadow, alpha));

    final Color numberColor;
    if (finger == null) {
      canvas.drawCircle(Offset.zero, r, _faded(ink.hollowFill, alpha));
      canvas.drawCircle(Offset.zero, r - 1.2, _faded(ink.hollowRing, alpha));
      numberColor = neck.ink;
    } else {
      canvas.drawCircle(Offset.zero, r, _faded(ink.glass(finger), alpha));
      canvas.drawCircle(Offset.zero, r, _faded(ink.underglow, alpha));
      canvas.drawCircle(Offset.zero, r - 0.6, _faded(ink.rim(finger), alpha));
      numberColor = fingerNumberColor[finger]!;
    }
    canvas.drawOval(
      Rect.fromLTRB(-r * 0.7, -r * 0.92, r * 0.7, -r * 0.02),
      _faded(ink.gloss, finger == null ? alpha * 0.45 : alpha),
    );

    // Text cannot be faded after it is laid out, so the fade is rounded
    // to eighths and each step is laid out once.
    final step = (alpha * 8).round() / 8;
    if (step > 0) {
      final number = ink.text(
        '${note.fret}',
        color: numberColor.withValues(alpha: step),
        size: r,
        shadows: numberColor.computeLuminance() > 0.5
            ? const [
                Shadow(
                  color: Color(0x80000000),
                  offset: Offset(0, 1),
                  blurRadius: 1.5,
                ),
              ]
            : null,
      );
      number.paint(canvas, Offset(-number.width / 2, -number.height / 2));
    }
    canvas.restore();
  }

  /// A brush's own gradient, made see-through. The paint's color is not
  /// drawn when a gradient is set, but its alpha still scales the result.
  Paint _faded(Paint paint, double alpha) {
    return paint..color = paint.color.withValues(alpha: alpha.clamp(0.0, 1.0));
  }

  /// A ring outside the note. Green is a hit, gold is early or late,
  /// and rose with a slash is a note that went by unplayed.
  void _paintMark(
    Canvas canvas,
    Offset center,
    ScoreMark mark,
    double scale,
    double alpha,
  ) {
    final color = RiffColors.forMark(mark);
    final ring = (_radius + 5) * scale;
    canvas.drawCircle(
      center,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = color.withValues(alpha: 0.2 * alpha),
    );
    canvas.drawCircle(
      center,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    if (mark == ScoreMark.miss) {
      final reach = _radius * 0.5 * scale;
      canvas.drawLine(
        center + Offset(-reach, -reach),
        center + Offset(reach, reach),
        Paint()
          ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// A capsule around the index barre and every note inside its reach.
  /// The other fingers keep their own colors. The capsule only says
  /// "this is one finger laid flat."
  void _paintBarre(Canvas canvas, double x, IndexBarre barre, double alpha) {
    final color = fingerColor[FrettingFinger.indexFinger]!;
    final capsule = RRect.fromLTRBR(
      x - _radius - 6,
      metrics.stringY(barre.topString) - _radius - 5,
      x + _radius + 6,
      metrics.stringY(barre.bottomString) + _radius + 5,
      Radius.circular(_radius + 6),
    );
    canvas.drawRRect(
      capsule,
      Paint()..color = color.withValues(alpha: 0.16 * alpha),
    );
    canvas.drawRRect(
      capsule,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.9 * alpha),
    );
  }

  StageEffect? _effectOn(SongMoment moment, int pass) {
    // Newest first, so a hit that saved a miss is the one that shows.
    for (final effect in run.effects.reversed) {
      if (effect.moment == moment && effect.pass == pass) return effect;
    }
    return null;
  }

  /// What a played note throws off: a ring that bursts outward, a few
  /// sparks, and the word "early" or "late" when it was not on time.
  void _paintEffects(Canvas canvas, Size size) {
    final loopMs = run.loop?.lengthMs ?? 0;
    for (final effect in run.effects) {
      if (effect.mark == ScoreMark.miss) continue;
      final age = _now - effect.atMs;
      final shiftMs = (effect.pass - run.loopPass) * loopMs;
      final x = metrics.xAt(effect.moment.timeMs + shiftMs, _position);
      if (x < 0 || x > size.width) continue;
      final color = RiffColors.forMark(effect.mark);

      const burstMs = 460.0;
      if (age < burstMs) {
        final progress = age / burstMs;
        // Fast out of the note, then slowing: one minus a cube.
        final out = 1 - math.pow(1 - progress, 3).toDouble();
        final fade = 1 - progress;
        for (final note in effect.moment.notes) {
          final center = Offset(x, metrics.stringY(note.string));
          canvas.drawCircle(
            center,
            _radius + 5 + out * _radius * 1.9,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1 + 3 * fade
              ..color = color.withValues(alpha: fade * fade),
          );
          _paintSparks(canvas, center, note, out, fade, color);
        }
      }

      if (effect.mark != ScoreMark.hit) {
        const wordMs = 760.0;
        final progress = (age / wordMs).clamp(0.0, 1.0);
        final fade = progress < 0.55 ? 1.0 : 1 - (progress - 0.55) / 0.45;
        final step = (fade * 8).round() / 8;
        if (step <= 0) continue;
        final word = ink.text(
          effect.mark.name,
          color: RiffColors.goldLit.withValues(alpha: step),
          size: 14,
          weight: FontWeight.w700,
          shadows: const [Shadow(color: Color(0xB3000000), blurRadius: 4)],
        );
        final top = effect.moment.notes
            .map((note) => metrics.stringY(note.string))
            .reduce(math.min);
        final rise = 14 * (1 - math.pow(1 - progress, 3));
        word.paint(
          canvas,
          Offset(x - word.width / 2, top - _radius - 22 - rise),
        );
      }
    }
  }

  /// Eight short streaks flying out from a played note. The angle is
  /// turned by the note's own time, so two notes do not spark alike and
  /// one note sparks the same way on every frame.
  void _paintSparks(
    Canvas canvas,
    Offset center,
    TabNote note,
    double out,
    double fade,
    Color color,
  ) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = shade(color, 0.35).withValues(alpha: fade);
    final turn = (note.timeMs % 360) * math.pi / 180;
    for (var spark = 0; spark < 8; spark++) {
      final angle = turn + spark * math.pi / 4;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final from = _radius * 1.25 + out * _radius * 1.5;
      canvas.drawLine(
        center + direction * from,
        center + direction * (from + 3 + 5 * fade),
        paint,
      );
    }
  }

  /// A named chord gets a gold chip, big enough to read as the chord and
  /// not as another fret number. A stack we cannot name stays unlabeled.
  void _paintChordNames(Canvas canvas, Size size, List<_Seen> seen) {
    var lastRight = double.negativeInfinity;
    for (final item in seen) {
      final name = item.moment.chordName;
      if (name == null) continue;
      final alpha = _edgeFade(item.x);
      final step = (alpha * 8).round() / 8;
      if (step <= 0) continue;
      final label = ink.text(
        name,
        color: RiffColors.onGold.withValues(alpha: step),
        size: 15,
      );
      final chip = Size(label.width + 20, label.height + 10);
      final left = item.x - chip.width / 2;
      if (left + chip.width > size.width - 8) continue;
      if (left < lastRight + 8) continue;
      lastRight = left + chip.width;
      final center = Offset(item.x, metrics.topStringY - _radius - 20);
      final shape = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: chip.width, height: chip.height),
        Radius.circular(chip.height / 2),
      );
      canvas.drawRRect(
        shape.shift(const Offset(0, 2)),
        Paint()..color = Color.fromRGBO(0, 0, 0, 0.35 * step),
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..shader = ui.Gradient.linear(
            shape.outerRect.topCenter,
            shape.outerRect.bottomCenter,
            [
              RiffColors.goldLit.withValues(alpha: step),
              RiffColors.gold.withValues(alpha: step),
            ],
          ),
      );
      label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
    }
  }

  /// Before the first Play, a quiet line saying which key starts it and
  /// when a note is meant to be played.
  void _paintRestHint(Canvas canvas) {
    final atRest =
        !run.playing && !run.finished && _position <= run.restMs + 1;
    if (!atRest || run.timeline.moments.isEmpty) return;
    final hint = ink.text(
      'Press Space, then play each note as it fills its ring',
      color: neck.ink.withValues(alpha: 0.5),
      size: 20,
      family: RiffFonts.display,
      weight: FontWeight.w400,
      style: FontStyle.italic,
    );
    hint.paint(
      canvas,
      Offset(
        metrics.playheadX + 22,
        metrics.topStringY - _radius - 20 - hint.height / 2,
      ),
    );
  }

  /// The count before the first note: 4, 3, 2, 1, each on its beat.
  void _paintCountIn(Canvas canvas, Size size) {
    final countIn = run.countIn;
    if (countIn == null) return;
    final beat = countIn.beatAt(_position);
    if (beat < 0 || beat >= CountIn.beats) return;
    final number = CountIn.beats - beat.floor();
    // 0 at the start of this beat, 1 at its end.
    final phase = beat - beat.floor();

    // Each number lands large and settles in the first third of its
    // beat, then fades out over the last third to make room for the next.
    final landing = (phase / 0.3).clamp(0.0, 1.0);
    final settle = 1 - math.pow(1 - landing, 3).toDouble();
    final scale = 1.45 - 0.45 * settle;
    final fadeIn = (phase / 0.1).clamp(0.0, 1.0);
    final fadeOut = phase < 0.68 ? 1.0 : 1 - (phase - 0.68) / 0.32;
    final alpha = fadeIn * fadeOut;

    final center = Offset(
      (metrics.playheadX + size.width) / 2,
      (metrics.topStringY + metrics.bottomStringY) / 2,
    );
    // A pool of shade so the number reads over strings and notes.
    canvas.drawCircle(
      center,
      150,
      Paint()
        ..shader = ui.Gradient.radial(center, 150, [
          Color.fromRGBO(0, 0, 0, 0.5 * alpha),
          const Color(0x00000000),
        ]),
    );

    final numeral = ink.text(
      '$number',
      color: RiffColors.goldLit,
      size: 190,
      family: RiffFonts.display,
      weight: FontWeight.w400,
      shadows: const [
        Shadow(color: Color(0xCCE4B15A), blurRadius: 40),
        Shadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 5)),
      ],
    );
    // One see-through layer for the numeral, so its glow fades with it.
    canvas.saveLayer(
      Rect.fromCircle(center: center, radius: 220),
      Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
    );
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    numeral.paint(canvas, Offset(-numeral.width / 2, -numeral.height / 2));
    canvas.restore();

    // Four pips under the number. The beats already counted are lit.
    const gap = 18.0;
    for (var pip = 0; pip < CountIn.beats; pip++) {
      final at = Offset(
        center.dx + (pip - (CountIn.beats - 1) / 2) * gap,
        metrics.bottomStringY + 20,
      );
      final lit = pip <= beat.floor();
      canvas.drawCircle(
        at,
        lit ? 4 : 3,
        Paint()
          ..color = lit
              ? RiffColors.goldLit
              : RiffColors.gold.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StagePainter oldDelegate) {
    return oldDelegate.run != run ||
        oldDelegate.metrics != metrics ||
        oldDelegate.neck != neck ||
        oldDelegate.ink != ink;
  }
}

/// One trip around the loop: how far its notes are shifted in time, and
/// the marks they were given on that trip.
class _Pass {
  const _Pass(this.shiftMs, this.marks, this.number);

  final double shiftMs;
  final Map<SongMoment, ScoreMark> marks;
  final int number;
}

/// A moment that is on the stage this frame, and where.
class _Seen {
  const _Seen(this.moment, this.pass, this.x);

  final SongMoment moment;
  final _Pass pass;
  final double x;

  ScoreMark? get mark => pass.marks[moment];
}
