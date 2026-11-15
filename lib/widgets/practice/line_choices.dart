import 'package:flutter/material.dart';

import '../../music/scale_line.dart';
import '../../theme/riffster_theme.dart';
import 'practice_chip.dart';

/// The root, the scale, and the arpeggio for the line on the stage.
///
/// One of them is in use. Picking a scale clears the arpeggio, and the
/// other way around, because the stage holds one line.
class LineChoices extends StatelessWidget {
  const LineChoices({
    super.key,
    required this.pitchClass,
    required this.kind,
    required this.onPitchClass,
    required this.onKind,
  });

  final int pitchClass;
  final LineKind kind;
  final ValueChanged<int> onPitchClass;
  final ValueChanged<LineKind> onKind;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RootChips(pitchClass: pitchClass, onPitchClass: onPitchClass),
        const SizedBox(height: 12),
        const Text('SCALE', style: RiffText.caption),
        const SizedBox(height: 6),
        PracticeChips(
          children: [
            for (final scale in LineKind.scales)
              PracticeChip(
                key: Key('line-${scale.name}'),
                label: scale.label,
                selected: scale == kind,
                onTap: () => onKind(scale),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('ARPEGGIO', style: RiffText.caption),
        const SizedBox(height: 6),
        PracticeChips(
          children: [
            for (final arp in LineKind.arpeggios)
              PracticeChip(
                key: Key('line-${arp.name}'),
                label: arp.label,
                selected: arp == kind,
                onTap: () => onKind(arp),
              ),
          ],
        ),
      ],
    );
  }
}
