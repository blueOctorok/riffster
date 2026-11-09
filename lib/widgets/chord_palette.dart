import 'package:flutter/material.dart';

import '../music/chord_lane.dart';
import 'chord_diagram.dart';

/// Every grip in the book, in one grid. Nothing is behind a Next button
/// or a shelf you have to switch. Low E is the left string of each card.
class ChordPalette extends StatelessWidget {
  const ChordPalette({super.key});

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
            for (final block in chordBlocks)
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
      paper: _paperFor(block.shelf),
    );
    return Draggable<LaneDrag>(
      data: LaneDrag.block(block),
      feedback: Material(color: Colors.transparent, child: face),
      childWhenDragging: Opacity(opacity: 0.35, child: face),
      child: KeyedSubtree(
        key: Key('chord-block-${block.shelf.name}-${block.label}'),
        child: face,
      ),
    );
  }
}

/// A light wash per family, so barre and sevenths read as groups
/// without hiding the open chords.
Color _paperFor(ChordShelf shelf) {
  return switch (shelf) {
    ChordShelf.open => const Color(0xFFF4EFE6),
    ChordShelf.barre => const Color(0xFFE4EEF6),
    ChordShelf.seventh => const Color(0xFFE5F2E6),
  };
}
