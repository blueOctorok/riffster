import 'package:flutter/material.dart';

import '../../music/scale_line.dart';
import '../../theme/riffster_theme.dart';

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
        const Text('ROOT', style: RiffText.caption),
        const SizedBox(height: 6),
        _Chips(
          children: [
            for (var note = 0; note < pitchNames.length; note++)
              _Chip(
                key: Key('root-${pitchNames[note]}'),
                label: pitchNames[note],
                selected: note == pitchClass,
                onTap: () => onPitchClass(note),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('SCALE', style: RiffText.caption),
        const SizedBox(height: 6),
        _Chips(
          children: [
            for (final scale in LineKind.scales)
              _Chip(
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
        _Chips(
          children: [
            for (final arp in LineKind.arpeggios)
              _Chip(
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

class _Chips extends StatelessWidget {
  const _Chips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: children);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? RiffColors.onGold : RiffColors.cream,
        backgroundColor: selected ? RiffColors.gold : RiffColors.panel,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      child: Text(
        label,
        style: RiffText.label.copyWith(
          color: selected ? RiffColors.onGold : RiffColors.cream,
        ),
      ),
    );
  }
}
