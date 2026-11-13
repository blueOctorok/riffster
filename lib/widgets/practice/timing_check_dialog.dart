import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../audio/guitar_ear.dart';
import '../../music/timing_check.dart';
import '../../theme/riffster_theme.dart';
import '../room.dart';

/// Measures how far behind the string the open input is. The player
/// plays one note on each click, and the gap between click and note
/// is the delay.
///
/// Returns the delay in milliseconds, or null when it was closed
/// without one.
Future<double?> showTimingCheck(BuildContext context, GuitarEar ear) {
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TimingCheck(ear: ear),
  );
}

enum _Step { ready, running, done }

class _TimingCheck extends StatefulWidget {
  const _TimingCheck({required this.ear});

  final GuitarEar ear;

  @override
  State<_TimingCheck> createState() => _TimingCheckState();
}

class _TimingCheckState extends State<_TimingCheck>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// The shell's listener, handed back when this closes.
  void Function(int? midi, double agoMs)? _screenListener;

  var _step = _Step.ready;
  var _elapsedMs = 0.0;

  /// A note lands between two frames, and [_elapsedMs] is the time of
  /// the last one. This is the rest.
  final _sinceFrame = Stopwatch();

  /// How many clicks have sounded, the lead-in included.
  var _sounded = 0;
  final _clicksMs = <double>[];
  final _notesMs = <double>[];
  double? _delayMs;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _screenListener = widget.ear.onPluck;
    widget.ear.onPluck = _onNote;
  }

  @override
  void dispose() {
    widget.ear.onPluck = _screenListener;
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    _clicksMs.clear();
    _notesMs.clear();
    _ticker
      ..stop()
      ..start();
    setState(() {
      _step = _Step.running;
      _sounded = 0;
      _elapsedMs = 0;
      _delayMs = null;
    });
  }

  void _onTick(Duration elapsed) {
    _elapsedMs = elapsed.inMicroseconds / 1000;
    _sinceFrame
      ..reset()
      ..start();
    const clicks = timingCheckLeadIn + timingCheckClicks;
    if (_sounded < clicks && _elapsedMs >= _sounded * timingCheckBeatMs) {
      widget.ear.click(accent: _sounded % 4 == 0);
      // The time the click was really asked for, not the time it was
      // due. A frame can be a few milliseconds late.
      if (_sounded >= timingCheckLeadIn) _clicksMs.add(_elapsedMs);
      setState(() => _sounded++);
    }
    // Half a beat after the last click, a late note has had its chance.
    if (_elapsedMs < (clicks - 0.5) * timingCheckBeatMs) return;
    _ticker.stop();
    setState(() {
      _step = _Step.done;
      _delayMs = measuredDelayMs(clicksMs: _clicksMs, notesMs: _notesMs);
    });
  }

  void _onNote(int? midi, double agoMs) {
    if (_step != _Step.running) return;
    _notesMs.add(_elapsedMs + _sinceFrame.elapsedMicroseconds / 1000 - agoMs);
  }

  String get _status {
    final delay = _delayMs;
    return switch (_step) {
      _Step.ready => 'Press Start when your hands are ready.',
      _Step.running =>
        _sounded <= timingCheckLeadIn ? 'Get ready…' : 'Play on each click.',
      _Step.done when _notesMs.isEmpty =>
        'No notes were heard. Check that the level bar moves when you play.',
      _Step.done when delay == null =>
        'That was too uneven to measure. Try again, one note on each click.',
      _Step.done =>
        'Your notes arrive ${delay!.abs().round()} ms '
            '${delay < 0 ? 'before' : 'after'} the click.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final measured = (_sounded - timingCheckLeadIn).clamp(0, timingCheckClicks);
    return Dialog(
      backgroundColor: const Color(0x00000000),
      child: GlassPanel(
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Timing check', style: RiffText.title),
              const SizedBox(height: 12),
              const Text(
                'Every input is a little behind the string. This measures '
                'how much, so a note played on time is scored on time.\n\n'
                'Play any one note on each click. The first four clicks '
                'are to get ready. The next eight are measured.',
                style: RiffText.body,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  for (var pip = 0; pip < timingCheckClicks; pip++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AnimatedContainer(
                        duration: RiffMotion.quick,
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pip < measured
                              ? RiffColors.gold
                              : RiffColors.line,
                          boxShadow: pip == measured - 1 &&
                                  _step == _Step.running
                              ? RiffShadows.goldGlow
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Room for two lines, so the box does not jump when a
              // longer message wraps.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Text(
                  _status,
                  style: RiffText.body.copyWith(color: RiffColors.cream),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (_step != _Step.running)
                    OutlinedButton(
                      onPressed: _start,
                      child: Text(_step == _Step.ready ? 'Start' : 'Again'),
                    ),
                  if (_delayMs != null) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_delayMs),
                      child: const Text('Use it'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
