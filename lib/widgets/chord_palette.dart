import 'package:flutter/material.dart';

import '../music/chord_lane.dart';
import 'chord_diagram.dart';

/// The cards for one group. Every card in that group is on screen
/// together, and each one can be dragged. There is no Next button.
class ChordPalette extends StatelessWidget {
  const ChordPalette({super.key, required this.blocks});

  final List<ChordBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 6;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final block in blocks)
              SizedBox(width: width, child: _ChordBlock(block)),
          ],
        );
      },
    );
  }
}

class _ChordBlock extends StatelessWidget {
  const _ChordBlock(this.block);

  final ChordBlock block;

  @override
  Widget build(BuildContext context) {
    final face = ChordShapeCard(
      name: block.label,
      grip: block.grip,
      paper: _paperFor(block.group),
    );
    return Draggable<LaneDrag>(
      data: LaneDrag.block(block),
      feedback: Material(color: Colors.transparent, child: face),
      childWhenDragging: Opacity(opacity: 0.35, child: face),
      child: KeyedSubtree(
        key: Key('chord-block-${block.group.name}-${block.label}'),
        child: face,
      ),
    );
  }
}

/// A light wash per family, so a barre card does not look like an open one.
Color _paperFor(ChordGroup group) {
  return switch (group) {
    ChordGroup.open => const Color(0xFFF4EFE6),
    ChordGroup.barre => const Color(0xFFE4EEF6),
    ChordGroup.seventh => const Color(0xFFE5F2E6),
    ChordGroup.sus => const Color(0xFFF8F1D8),
    ChordGroup.power => const Color(0xFFE8E6F2),
    ChordGroup.more => const Color(0xFFF8E8EA),
  };
}
