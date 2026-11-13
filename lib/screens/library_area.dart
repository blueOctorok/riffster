import 'package:flutter/material.dart';

import '../data/library_item.dart';
import '../data/library_store.dart';
import '../models/instrument.dart';
import '../theme/riffster_theme.dart';
import '../widgets/lift_card.dart';

/// Every song kept for the instrument in hand, in groups by where it
/// came from, with the best score at each speed it has been played at.
class LibraryArea extends StatelessWidget {
  const LibraryArea({
    super.key,
    required this.library,
    required this.instrument,
    required this.onOpen,
    required this.onRemove,
  });

  final LibraryStore library;
  final Instrument instrument;

  /// Puts a song on the stage.
  final ValueChanged<LibraryItem> onOpen;
  final ValueChanged<LibraryItem> onRemove;

  static const _columns = 3;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final item in library.items)
        if (item.song.instrument == instrument) item,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Library', style: RiffText.title.copyWith(fontSize: 46)),
          const SizedBox(height: 8),
          Text(
            items.isEmpty
                ? 'Nothing for ${instrument.label.toLowerCase()} yet. '
                      'A part you open from a file is kept here.'
                : 'A part you open from a file is kept here, with your '
                      'best score at each speed.',
            style: RiffText.label,
          ),
          for (final source in SongSource.values)
            ..._group(source, [
              for (final item in items)
                if (item.source == source) item,
            ]),
        ],
      ),
    );
  }

  /// One heading and its cards, or nothing when the group is empty.
  List<Widget> _group(SongSource source, List<LibraryItem> items) {
    if (items.isEmpty) return const [];
    return [
      const SizedBox(height: 28),
      Text(source.label.toUpperCase(), style: RiffText.caption),
      const SizedBox(height: 12),
      // A Wrap would size each card to its own text. LayoutBuilder says
      // how wide the page is, so every card can be exactly a third.
      LayoutBuilder(
        builder: (context, constraints) {
          final width =
              (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _SongCard(
                    item: item,
                    scores: library.bestScores(item.id),
                    onOpen: () => onOpen(item),
                    onRemove: item.source == SongSource.yours
                        ? () => onRemove(item)
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    ];
  }
}

class _SongCard extends StatelessWidget {
  const _SongCard({
    required this.item,
    required this.scores,
    required this.onOpen,
    required this.onRemove,
  });

  final LibraryItem item;
  final List<({int speedPercent, int onTimePercent})> scores;
  final VoidCallback onOpen;

  /// Null for a song that came with the app, which cannot be removed.
  final VoidCallback? onRemove;

  /// More speeds than this would not fit on one line of the card.
  static const _scoresShown = 3;

  @override
  Widget build(BuildContext context) {
    final song = item.song;
    final bars = song.bars.length;
    return LiftCard(
      key: Key('library-${item.id}'),
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiffText.title.copyWith(fontSize: 26),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  key: Key('remove-${item.id}'),
                  onPressed: onRemove,
                  tooltip: 'Remove from the Library',
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: RiffColors.quiet,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${song.tempoBpm} bpm · $bars ${bars == 1 ? 'bar' : 'bars'}',
            style: RiffText.label,
          ),
          if (item.about.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.about,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RiffText.label,
            ),
          ],
          const SizedBox(height: 12),
          if (scores.isEmpty)
            Text(
              'NOT PLAYED YET',
              style: RiffText.caption.copyWith(color: RiffColors.faint),
            )
          else
            Row(
              children: [
                for (final score in scores.take(_scoresShown))
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _Score(
                      speedPercent: score.speedPercent,
                      onTimePercent: score.onTimePercent,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A best score: the share of notes on time, over the speed it was
/// played at.
class _Score extends StatelessWidget {
  const _Score({required this.speedPercent, required this.onTimePercent});

  final int speedPercent;
  final int onTimePercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$onTimePercent%',
          style: RiffText.figure.copyWith(
            fontSize: 22,
            color: RiffColors.goldLit,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          speedPercent == 100 ? 'FULL SPEED' : 'AT $speedPercent%',
          style: RiffText.caption,
        ),
      ],
    );
  }
}
