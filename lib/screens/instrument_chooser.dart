import 'package:flutter/material.dart';

import '../models/instrument.dart';
import '../theme/riffster_theme.dart';
import '../widgets/room.dart';
import '../widgets/wordmark.dart';

/// The first thing a new player sees: one question, two answers.
class InstrumentChooser extends StatelessWidget {
  const InstrumentChooser({super.key, required this.onChosen});

  final ValueChanged<Instrument> onChosen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Room(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Wordmark(),
              const SizedBox(height: 28),
              Text(
                'What are you playing?',
                style: RiffText.title.copyWith(fontSize: 48),
              ),
              const SizedBox(height: 10),
              const Text(
                'You can switch at any time from the top of the screen.',
                style: RiffText.label,
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InstrumentCard(
                    instrument: Instrument.bass,
                    onTap: () => onChosen(Instrument.bass),
                  ),
                  const SizedBox(width: 24),
                  _InstrumentCard(
                    instrument: Instrument.guitar,
                    onTap: () => onChosen(Instrument.guitar),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card with the instrument's strings drawn on it. It lifts and its
/// edge turns gold under the pointer.
class _InstrumentCard extends StatefulWidget {
  const _InstrumentCard({required this.instrument, required this.onTap});

  final Instrument instrument;
  final VoidCallback onTap;

  @override
  State<_InstrumentCard> createState() => _InstrumentCardState();
}

class _InstrumentCardState extends State<_InstrumentCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final instrument = widget.instrument;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: Key('choose-${instrument.name}'),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: RiffMotion.settle,
          curve: RiffMotion.ease,
          width: 260,
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: _hovered ? RiffColors.panelLit : RiffColors.panel,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.all(
              color: _hovered ? RiffColors.gold : RiffColors.line,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [...RiffShadows.panel, ...RiffShadows.goldGlow]
                : RiffShadows.panel,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 84,
                width: double.infinity,
                child: CustomPaint(
                  painter: _StringsPainter(instrument.stringCount),
                ),
              ),
              const SizedBox(height: 22),
              Text(instrument.label, style: RiffText.title),
              const SizedBox(height: 4),
              Text(
                '${instrument.stringCount} strings · '
                '${instrument.stringNames.reversed.join(' ')}',
                style: RiffText.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The instrument's strings as plain lines, thicker toward the bottom.
class _StringsPainter extends CustomPainter {
  const _StringsPainter(this.count);

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.height / (count - 1);
    for (var string = 0; string < count; string++) {
      final y = gap * string;
      // Fewer strings are drawn fatter, the way a bass set is.
      final width = (count == 4 ? 2.6 : 1.2) + string * (count == 4 ? 1.0 : 0.5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = RiffColors.goldLit.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_StringsPainter oldDelegate) => oldDelegate.count != count;
}
