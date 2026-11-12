import 'package:flutter/material.dart';

import '../../audio/pitch.dart';
import '../../music/practice_run.dart';
import '../../music/score_note.dart';
import '../../theme/riffster_theme.dart';
import '../room.dart';

/// What the app just heard and how the run is going: the note, how it
/// was judged, how many in a row, and the share that were on time.
class FeedbackStrip extends StatelessWidget {
  const FeedbackStrip({super.key, required this.run});

  final PracticeRun run;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: ListenableBuilder(
        listenable: run,
        builder: (context, _) {
          final heard = run.heardMidi;
          final mark = run.lastMark;
          final summary = run.summary;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Figure(
                caption: 'HEARD',
                width: 132,
                value: heard == null ? '–' : pitchName(heard),
                color: heard == null ? RiffColors.faint : RiffColors.cream,
                trailing: mark == null ? null : _MarkPill(mark: mark),
              ),
              const _Gap(),
              _TimingGauge(timingMs: run.lastTimingMs),
              const _Gap(),
              _Figure(
                caption: 'IN A ROW',
                width: 76,
                value: '${run.streak}',
                color: run.streak >= 10 ? RiffColors.goldLit : RiffColors.cream,
                // A new key makes Flutter treat each count as a new
                // widget, which is what restarts the little bounce.
                bounceKey: ValueKey(run.streak),
              ),
              const _Gap(),
              _Figure(
                caption: 'ON TIME',
                width: 76,
                value: summary.judged == 0
                    ? '–'
                    : '${(summary.accuracy * 100).round()}%',
                color: summary.judged == 0
                    ? RiffColors.faint
                    : RiffColors.cream,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.caption,
    required this.value,
    required this.color,
    required this.width,
    this.trailing,
    this.bounceKey,
  });

  final String caption;
  final String value;
  final Color color;
  final double width;
  final Widget? trailing;
  final Key? bounceKey;

  @override
  Widget build(BuildContext context) {
    Widget figure = Text(value, style: RiffText.figure.copyWith(color: color));
    if (bounceKey != null) {
      // Starts a third larger and springs back. elasticOut overshoots
      // and wobbles, which is the bounce.
      figure = TweenAnimationBuilder<double>(
        key: bounceKey,
        tween: Tween(begin: value == '0' ? 1 : 1.35, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: child,
        ),
        child: figure,
      );
    }
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: RiffText.caption),
          const SizedBox(height: 4),
          Row(
            children: [
              figure,
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

/// How early or late the last note was. The dot sits left of centre
/// for early and right for late, and the lit band in the middle is
/// the part that counts as on time.
class _TimingGauge extends StatelessWidget {
  const _TimingGauge({required this.timingMs});

  static const _width = 124.0;

  /// Null when the last sound was not played against a note.
  final double? timingMs;

  @override
  Widget build(BuildContext context) {
    final timing = timingMs;
    final onTime = timing != null && timing.abs() <= onTimeMs;
    final color = timing == null
        ? RiffColors.faint
        : RiffColors.forMark(onTime ? ScoreMark.hit : ScoreMark.late);
    return SizedBox(
      width: _width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIMING', style: RiffText.caption),
          const SizedBox(height: 7),
          SizedBox(
            height: 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _GaugeBar(width: _width, color: RiffColors.line),
                // The whole bar is one beat's worth each way, so the
                // on-time band takes the same share of it.
                _GaugeBar(
                  width: _width * onTimeMs / sameBeatMs,
                  color: RiffColors.hit.withValues(alpha: 0.28),
                ),
                const SizedBox(
                  width: 1,
                  height: 12,
                  child: ColoredBox(color: RiffColors.lineStrong),
                ),
                if (timing != null)
                  // Alignment runs from -1 at the left edge to 1 at the
                  // right, which is the same shape as early to late.
                  AnimatedAlign(
                    alignment: Alignment(
                      (timing / sameBeatMs).clamp(-1.0, 1.0),
                      0,
                    ),
                    duration: RiffMotion.quick,
                    curve: RiffMotion.ease,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const SizedBox.square(dimension: 10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _words(timing),
            style: RiffText.label.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static String _words(double? timing) {
    if (timing == null) return '–';
    final ms = timing.round();
    if (ms == 0) return 'On the beat';
    return '${ms.abs()} ms ${ms < 0 ? 'early' : 'late'}';
  }
}

class _GaugeBar extends StatelessWidget {
  const _GaugeBar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }
}

/// The verdict on the last note, in its color.
class _MarkPill extends StatelessWidget {
  const _MarkPill({required this.mark});

  final ScoreMark mark;

  @override
  Widget build(BuildContext context) {
    final color = RiffColors.forMark(mark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        markLabel(mark),
        style: RiffText.label.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(
        width: 1,
        height: 34,
        child: ColoredBox(color: RiffColors.line),
      ),
    );
  }
}
