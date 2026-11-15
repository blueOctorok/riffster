import 'package:flutter/material.dart';

import '../../music/scale_line.dart';
import '../../theme/riffster_theme.dart';

/// The twelve roots. The same row sits over a scale and over a drill,
/// and the key is how a test presses one.
class RootChips extends StatelessWidget {
  const RootChips({
    super.key,
    required this.pitchClass,
    required this.onPitchClass,
  });

  final int pitchClass;
  final ValueChanged<int> onPitchClass;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ROOT', style: RiffText.caption),
        const SizedBox(height: 6),
        PracticeChips(
          children: [
            for (var note = 0; note < pitchNames.length; note++)
              PracticeChip(
                key: Key('root-${pitchNames[note]}'),
                label: pitchNames[note],
                selected: note == pitchClass,
                onTap: () => onPitchClass(note),
              ),
          ],
        ),
      ],
    );
  }
}

class PracticeChips extends StatelessWidget {
  const PracticeChips({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: children);
  }
}

class PracticeChip extends StatelessWidget {
  const PracticeChip({
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
        // The label style brings its own color. Copying it without a
        // color would leave the quiet grey on a gold chip.
        style: RiffText.label.copyWith(
          color: selected ? RiffColors.onGold : RiffColors.cream,
        ),
      ),
    );
  }
}
