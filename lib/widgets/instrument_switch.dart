import 'package:flutter/material.dart';

import '../models/instrument.dart';
import 'segment_switch.dart';

/// Bass or guitar, side by side. Pressing the one that is already on
/// does nothing, so the song on the stage is not swapped out by accident.
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
    return SegmentSwitch<Instrument>(
      // Bass first. It is the instrument this app is built around.
      choices: const [Instrument.bass, Instrument.guitar],
      label: (instrument) => instrument.label,
      choiceKey: (instrument) => Key('instrument-${instrument.name}'),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
