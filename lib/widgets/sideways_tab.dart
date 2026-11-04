import 'package:flutter/material.dart';

import '../models/fretting_finger.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';
import '../music/barre.dart';
import '../music/chord_name.dart';
import '../theme/neck_theme.dart';
import 'finger_colors.dart';

/// Six string lines. Notes move from the right into a fixed playhead.
class SidewaysTab extends StatelessWidget {
  const SidewaysTab({
    super.key,
    required this.song,
    required this.position,
    required this.neck,
  });

  /// Height of the staff band. The screen must not stretch past this.
  static const double height = _SidewaysTabPainter.staffHeight;

  final TabSong song;
  final Duration position;
  final NeckTheme neck;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SidewaysTabPainter(
        song: song,
        positionMs: position.inMilliseconds,
        neck: neck,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SidewaysTabPainter extends CustomPainter {
  _SidewaysTabPainter({
    required this.song,
    required this.positionMs,
    required this.neck,
  });

  final TabSong song;
  final int positionMs;
  final NeckTheme neck;

  static const _stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];
  static const _playheadX = 64.0;

  /// Fixed staff, not stretched to the window. Six strings stay one short band.
  /// The top band is reserved for a chord name, so the strings do not move.
  static const stringGap = 32.0;
  static const chordLabelSpace = 40.0;
  static const staffHeight = chordLabelSpace + stringGap * 5 + 28;

  /// A quarter note at 100 bpm (600 ms) lands about 72 px to the right.
  static const _pixelsPerSecond = 120.0;

  static const _playhead = Color(0xFFE4B15A);

  @override
  void paint(Canvas canvas, Size size) {
    final top =
        chordLabelSpace + (size.height - chordLabelSpace - stringGap * 5) / 2;

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

    final grouped = <int, List<TabNote>>{};
    for (final note in song.notes) {
      grouped.putIfAbsent(note.timeMs, () => []).add(note);
    }
    for (final sounding in grouped.values) {
      final barre = indexBarre(sounding);
      if (barre == null) continue;
      final x = _xFor(sounding.first.timeMs);
      if (x < 40 || x > size.width + 20) continue;
      _paintBarreOval(canvas, x, top, barre);
    }

    for (final note in song.notes) {
      // Time becomes distance from the playhead. Future notes sit to the
      // right. Once [positionMs] passes a note, it slips off to the left.
      final x = _xFor(note.timeMs);
      if (x < 40 || x > size.width + 20) continue;

      final y = top + stringGap * (note.string - 1);
      final passed = note.timeMs < positionMs - 70;
      final finger = note.finger;
      final base = finger == null ? neck.ink : fingerColor[finger]!;
      final color = passed ? base.withValues(alpha: 0.4) : base;
      if (finger == null) {
        // The fill matches the wood, so an open note reads as a ring
        // rather than a dot sitting on a different color.
        canvas.drawCircle(Offset(x, y), 11, Paint()..color = neck.wood);
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

    _paintChordNames(canvas, size, top, grouped);
  }

  double _xFor(int timeMs) {
    return _playheadX + (timeMs - positionMs) / 1000 * _pixelsPerSecond;
  }

  /// A blue outline around the index barre and every note inside its reach.
  /// The other fingers keep their own colors. The oval only says "this is
  /// one barre."
  void _paintBarreOval(
    Canvas canvas,
    double x,
    double stringTop,
    IndexBarre barre,
  ) {
    final y1 = stringTop + stringGap * (barre.topString - 1);
    final y2 = stringTop + stringGap * (barre.bottomString - 1);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(x - 20, y1 - 16, x + 20, y2 + 16),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = fingerColor[FrettingFinger.indexFinger]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// A named chord gets a gold chip, big enough to read as the chord and
  /// not as another fret number. A stack we cannot name stays unlabeled.
  void _paintChordNames(
    Canvas canvas,
    Size size,
    double stringTop,
    Map<int, List<TabNote>> grouped,
  ) {
    final times = grouped.keys.toList()..sort();
    var lastRight = -100.0;
    for (final time in times) {
      final sounding = grouped[time]!;
      if (sounding.length < 2) continue;
      final name = chordName(sounding);
      if (name == null) continue;
      final x = _xFor(time);
      final label = _layoutText(name, const Color(0xFF1A1814), 15);
      final chip = Size(label.width + 16, label.height + 8);
      final left = x - chip.width / 2;
      if (left < 36 || left + chip.width > size.width - 8) continue;
      if (left < lastRight + 8) continue;
      lastRight = left + chip.width;
      final center = Offset(x, stringTop - 22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: chip.width,
            height: chip.height,
          ),
          Radius.circular(chip.height / 2),
        ),
        Paint()..color = _playhead,
      );
      label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
    }
  }

  void _paintDashedString(Canvas canvas, double y, double start, double end) {
    final paint = Paint()
      ..color = neck.ink.withValues(alpha: 0.45)
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
        ..color = neck.ink.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _paintText(canvas, text, center, neck.ink, 11);
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
    final painter = _layoutText(text, color, size);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  TextPainter _layoutText(String text, Color color, double size) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _SidewaysTabPainter oldDelegate) {
    return oldDelegate.positionMs != positionMs ||
        oldDelegate.song != song ||
        oldDelegate.neck != neck;
  }
}
