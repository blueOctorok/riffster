import 'package:flutter/material.dart';

import '../../music/practice_run.dart';
import '../../music/score_note.dart';
import '../../theme/riffster_theme.dart';

/// The card that slides up over the stage when a run ends. It says how
/// the run went and what to work on.
///
/// It keeps wrong notes and off-time notes apart, because they are fixed
/// in different ways. A wrong note is a fretting problem. An early or
/// late one is a timing problem.
class RunSummaryCard extends StatefulWidget {
  const RunSummaryCard({super.key, required this.run});

  final PracticeRun run;

  @override
  State<RunSummaryCard> createState() => _RunSummaryCardState();
}

class _RunSummaryCardState extends State<RunSummaryCard> {
  /// Close was pressed on this run's card. Cleared when a new run
  /// starts, so the next finish shows a card again.
  var _closed = false;

  @override
  void initState() {
    super.initState();
    widget.run.addListener(_onRun);
  }

  @override
  void didUpdateWidget(RunSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run == widget.run) return;
    oldWidget.run.removeListener(_onRun);
    widget.run.addListener(_onRun);
  }

  @override
  void dispose() {
    widget.run.removeListener(_onRun);
    super.dispose();
  }

  void _onRun() {
    setState(() {
      if (!widget.run.finished) _closed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final shown = run.finished && !_closed;
    // While hidden the card sits a little lower and fully see-through.
    // Showing it animates both back, which is the slide up.
    return IgnorePointer(
      ignoring: !shown,
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, 0.12),
        duration: RiffMotion.slide,
        curve: RiffMotion.ease,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: RiffMotion.settle,
          child: _Card(run: run, onClose: () => setState(() => _closed = true)),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.run, required this.onClose});

  final PracticeRun run;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final summary = run.summary;
    return Container(
      key: const Key('run-summary'),
      width: 430,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      decoration: BoxDecoration(
        color: RiffColors.panel.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: RiffColors.gold.withValues(alpha: 0.45)),
        boxShadow: RiffShadows.panel,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(summary.accuracy * 100).round()}%',
                style: RiffText.title.copyWith(
                  fontSize: 64,
                  color: RiffColors.goldLit,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('on time', style: RiffText.label),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Best streak  ${run.bestStreak}',
                  style: RiffText.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Count('On time', summary.onTime, RiffColors.hit),
              _Count('Early', summary.early, RiffColors.gold),
              _Count('Late', summary.late, RiffColors.gold),
              _Count('Missed', summary.missed, RiffColors.miss),
            ],
          ),
          const SizedBox(height: 12),
          Text(_advice(run), style: RiffText.body),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton(
                onPressed: run.restart,
                child: const Text('Again'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onClose, child: const Text('Close')),
            ],
          ),
        ],
      ),
    );
  }
}

/// One or two plain sentences on what the numbers mean.
String _advice(PracticeRun run) {
  final lines = <String>[];
    final timingMs = run.averageTimingMs;
    if (timingMs != null) {
      // Only the part past the circle is worth naming. An average that
      // lands inside it was on time, even when every note led the centre.
      final past = timingMs.abs() - onTimeMs;
      final off = past.round();
      lines.add(
        past < 15
            ? 'Your timing sits on the beat.'
            : timingMs < 0
            ? 'You tend to play about $off ms early. Let the note come to the line.'
            : 'You tend to play about $off ms late. Meet the note sooner.',
      );
    }
  final stray = run.strayNotes;
  if (stray > 0) {
    lines.add(
      stray == 1
          ? '1 sound was a wrong or extra note.'
          : '$stray sounds were wrong or extra notes.',
    );
  }
  if (lines.isEmpty) lines.add('Nothing was heard on this run.');
  final missedBars = _barsWithMisses(run);
  if (missedBars.isNotEmpty) {
    lines.add(
      // A long song could miss in dozens of bars. Past a handful, the
      // count says more than the list.
      missedBars.length > 6
          ? 'Missed notes were in ${missedBars.length} bars.'
          : 'Missed notes were in bar${missedBars.length == 1 ? '' : 's'} '
                '${missedBars.join(', ')}.',
    );
  }
  return lines.join('\n');
}

/// The bars that hold a missed note, numbered from one the way the
/// stage numbers them. Empty for a song with no bar lines.
List<int> _barsWithMisses(PracticeRun run) {
  final bars = run.song.bars;
  final missed = <int>{};
  for (final MapEntry(key: moment, value: mark) in run.marks.entries) {
    if (mark != ScoreMark.miss) continue;
    final bar = bars.indexWhere(
      (bar) => moment.timeMs >= bar.startMs && moment.timeMs < bar.endMs,
    );
    if (bar >= 0) missed.add(bar + 1);
  }
  return missed.toList()..sort();
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$count', style: RiffText.figure.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: RiffText.caption),
        ],
      ),
    );
  }
}
