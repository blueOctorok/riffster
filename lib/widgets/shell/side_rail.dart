import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/instrument.dart';
import '../../theme/riffster_theme.dart';
import '../instrument_switch.dart';
import '../wordmark.dart';
import 'app_area.dart';
import 'input_status.dart';
import 'level_meter.dart';
import 'recording_line.dart';

/// The strip down the left of every screen: where you are, where you
/// can go, which instrument you are holding, and what the app hears.
class SideRail extends StatelessWidget {
  const SideRail({
    super.key,
    required this.area,
    required this.onArea,
    required this.instrument,
    required this.onInstrument,
    required this.status,
    required this.level,
    required this.inputOpen,
    required this.onInput,
    this.clipStarted,
  });

  static const width = 200.0;

  final AppArea area;
  final ValueChanged<AppArea> onArea;
  final Instrument instrument;
  final ValueChanged<Instrument> onInstrument;
  final InputStatus status;
  final ValueListenable<double> level;

  /// True while the input panel is showing.
  final bool inputOpen;
  final VoidCallback onInput;

  /// When the open clip began, or null when none is recording.
  final DateTime? clipStarted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          // Dark glass over the room, so the lamp still shows through.
          color: Color(0x73100E0B),
          border: Border(right: BorderSide(color: RiffColors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wordmark(),
                ),
              ),
              const SizedBox(height: 26),
              for (final item in AppArea.values)
                _AreaButton(
                  area: item,
                  selected: item == area,
                  ready: item.readyFor(instrument),
                  onTap: () => onArea(item),
                ),
              const Spacer(),
              InstrumentSwitch(selected: instrument, onSelected: onInstrument),
              const SizedBox(height: 10),
              _InputChip(
                status: status,
                level: level,
                open: inputOpen,
                onTap: onInput,
                clipStarted: clipStarted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of the rail. The area you are in is lit. An area that is
/// not built yet is dim and says so.
class _AreaButton extends StatelessWidget {
  const _AreaButton({
    required this.area,
    required this.selected,
    required this.ready,
    required this.onTap,
  });

  final AppArea area;
  final bool selected;
  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextButton(
        key: Key('area-${area.name}'),
        onPressed: ready ? onTap : null,
        style: _railButtonStyle(lit: selected),
        child: Row(
          children: [
            Icon(
              area.icon,
              size: 20,
              color: selected
                  ? RiffColors.gold
                  : ready
                  ? RiffColors.quiet
                  : RiffColors.faint,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(area.label)),
            if (!ready)
              Text(
                'SOON',
                style: RiffText.caption.copyWith(
                  fontSize: 9,
                  color: RiffColors.faint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What the app is listening to, in a word, with the level under it.
/// Pressing it opens the input panel.
class _InputChip extends StatelessWidget {
  const _InputChip({
    required this.status,
    required this.level,
    required this.open,
    required this.onTap,
    required this.clipStarted,
  });

  final InputStatus status;
  final ValueListenable<double> level;
  final bool open;
  final VoidCallback onTap;
  final DateTime? clipStarted;

  @override
  Widget build(BuildContext context) {
    final clipStarted = this.clipStarted;
    final color = status.needsAttention ? RiffColors.miss : RiffColors.cream;
    return Tooltip(
      message: 'Input, timing check, and tuner',
      child: TextButton(
        key: const Key('input-chip'),
        onPressed: onTap,
        style: _railButtonStyle(lit: open, outlined: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (clipStarted != null)
              RecordingLine(started: clipStarted, short: true)
            else
              Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status.shortLabel,
                      key: const Key('input-chip-label'),
                      style: TextStyle(color: color),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: RiffColors.quiet,
                  ),
                ],
              ),
            const SizedBox(height: 9),
            ValueListenableBuilder(
              valueListenable: level,
              builder: (context, level, _) =>
                  LevelMeter(level: level, height: 5),
            ),
          ],
        ),
      ),
    );
  }
}

/// The look shared by everything pressable on the rail: left-aligned,
/// and lit with a gold edge when it is the one in use.
ButtonStyle _railButtonStyle({required bool lit, bool outlined = false}) {
  return TextButton.styleFrom(
    foregroundColor: lit ? RiffColors.cream : RiffColors.quiet,
    disabledForegroundColor: RiffColors.faint,
    backgroundColor: lit ? RiffColors.panelLit : null,
    side: BorderSide(
      color: lit
          ? RiffColors.gold
          : outlined
          ? RiffColors.line
          : const Color(0x00000000),
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  );
}
