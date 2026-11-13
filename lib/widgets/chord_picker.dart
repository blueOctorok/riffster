import 'package:flutter/material.dart';

import '../music/chord_catalog.dart';
import '../music/chord_lane.dart';
import '../theme/riffster_theme.dart';

const _gold = RiffColors.gold;
const _ink = RiffColors.cardInk;
const _quiet = RiffColors.quiet;

/// The group chips above the chord cards. One group is open at a time.
/// Barre adds a shape row and a quality row, because twelve roots times
/// ten shapes is a wall. The cards themselves stay a grid you drag.
class ChordPicker extends StatelessWidget {
  const ChordPicker({
    super.key,
    required this.group,
    required this.section,
    required this.onGroup,
    required this.onSection,
  });

  final ChordGroup group;
  final String section;
  final ValueChanged<ChordGroup> onGroup;
  final ValueChanged<String> onSection;

  @override
  Widget build(BuildContext context) {
    final shown = activeSection(group, section);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in ChordGroup.values)
              _Choice(
                key: Key('group-${item.name}'),
                label: item.label,
                selected: item == group,
                onTap: () => onGroup(item),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(group.blurb, style: RiffText.label),
        if (group == ChordGroup.barre) ...[
          const SizedBox(height: 8),
          _barreRows(shown),
        ] else if (sectionsFor(group).length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in sectionsFor(group))
                _Choice(
                  key: Key('section-$item'),
                  label: item,
                  selected: item == shown,
                  onTap: () => onSection(item),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _barreRows(String shown) {
    final shape = barreShape(shown);
    final quality = barreQuality(shown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in const ['E', 'A'])
              _Choice(
                key: Key('barre-shape-$item'),
                label: '$item shape',
                selected: item == shape,
                onTap: () => onSection(barreSection(item, quality)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in const ['Major', 'Minor', '7', 'm7', 'maj7'])
              _Choice(
                key: Key('barre-quality-$item'),
                label: item,
                selected: item == quality,
                onTap: () => onSection(barreSection(shape, item)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      foregroundColor: WidgetStatePropertyAll(selected ? _ink : _quiet),
      backgroundColor: WidgetStatePropertyAll(
        selected ? _gold : const Color(0x00000000),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: selected ? _gold : RiffColors.lineStrong),
      ),
    );
    return FilledButton(style: style, onPressed: onTap, child: Text(label));
  }
}
