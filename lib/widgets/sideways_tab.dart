import 'package:flutter/material.dart';

import '../models/tab_song.dart';
import 'finger_colors.dart';

/// Six string lines. Notes move from the right into a fixed playhead.
class SidewaysTab extends StatelessWidget {
  const SidewaysTab({
    super.key,
    required this.song,
    required this.position,
  });

  /// Height of the staff band. The screen must not stretch past this.
  static const double height = _SidewaysTabPainter.staffHeight;

  final TabSong song;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SidewaysTabPainter(
        song: song,
        positionMs: position.inMilliseconds,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SidewaysTabPainter extends CustomPainter {
  _SidewaysTabPainter({
    required this.song,
    required this.positionMs,
  });

  final TabSong song;
  final int positionMs;

  static const _stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];
  static const _playheadX = 64.0;

  /// Fixed staff, not stretched to the window. Six strings stay one short band.
  static const stringGap = 32.0;
  static const staffHeight = stringGap * 5 + 28;

  /// A quarter note at 100 bpm (600 ms) lands about 72 px to the right.
  static const _pixelsPerSecond = 120.0;

  static const _staff = Color(0xFFF3EEE6);
  static const _dim = Color(0xFF8A8175);
  static const _playhead = Color(0xFFE4B15A);

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - stringGap * 5) / 2;

    for (var i = 0; i < 6; i++) {
      final y = top + stringGap * i;
      _paintDashedString(canvas, y, 46, size.width - 16);
      _paintStringBadge(canvas, _stringNames[i], Offset(22, y));
    }

    canvas.drawLine(
      Offset(_playheadX, top - 10),
      Offset(_playheadX, top + stringGap * 5 + 10),
      Paint()
        ..color = _playhead
        ..strokeWidth = 2,
    );

    for (final note in song.notes) {
      // Time becomes distance from the playhead. Future notes sit to the
      // right. Once [positionMs] passes a note, it slips off to the left.
      final secondsUntil = (note.timeMs - positionMs) / 1000;
      final x = _playheadX + secondsUntil * _pixelsPerSecond;
      if (x < 40 || x > size.width + 20) continue;

      final y = top + stringGap * (note.string - 1);
      final passed = note.timeMs < positionMs - 70;
      final finger = note.finger;
      final base = finger == null ? _staff : fingerColor[finger]!;
      final color = passed ? base.withValues(alpha: 0.4) : base;
      if (finger == null) {
        canvas.drawCircle(
          Offset(x, y),
          11,
          Paint()..color = const Color(0xFF241F1A),
        );
        canvas.drawCircle(
          Offset(x, y),
          11,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        _paintFret(canvas, '${note.fret}', Offset(x, y), color);
      } else {
        canvas.drawCircle(Offset(x, y), 11, Paint()..color = color);
        final number = passed
            ? fingerNumberColor[finger]!.withValues(alpha: 0.45)
            : fingerNumberColor[finger]!;
        _paintFret(canvas, '${note.fret}', Offset(x, y), number);
      }
    }
  }

  void _paintDashedString(Canvas canvas, double y, double start, double end) {
    final paint = Paint()
      ..color = _staff.withValues(alpha: 0.45)
      ..strokeWidth = 1.4;
    const dash = 5.0;
    const gap = 3.0;
    var x = start;
    while (x < end) {
      final dashEnd = x + dash > end ? end : x + dash;
      canvas.drawLine(Offset(x, y), Offset(dashEnd, y), paint);
      x += dash + gap;
    }
  }

  void _paintStringBadge(Canvas canvas, String text, Offset center) {
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = _dim.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _paintText(canvas, text, center, _staff, 11);
  }

  void _paintFret(Canvas canvas, String text, Offset center, Color color) {
    _paintText(canvas, text, center, color, 13);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SidewaysTabPainter oldDelegate) {
    return oldDelegate.positionMs != positionMs || oldDelegate.song != song;
  }
}
