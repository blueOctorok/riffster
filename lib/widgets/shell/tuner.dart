import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/instrument.dart';
import '../../music/tuning.dart';
import '../../theme/riffster_theme.dart';

/// The needle shows a semitone each way. A string that has slipped
/// more than half a semitone is common, and on a narrower dial its
/// needle would sit hard against the stop and look dead. A string
/// further out than this pins the needle, and the words say so.
const _dialCents = 100.0;

/// How far the needle swings for each cent. A semitone is 80 degrees,
/// so the whole dial is a little short of a half circle.
const _degreesPerCent = 0.8;

/// A needle for tuning the open strings. Play one, and it names the
/// string and shows how far flat or sharp it is.
class Tuner extends StatefulWidget {
  const Tuner({super.key, required this.tone, required this.instrument});

  /// The pitch that is ringing, in hertz. Null when nothing is.
  final ValueListenable<double?> tone;
  final Instrument instrument;

  @override
  State<Tuner> createState() => _TunerState();
}

class _TunerState extends State<Tuner> {
  /// The pitch on show. It outlives the sound by a moment: see [_onTone].
  double? _hertz;
  Timer? _rest;

  @override
  void initState() {
    super.initState();
    widget.tone.addListener(_onTone);
    _hertz = widget.tone.value;
  }

  @override
  void didUpdateWidget(Tuner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tone == widget.tone) return;
    oldWidget.tone.removeListener(_onTone);
    widget.tone.addListener(_onTone);
  }

  @override
  void dispose() {
    widget.tone.removeListener(_onTone);
    _rest?.cancel();
    super.dispose();
  }

  void _onTone() {
    final hertz = widget.tone.value;
    if (hertz != null) {
      _rest?.cancel();
      _rest = null;
      setState(() => _hertz = hertz);
      return;
    }
    // The listener loses a ringing note for a few milliseconds each
    // time it checks the note is still the same one. Dropping the
    // needle on every one of those would make it twitch, so it only
    // goes to rest once the sound has been gone for a while.
    _rest ??= Timer(const Duration(milliseconds: 600), () {
      _rest = null;
      if (mounted) setState(() => _hertz = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hertz = _hertz;
    final reading = hertz == null
        ? null
        : nearestString(hertz, widget.instrument);
    final cents = reading?.cents;
    final inTune = cents != null && cents.abs() <= inTuneCents;
    final color = cents == null
        ? RiffColors.faint
        : inTune
        ? RiffColors.hit
        : RiffColors.gold;
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('TUNER', style: RiffText.caption),
        ),
        SizedBox(
          height: 104,
          width: double.infinity,
          // The needle glides to each new reading. With no sound
          // there is no needle at all, so a needle anywhere on the
          // dial, even against a stop, always means a string is heard.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: cents?.clamp(-_dialCents, _dialCents) ?? 0),
            duration: RiffMotion.quick,
            curve: RiffMotion.ease,
            builder: (context, shown, _) => CustomPaint(
              painter: _DialPainter(
                cents: shown,
                needle: cents == null ? null : color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reading == null ? '–' : widget.instrument.stringNames[reading.string],
          key: const Key('tuner-string'),
          style: RiffText.figure.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          _words(cents),
          key: const Key('tuner-words'),
          style: RiffText.label.copyWith(
            color: cents == null ? RiffColors.quiet : color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  static String _words(double? cents) {
    if (cents == null) return 'Play an open string';
    if (cents.abs() <= inTuneCents) return 'In tune';
    final way = cents < 0 ? 'flat' : 'sharp';
    // Past a semitone the sound is nearer another note than this
    // string, and a count of cents stops being useful.
    if (cents.abs() > 100) return 'Over a semitone $way';
    return '${cents.abs().round()} cents $way';
  }
}

/// The arc, its ticks, and the needle.
class _DialPainter extends CustomPainter {
  const _DialPainter({required this.cents, required this.needle});

  final double cents;

  /// The needle's color, or null to draw the dial with no needle.
  final Color? needle;

  /// Straight up on a canvas, where angles start at three o'clock.
  static const _up = -math.pi / 2;

  static double _radians(double cents) {
    return cents * _degreesPerCent * math.pi / 180;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height - 8);
    final radius = size.height - 18;
    final circle = Rect.fromCircle(center: pivot, radius: radius);

    Offset onDial(double cents, double distance) {
      final angle = _up + _radians(cents);
      return pivot + Offset(math.cos(angle), math.sin(angle)) * distance;
    }

    Paint line(Color color) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color;
    }

    canvas.drawArc(
      circle,
      _up - _radians(_dialCents),
      _radians(_dialCents * 2),
      false,
      line(RiffColors.lineStrong),
    );
    // The part of the arc that counts as in tune.
    canvas.drawArc(
      circle,
      _up - _radians(inTuneCents),
      _radians(inTuneCents * 2),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = RiffColors.hit.withValues(alpha: 0.75),
    );
    for (var tick = -_dialCents; tick <= _dialCents; tick += 10) {
      // A longer mark at the middle, the half semitones, and the ends.
      final long = tick % 50 == 0;
      canvas.drawLine(
        onDial(tick, radius - (long ? 12 : 7)),
        onDial(tick, radius - 3),
        line(long ? RiffColors.quiet : RiffColors.lineStrong),
      );
    }

    final needle = this.needle;
    if (needle == null) {
      canvas.drawCircle(pivot, 5, line(RiffColors.lineStrong));
      return;
    }
    final tip = onDial(cents, radius - 16);
    // A wide, blurred copy under the needle is its glow.
    canvas.drawLine(
      pivot,
      tip,
      Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = needle.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      pivot,
      tip,
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = needle,
    );
    canvas.drawCircle(pivot, 5, Paint()..color = RiffColors.panelLit);
    canvas.drawCircle(
      pivot,
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = needle,
    );
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.needle != needle;
  }
}
