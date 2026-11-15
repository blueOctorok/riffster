import 'package:flutter/material.dart';

import '../../music/drill_line.dart';
import '../../theme/riffster_theme.dart';
import '../segment_switch.dart';
import 'practice_chip.dart';

/// Scales and arpeggios, or the drills. The stage holds one of them.
enum PracticePage { scales, drills }

/// The two pages, kept narrow so the switch does not span the stage.
class PracticePageSwitch extends StatelessWidget {
  const PracticePageSwitch({
    super.key,
    required this.page,
    required this.onPage,
  });

  final PracticePage page;
  final ValueChanged<PracticePage> onPage;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 260,
        child: SegmentSwitch<PracticePage>(
          choices: PracticePage.values,
          label: (page) => page == PracticePage.scales ? 'Scales' : 'Drills',
          choiceKey: (page) => Key('practice-${page.name}'),
          selected: page,
          onSelected: onPage,
        ),
      ),
    );
  }
}

/// The drill, and the knobs that shape it: length, note value, difficulty.
///
/// The root row is the key. It is the same row the scales use.
class DrillChoices extends StatelessWidget {
  const DrillChoices({
    super.key,
    required this.pitchClass,
    required this.kind,
    required this.bars,
    required this.value,
    required this.level,
    required this.onPitchClass,
    required this.onKind,
    required this.onBars,
    required this.onValue,
    required this.onLevel,
  });

  final int pitchClass;
  final DrillKind kind;
  final DrillBars bars;
  final NoteValue value;
  final DrillLevel level;
  final ValueChanged<int> onPitchClass;
  final ValueChanged<DrillKind> onKind;
  final ValueChanged<DrillBars> onBars;
  final ValueChanged<NoteValue> onValue;
  final ValueChanged<DrillLevel> onLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RootChips(pitchClass: pitchClass, onPitchClass: onPitchClass),
        const SizedBox(height: 12),
        _row('DRILL', [
          for (final drill in DrillKind.values)
            PracticeChip(
              key: Key('drill-${drill.name}'),
              label: drill.label,
              selected: drill == kind,
              onTap: () => onKind(drill),
            ),
        ]),
        _row('LENGTH', [
          for (final choice in DrillBars.values)
            PracticeChip(
              key: Key('bars-${choice.bars}'),
              label: choice.label,
              selected: choice == bars,
              onTap: () => onBars(choice),
            ),
        ]),
        _row('NOTE', [
          for (final choice in NoteValue.values)
            PracticeChip(
              key: Key('value-${choice.name}'),
              label: choice.label,
              selected: choice == value,
              onTap: () => onValue(choice),
            ),
        ]),
        _row('LEVEL', [
          for (final choice in DrillLevel.values)
            PracticeChip(
              key: Key('level-${choice.name}'),
              label: choice.label,
              selected: choice == level,
              onTap: () => onLevel(choice),
            ),
        ]),
      ],
    );
  }

  Widget _row(String caption, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: RiffText.caption),
        const SizedBox(height: 6),
        PracticeChips(children: chips),
        const SizedBox(height: 12),
      ],
    );
  }
}
