import 'package:flutter/material.dart';

import '../../music/practice_run.dart';
import '../../theme/riffster_theme.dart';
import '../room.dart';

/// The strip under the stage that drives a run: restart, play, loop,
/// speed, and where you are in the song.
class TransportDock extends StatefulWidget {
  const TransportDock({
    super.key,
    required this.run,
    required this.enabled,
    required this.loopFromBar,
    required this.loopToBar,
    required this.onLoop,
    required this.onLoopBars,
  });

  final PracticeRun run;

  /// False while a file is opening, or when there is nothing to play.
  final bool enabled;

  /// The bars the loop covers, counted from zero. Both ends are inside.
  final int loopFromBar;
  final int loopToBar;
  final VoidCallback onLoop;
  final void Function(int fromBar, int toBar) onLoopBars;

  @override
  State<TransportDock> createState() => _TransportDockState();
}

class _TransportDockState extends State<TransportDock> {
  /// Play was running when the slider was grabbed, so letting go counts
  /// in and carries on from the new spot.
  var _resumeAfterScrub = false;

  PracticeRun get _run => widget.run;

  void _scrubStarted(double _) {
    _resumeAfterScrub = _run.playing;
    _run.pause();
  }

  void _scrubEnded(double milliseconds) {
    _run.seek(milliseconds);
    if (_resumeAfterScrub) _run.play();
    _resumeAfterScrub = false;
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // The buttons redraw when the run changes state. The slider
          // and the clock redraw every frame, and nothing else does.
          ListenableBuilder(listenable: _run, builder: _buildControls),
          const SizedBox(width: 12),
          Expanded(
            child: ListenableBuilder(
              listenable: _run.frames,
              builder: _buildPosition,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, Widget? _) {
    final enabled = widget.enabled;
    final looping = _run.loop != null;
    final barCount = _run.song.bars.length;
    final from = widget.loopFromBar;
    final to = widget.loopToBar;
    return Row(
      children: [
        IconButton(
          tooltip: 'Restart (R)',
          onPressed: enabled ? _run.restart : null,
          icon: const Icon(Icons.replay_rounded),
        ),
        const SizedBox(width: 6),
        _PlayButton(
          playing: _run.playing,
          onPressed: enabled ? _run.toggle : null,
        ),
        const SizedBox(width: 14),
        const _Divider(),
        const SizedBox(width: 10),
        _LoopButton(on: looping, onPressed: enabled ? widget.onLoop : null),
        if (looping && barCount > 1) ...[
          const SizedBox(width: 6),
          _Stepper(
            caption: 'FROM',
            lessTooltip: 'Start the loop a bar earlier',
            moreTooltip: 'Start the loop a bar later',
            label: '${from + 1}',
            onLess: from > 0 ? () => widget.onLoopBars(from - 1, to) : null,
            onMore: from < to ? () => widget.onLoopBars(from + 1, to) : null,
          ),
          _Stepper(
            caption: 'TO',
            lessTooltip: 'End the loop a bar earlier',
            moreTooltip: 'End the loop a bar later',
            label: '${to + 1}',
            onLess: to > from ? () => widget.onLoopBars(from, to - 1) : null,
            onMore: to < barCount - 1
                ? () => widget.onLoopBars(from, to + 1)
                : null,
          ),
        ],
        const SizedBox(width: 10),
        const _Divider(),
        const SizedBox(width: 6),
        _Stepper(
          caption: 'SPEED',
          label: '${(_run.speed * 100).round()}%',
          lessTooltip: 'Slower (−)',
          moreTooltip: 'Faster (+)',
          onLess: _run.speed > PracticeRun.slowestSpeed
              ? () => _run.nudgeSpeed(-1)
              : null,
          onMore: _run.speed < 1 ? () => _run.nudgeSpeed(1) : null,
        ),
        const SizedBox(width: 6),
        const _Divider(),
      ],
    );
  }

  Widget _buildPosition(BuildContext context, Widget? _) {
    final lengthMs = _run.song.lengthMs;
    // The clock sits below zero during the count. The slider and the
    // label both hold at the start until the song itself begins.
    final placeMs = _run.positionMs.clamp(0, lengthMs).toDouble();
    return Row(
      children: [
        Expanded(
          child: Slider(
            key: const Key('position'),
            value: placeMs,
            max: lengthMs <= 0 ? 1 : lengthMs.toDouble(),
            onChangeStart: _scrubStarted,
            onChanged: widget.enabled ? _run.seek : null,
            onChangeEnd: _scrubEnded,
          ),
        ),
        SizedBox(
          width: 92,
          child: Text(
            '${_clockLabel(placeMs)} / ${_clockLabel(lengthMs)}',
            textAlign: TextAlign.right,
            style: RiffText.label.copyWith(
              // Digits of equal width, so the label does not shiver as
              // the seconds change.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

String _clockLabel(num milliseconds) {
  final position = Duration(milliseconds: milliseconds.floor());
  final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${position.inMinutes}:$seconds';
}

/// The one gold button. It swells a little under the pointer, dips when
/// pressed, and glows while the song is running.
class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback? onPressed;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = !enabled
        ? 1.0
        : _pressed
        ? 0.94
        : _hovered
        ? 1.07
        : 1.0;
    final label = widget.playing ? 'Pause' : 'Play';
    return Tooltip(
      message: '$label (Space)',
      child: Semantics(
        button: true,
        label: label,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            key: const Key('play'),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPressed,
            child: AnimatedScale(
              scale: scale,
              duration: RiffMotion.quick,
              curve: RiffMotion.ease,
              child: AnimatedContainer(
                duration: RiffMotion.settle,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: enabled
                        ? const [RiffColors.goldLit, RiffColors.gold]
                        : const [RiffColors.lineStrong, RiffColors.line],
                  ),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                    if (enabled && (widget.playing || _hovered))
                      ...RiffShadows.goldGlow,
                  ],
                ),
                // The triangle turns into two bars. An AnimatedSwitcher
                // fades and grows the new icon in as the old one leaves.
                child: AnimatedSwitcher(
                  duration: RiffMotion.settle,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    widget.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(widget.playing),
                    size: 30,
                    color: enabled ? RiffColors.onGold : RiffColors.faint,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoopButton extends StatelessWidget {
  const _LoopButton({required this.on, required this.onPressed});

  final bool on;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: on ? 'Stop looping (L)' : 'Loop (L)',
      child: TextButton.icon(
        key: const Key('loop'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: on ? RiffColors.onGold : RiffColors.cream,
          backgroundColor: on ? RiffColors.gold : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        icon: const Icon(Icons.repeat_rounded, size: 20),
        label: Text(on ? 'Looping' : 'Loop'),
      ),
    );
  }
}

/// A value with a button on each side to step it down or up.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.caption,
    required this.label,
    required this.onLess,
    required this.onMore,
    this.lessTooltip,
    this.moreTooltip,
  });

  final String caption;
  final String label;
  final VoidCallback? onLess;
  final VoidCallback? onMore;
  final String? lessTooltip;
  final String? moreTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: lessTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onLess,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(caption, style: RiffText.caption.copyWith(fontSize: 9)),
              const SizedBox(height: 2),
              Text(
                label,
                style: RiffText.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: moreTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onMore,
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 30,
      child: ColoredBox(color: RiffColors.line),
    );
  }
}
