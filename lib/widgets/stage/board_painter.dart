import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../theme/neck_theme.dart';
import '../../theme/riffster_theme.dart';
import 'stage_ink.dart';
import 'stage_metrics.dart';

/// The part of the stage that never moves: the wood, its grain, and the
/// nut with the string names.
///
/// It is painted once and kept as a picture. Thousands of grain strokes
/// would be far too much to redraw sixty times a second, and they do not
/// need to be, because only the notes move.
class BoardPainter extends CustomPainter {
  const BoardPainter({required this.neck, required this.metrics});

  final NeckTheme neck;
  final StageMetrics metrics;

  static const _nutBone = [
    Color(0xFFA9997B),
    Color(0xFFE6DABF),
    Color(0xFFF5EDDA),
    Color(0xFFD9CBAE),
    Color(0xFF9C8C6E),
  ];
  static const _nutInk = Color(0xFF3B3023);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final board = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(StageMetrics.cornerRadius),
    );
    canvas.save();
    canvas.clipRRect(board);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shade(neck.wood, 0.06), neck.wood, shade(neck.wood, -0.1)],
        ).createShader(rect),
    );
    _paintGrain(canvas, size);
    _paintLight(canvas, rect);
    _paintNut(canvas, size);
    canvas.restore();

    // A hairline of light along the edge, as if the board had a bevel.
    canvas.drawRRect(
      board.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x1AFFFFFF),
    );
  }

  /// Wood grain, drawn in code so there is no photo to license.
  ///
  /// Three layers: a few wide soft bands, many thin wavy lines, and
  /// short dark pores. The random numbers are seeded from the wood's
  /// name, so a board looks the same every time it is drawn. A bare
  /// `Random()` would give a new pattern on every repaint, and the grain
  /// would crawl.
  void _paintGrain(Canvas canvas, Size size) {
    final seed = neck.name.codeUnits.fold(7, (sum, unit) => sum * 31 + unit);
    final random = math.Random(seed);
    final strength = neck.grainStrength;
    final light = shade(neck.wood, 0.45);

    for (var band = 0; band < 7; band++) {
      _paintGrainLine(
        canvas,
        size,
        random,
        color: neck.grain.withValues(alpha: 0.05 * strength),
        width: 10 + random.nextDouble() * 26,
      );
    }
    final lines = (size.height / 1.6).round();
    for (var line = 0; line < lines; line++) {
      final dark = random.nextDouble() < 0.72;
      final loud = random.nextDouble();
      _paintGrainLine(
        canvas,
        size,
        random,
        color: (dark ? neck.grain : light).withValues(
          alpha: (0.03 + loud * loud * 0.16) * strength,
        ),
        width: 0.5 + random.nextDouble() * 1.2,
      );
    }
    final pore = Paint()
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 260 * strength; i++) {
      final at = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      pore.color = neck.grain.withValues(
        alpha: (0.08 + random.nextDouble() * 0.2) * strength,
      );
      canvas.drawLine(at, at + Offset(4 + random.nextDouble() * 16, 0), pore);
    }
  }

  /// One streak that runs the length of the board, drifting and waving
  /// a little, the way a growth ring does when a plank is cut.
  void _paintGrainLine(
    Canvas canvas,
    Size size,
    math.Random random, {
    required Color color,
    required double width,
  }) {
    final y = random.nextDouble() * size.height;
    final wave = 0.6 + random.nextDouble() * 2.6;
    final waveLength = 240 + random.nextDouble() * 720;
    final phase = random.nextDouble() * math.pi * 2;
    final drift = (random.nextDouble() - 0.5) * 10;
    final path = Path();
    const step = 36.0;
    for (var x = 0.0; x <= size.width + step; x += step) {
      final lineY =
          y +
          drift * (x / size.width) +
          wave * math.sin(x / waveLength * math.pi * 2 + phase);
      if (x == 0) {
        path.moveTo(x, lineY);
      } else {
        path.lineTo(x, lineY);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  /// A fretboard is not flat. It curves away at the top and bottom
  /// edges, so those are darker, and the far end fades into the room.
  void _paintLight(Canvas canvas, Rect rect) {
    final edge = neck.isLight ? 0.6 : 1.0;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0.34 * edge),
            const Color(0x00000000),
            const Color(0x00000000),
            Color.fromRGBO(0, 0, 0, 0.42 * edge),
          ],
          stops: const [0, 0.24, 0.7, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0x00000000),
            Color.fromRGBO(0, 0, 0, 0.36 * edge),
          ],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
    // The polish: a soft stripe of light along the length of the board,
    // where a curved, oiled surface catches the lamp.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 255, neck.isLight ? 0.16 : 0.07),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.1, 0.27, 0.5],
        ).createShader(rect),
    );
    // A pool of warm light where the playhead sits.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(metrics.playheadX / rect.width * 2 - 1, -0.3),
          radius: 0.42,
          colors: [
            RiffColors.goldLit.withValues(alpha: neck.isLight ? 0.16 : 0.09),
            RiffColors.goldLit.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  /// The nut is the bone strip the strings rest in at the top of a real
  /// neck. Here it carries each string's name.
  void _paintNut(Canvas canvas, Size size) {
    const width = StageMetrics.nutWidth;
    final nut = Rect.fromLTWH(0, 0, width, size.height);
    canvas.drawRect(
      nut,
      Paint()
        ..shader = const LinearGradient(
          colors: _nutBone,
          stops: [0, 0.16, 0.5, 0.84, 1],
        ).createShader(nut),
    );
    canvas.drawRect(
      nut,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x40000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0x4D000000),
          ],
          stops: [0, 0.25, 0.7, 1],
        ).createShader(nut),
    );
    // The shadow the nut throws onto the wood beside it.
    final cast = Rect.fromLTWH(width, 0, 16, size.height);
    canvas.drawRect(
      cast,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x80000000), Color(0x00000000)],
        ).createShader(cast),
    );

    for (var string = 1; string <= metrics.instrument.stringCount; string++) {
      final y = metrics.stringY(string);
      final gauge = metrics.stringWidth(string);
      // The slot the string sits in.
      canvas.drawRRect(
        RRect.fromLTRBR(
          width - 10,
          y - gauge / 2 - 1.5,
          width + 1,
          y + gauge / 2 + 1.5,
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0x8C3B3023),
      );
      final name = TextPainter(
        text: TextSpan(
          text: metrics.instrument.stringNames[string - 1],
          style: const TextStyle(
            fontFamily: RiffFonts.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _nutInk,
            height: 1,
            // A pale line under each letter makes it look cut into the
            // bone instead of printed on it.
            shadows: [Shadow(color: Color(0x99FFFFFF), offset: Offset(0, 1))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      name.paint(
        canvas,
        Offset((width - 10 - name.width) / 2, y - name.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.neck != neck || oldDelegate.metrics != metrics;
  }
}
