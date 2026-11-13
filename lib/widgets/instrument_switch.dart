import 'package:flutter/material.dart';

import '../models/instrument.dart';
import '../theme/riffster_theme.dart';

/// Bass or guitar, side by side. The one in use is gold.
class InstrumentSwitch extends StatelessWidget {
  const InstrumentSwitch({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Instrument selected;
  final ValueChanged<Instrument> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: RiffColors.roomDeep,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(BorderSide(color: RiffColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        // The two halves share whatever width the switch is given, so
        // it lines up with the rail it sits in.
        child: Row(
          children: [
            // Bass first. It is the instrument this app is built around.
            for (final instrument in [Instrument.bass, Instrument.guitar])
              Expanded(
                child: _Choice(
                  instrument: instrument,
                  on: instrument == selected,
                  onTap: () => onSelected(instrument),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.instrument,
    required this.on,
    required this.onTap,
  });

  final Instrument instrument;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: Key('instrument-${instrument.name}'),
      // Tapping the one that is already on does nothing, so the song on
      // the stage is not swapped out by accident.
      onPressed: on ? null : onTap,
      style: TextButton.styleFrom(
        backgroundColor: on ? RiffColors.gold : null,
        foregroundColor: RiffColors.quiet,
        disabledForegroundColor: RiffColors.onGold,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(instrument.label),
    );
  }
}
