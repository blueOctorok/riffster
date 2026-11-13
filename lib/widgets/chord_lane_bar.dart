import 'package:flutter/material.dart';

import '../music/chord_lane.dart';
import '../theme/riffster_theme.dart';

const _gold = RiffColors.gold;
const _ink = RiffColors.quiet;
const _chip = RiffColors.panel;

/// A chord's name on its chip in the lane.
final _chordName = RiffText.body.copyWith(
  color: _gold,
  fontWeight: FontWeight.w600,
);

/// The chords dropped so far, in the order they will be played.
class ChordLaneBar extends StatelessWidget {
  const ChordLaneBar({
    super.key,
    required this.lane,
    required this.onDrop,
    required this.onDuration,
    required this.onRemove,
  });

  final List<LaneChord> lane;
  final void Function(LaneDrag drag, int index) onDrop;
  final void Function(int index, int durationMs) onDuration;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('chord-lane'),
      height: 48,
      child: lane.isEmpty
          ? _DropGap(index: 0, onDrop: onDrop, hint: 'Drop a chord here')
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lane.length + 1,
              itemBuilder: (context, index) {
                if (index == lane.length) {
                  return _DropGap(index: index, onDrop: onDrop, hint: '+');
                }
                final previous = index == 0 ? null : lane[index - 1];
                return _LaneChip(
                  index: index,
                  placed: lane[index],
                  stays:
                      previous != null &&
                      fingerStays(previous.block.grip, lane[index].block.grip),
                  onDrop: onDrop,
                  onDuration: (ms) => onDuration(index, ms),
                  onRemove: () => onRemove(index),
                );
              },
            ),
    );
  }
}

class _DropGap extends StatelessWidget {
  const _DropGap({
    required this.index,
    required this.onDrop,
    required this.hint,
  });

  final int index;
  final void Function(LaneDrag drag, int index) onDrop;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DragTarget<LaneDrag>(
      onAcceptWithDetails: (details) => onDrop(details.data, index),
      builder: (context, candidate, _) {
        final hot = candidate.isNotEmpty;
        return Container(
          key: hint == '+' ? null : const Key('chord-lane-empty'),
          width: hint == '+' ? 64 : null,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: hot ? _gold : RiffColors.line),
          ),
          child: Text(hint, style: RiffText.label),
        );
      },
    );
  }
}

class _LaneChip extends StatelessWidget {
  const _LaneChip({
    required this.index,
    required this.placed,
    required this.stays,
    required this.onDrop,
    required this.onDuration,
    required this.onRemove,
  });

  final int index;
  final LaneChord placed;
  final bool stays;
  final void Function(LaneDrag drag, int index) onDrop;
  final ValueChanged<int> onDuration;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // The name moves the chord. The gold edge changes how long it rings,
    // which is also when the next chord starts.
    final width = 72 + placed.durationMs / 40;
    return DragTarget<LaneDrag>(
      onAcceptWithDetails: (details) => onDrop(details.data, index),
      builder: (context, candidate, _) {
        return Container(
          width: width,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: _chip,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: candidate.isNotEmpty ? _gold : RiffColors.line,
              width: candidate.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Draggable<LaneDrag>(
                  data: LaneDrag.move(index),
                  feedback: Material(
                    color: Colors.transparent,
                    child: Text(
                      placed.block.label,
                      style: _chordName.copyWith(fontSize: 16),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: Text(
                      placed.block.label,
                      overflow: TextOverflow.ellipsis,
                      style: _chordName,
                    ),
                  ),
                  child: Text(
                    placed.block.label,
                    overflow: TextOverflow.ellipsis,
                    style: _chordName,
                  ),
                ),
              ),
              if (stays)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'stays',
                    style: RiffText.label.copyWith(color: _gold, fontSize: 11),
                  ),
                ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 14, color: _ink),
              ),
              Tooltip(
                message: 'Drag to change how long it rings',
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final next =
                        placed.durationMs + (details.delta.dx * 25).round();
                    onDuration(next.clamp(laneMinMs, laneMaxMs));
                  },
                  child: const SizedBox(
                    width: 14,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
