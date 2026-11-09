import 'package:flutter/material.dart';

import '../music/chord_book.dart';
import '../music/chord_chart.dart';
import 'finger_colors.dart';

const _ink = Color(0xFF2A241C);
const _quiet = Color(0xFF6E675E);

/// A beginner chord card. Low E is the left string. The number in a
/// dot is the finger, in the same colors as the staff.
class ChordShapeCard extends StatelessWidget {
  const ChordShapeCard({
    super.key,
    required this.name,
    required this.grip,
    this.paper = const Color(0xFFF4EFE6),
  });

  final String name;
  final ChordGrip grip;
  final Color paper;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            CustomPaint(
              size: const Size(128, 132),
              painter: _ChartPainter(chartFor(grip, flats: name.contains('b'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.chart);

  final ChordChart chart;

  static const _stringGap = 16.0;
  static const _fretGap = 16.0;
  static const _left = 22.0;
  static const _top = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final gridBottom = _top + chart.fretCount * _fretGap;
    final line = Paint()
      ..color = _ink
      ..strokeWidth = 1.2;

    for (var column = 0; column < 6; column++) {
      final x = _left + column * _stringGap;
      canvas.drawLine(Offset(x, _top), Offset(x, gridBottom), line);
    }
    // The nut is the thick line. A window into the neck has no nut,
    // so the first line stays thin and the fret number sits beside it.
    canvas.drawLine(
      Offset(_left, _top),
      Offset(_left + 5 * _stringGap, _top),
      Paint()
        ..color = _ink
        ..strokeWidth = chart.startFret == 0 ? 3.5 : 1.2,
    );
    for (var fret = 1; fret <= chart.fretCount; fret++) {
      final y = _top + fret * _fretGap;
      canvas.drawLine(
        Offset(_left, y),
        Offset(_left + 5 * _stringGap, y),
        line,
      );
    }

    if (chart.startFret > 0) {
      _letter(
        canvas,
        '${chart.startFret}',
        Offset(8, _top + _fretGap / 2),
        11,
        FontWeight.w700,
      );
    }

    for (final barre in chart.barres) {
      final y = _dotY(barre.fret);
      final x1 = _left + barre.firstColumn * _stringGap;
      final x2 = _left + barre.lastColumn * _stringGap;
      canvas.drawRRect(
        RRect.fromLTRBR(x1, y - 5, x2, y + 5, const Radius.circular(5)),
        Paint()..color = fingerColor[barre.finger]!,
      );
      _letter(
        canvas,
        '${fingerNumber(barre.finger)}',
        Offset(x1, y),
        10,
        FontWeight.w700,
        fingerNumberColor[barre.finger]!,
      );
    }

    for (var column = 0; column < 6; column++) {
      final string = chart.strings[column];
      final x = _left + column * _stringGap;
      final fret = string.fret;
      if (fret == null) {
        _letter(canvas, 'X', Offset(x, 7), 10, FontWeight.w700);
      } else if (fret == 0) {
        canvas.drawCircle(
          Offset(x, 7),
          4,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      } else if (!chart.covers(column)) {
        final finger = string.finger;
        final color = finger == null ? _ink : fingerColor[finger]!;
        final y = _dotY(fret);
        canvas.drawCircle(Offset(x, y), 7, Paint()..color = color);
        if (finger != null) {
          _letter(
            canvas,
            '${fingerNumber(finger)}',
            Offset(x, y),
            10,
            FontWeight.w700,
            fingerNumberColor[finger]!,
          );
        }
      }
      if (string.pitch != null) {
        _letter(
          canvas,
          string.pitch!,
          Offset(x, gridBottom + 11),
          9,
          FontWeight.w600,
          _quiet,
        );
      }
    }
  }

  /// The finger sits in the space behind the fret wire. Fret 1 is the
  /// first space under the nut. A window uses the same spaces, counted
  /// from [ChordChart.startFret].
  double _dotY(int fret) {
    final first = chart.startFret == 0 ? 1 : chart.startFret;
    return _top + (fret - first) * _fretGap + _fretGap / 2;
  }

  void _letter(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    FontWeight weight, [
    Color color = _ink,
  ]) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.chart != chart;
  }
}
