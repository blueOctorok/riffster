import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../models/fretting_finger.dart';
import '../../theme/neck_theme.dart';
import '../../theme/riffster_theme.dart';
import '../finger_colors.dart';

/// [color] moved toward white (above zero) or toward black (below zero).
Color shade(Color color, double amount) {
  final target = amount >= 0 ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  return Color.lerp(color, target, amount.abs())!;
}

/// The brushes the stage paints with, made once and reused every frame.
///
/// A gradient is a small program the graphics card runs. Building one
/// costs far more than using one, and so does laying out a piece of
/// text. A frame can hold sixty notes, so everything a note needs is
/// built here once, centered on zero. The painter then moves the canvas
/// to the note instead of building a new brush at the note's position.
class StageInk {
  StageInk({required this.noteRadius, required this.neck}) {
    final r = noteRadius;
    for (final finger in FrettingFinger.values) {
      final color = fingerColor[finger]!;
      // Light comes from the upper left, so the bright spot sits there
      // and the color deepens toward the lower right edge.
      _glass[finger] = Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.35, -r * 0.45),
          r * 1.7,
          [shade(color, 0.32), color, shade(color, -0.38)],
          const [0, 0.42, 1],
        );
      _rims[finger] = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = shade(color, -0.5);
    }

    shadow.shader = ui.Gradient.radial(
      Offset(0, r * 0.3),
      r * 1.45,
      const [Color(0x8C000000), Color(0x00000000)],
      const [0.5, 1],
    );
    // The white sheen across the top half is what makes a disc read as
    // glass and not as a flat sticker.
    gloss.shader = ui.Gradient.linear(
      Offset(0, -r * 0.92),
      Offset(0, -r * 0.02),
      const [Color(0x99FFFFFF), Color(0x00FFFFFF)],
    );
    // Light that passes through a glass bead gathers at the bottom.
    underglow.shader = ui.Gradient.radial(
      Offset(0, r * 0.55),
      r * 0.7,
      const [Color(0x38FFFFFF), Color(0x00FFFFFF)],
    );
    hollowFill.color = shade(neck.wood, neck.isLight ? 0.12 : -0.28);
    hollowRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = ui.Gradient.linear(
        Offset(0, -r),
        Offset(0, r),
        [neck.ink, shade(neck.ink, neck.isLight ? 0.25 : -0.3)],
      );
  }

  final double noteRadius;
  final NeckTheme neck;

  final _glass = <FrettingFinger, Paint>{};
  final _rims = <FrettingFinger, Paint>{};
  final shadow = Paint();
  final gloss = Paint();
  final underglow = Paint();
  final hollowFill = Paint();
  final hollowRing = Paint();
  final _text = <String, TextPainter>{};

  Paint glass(FrettingFinger finger) => _glass[finger]!;
  Paint rim(FrettingFinger finger) => _rims[finger]!;

  /// A laid-out piece of text, built the first time it is asked for.
  ///
  /// The stage shows the same few strings over and over: fret numbers,
  /// chord names, the countdown. The key is everything that changes how
  /// the text looks.
  TextPainter text(
    String text, {
    required Color color,
    required double size,
    String family = RiffFonts.text,
    FontWeight weight = FontWeight.w700,
    FontStyle style = FontStyle.normal,
    List<Shadow>? shadows,
  }) {
    final key =
        '$text|${color.toARGB32()}|$size|$family|${weight.value}|'
        '${style.index}|${shadows?.length ?? 0}';
    return _text.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontFamily: family,
            fontWeight: weight,
            fontStyle: style,
            height: 1,
            shadows: shadows,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }
}
