import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../audio/guitar_ear.dart';
import '../../theme/riffster_theme.dart';
import '../input_sources.dart';

/// Where the sound comes in and where it goes out: the three input
/// switches, what is connected, the level, and the speaker.
class InputBar extends StatelessWidget {
  const InputBar({
    super.key,
    required this.input,
    required this.failed,
    required this.looking,
    required this.level,
    required this.volume,
    required this.speakerOn,
    required this.onSource,
    required this.onLookAgain,
    required this.onVolume,
    required this.onSpeaker,
    required this.measuredDelayMs,
    required this.onTimingCheck,
    this.clipRecording = false,
    this.clipStarted,
    this.onClip,
  });

  /// Null until the devices have been found for the first time.
  final HeardInput? input;

  /// True when no input could be opened at all.
  final bool failed;
  final bool looking;

  /// Loudness of the input. It changes many times a second, so only the
  /// meter listens to it. The rest of the bar stays as it is.
  final ValueListenable<double> level;
  final double volume;
  final bool speakerOn;
  final ValueChanged<EarSource> onSource;
  final VoidCallback onLookAgain;
  final ValueChanged<double> onVolume;
  final ValueChanged<bool> onSpeaker;

  /// The delay the timing check found on this input, or null when it
  /// has not been run.
  final double? measuredDelayMs;
  final VoidCallback onTimingCheck;

  /// The clip recorder is a tool for building the app. [onClip] is
  /// null outside a debug build, and the button is not shown.
  final bool clipRecording;

  /// When the open take began. Null unless [clipRecording] is true.
  final DateTime? clipStarted;
  final VoidCallback? onClip;

  @override
  Widget build(BuildContext context) {
    final input = this.input;
    // Only a guitar cable may reach the speakers. A room mic played out
    // loud hears itself and howls.
    final canMonitor = input != null && input.isGuitar && input.speakerReady;
    final speaking = canMonitor && speakerOn;
    final listening = input?.active != null;
    return Row(
      children: [
        InputSources(
          active: input?.active,
          cablePresent: input?.cablePresent ?? false,
          irigPresent: input?.irigPresent ?? false,
          micPresent: input?.micPresent ?? false,
          enabled: !looking,
          onToggle: onSource,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: clipRecording && clipStarted != null
              ? _RecordingLine(started: clipStarted!)
              : Text(
                  _statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiffText.label,
                ),
        ),
        const SizedBox(width: 8),
        // Both need an open input. With none, the status line is a
        // long instruction and gets the room.
        if (listening && onClip != null)
          clipRecording
              ? FilledButton(
                  onPressed: onClip,
                  style: FilledButton.styleFrom(
                    backgroundColor: RiffColors.miss,
                    foregroundColor: RiffColors.cream,
                  ),
                  child: const Text('Save clip'),
                )
              : TextButton(
                  onPressed: onClip,
                  child: const Text('Record clip'),
                ),
        if (listening)
          Tooltip(
            message: canMonitor
                ? 'Measure how far behind the string this input is'
                : 'Needs a cable. The mic would hear the click.',
            child: TextButton(
              key: const Key('timing-check'),
              onPressed: canMonitor && !looking ? onTimingCheck : null,
              child: Text(
                measuredDelayMs == null
                    ? 'Timing check'
                    : 'Timing ${measuredDelayMs!.round()} ms',
              ),
            ),
          ),
        TextButton(
          onPressed: looking || (input == null && !failed) ? null : onLookAgain,
          child: Text(looking ? 'Looking…' : 'Look again'),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder(
          valueListenable: level,
          builder: (context, level, _) => _LevelMeter(level: level),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.volume_down_rounded, size: 18, color: RiffColors.quiet),
        SizedBox(
          width: 120,
          child: Slider(
            key: const Key('volume'),
            value: volume,
            onChanged: canMonitor ? onVolume : null,
          ),
        ),
        TextButton(
          onPressed: canMonitor ? () => onSpeaker(!speakerOn) : null,
          child: Text(speaking ? 'Speaker on' : 'Speaker off'),
        ),
      ],
    );
  }

  String get _statusLabel {
    if (failed) {
      return 'No input. Plug in the Rocksmith cable, then press Look again.';
    }
    final input = this.input;
    if (input == null) return 'Looking for an input…';
    final irigSpeaker = input.irigSpeaker;
    return switch (input.active) {
      EarSource.cable =>
        input.exclusive ? '${input.name} · exclusive' : input.name,
      EarSource.irig => input.name,
      EarSource.mic => 'Microphone · speakers stay off',
      null =>
        irigSpeaker != null
            ? '$irigSpeaker is connected. Turn iRig on, or plug in the Rocksmith cable.'
            : 'Inputs are off. Plug in the Rocksmith cable, or turn the mic on.',
    };
  }
}

/// A rose line that counts up for as long as a clip is open.
///
/// Restart and Play only move the song. The count is what shows the
/// tape is still rolling through both.
class _RecordingLine extends StatefulWidget {
  const _RecordingLine({required this.started});

  final DateTime started;

  @override
  State<_RecordingLine> createState() => _RecordingLineState();
}

class _RecordingLineState extends State<_RecordingLine> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = DateTime.now().difference(widget.started).inSeconds;
    return Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: RiffColors.miss,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Recording · ${seconds}s. Restart does not stop this.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RiffText.label.copyWith(
              color: RiffColors.miss,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A short bar that jumps when the instrument sends a signal.
///
/// A real pluck is often only a fifth of full scale, so the bar treats
/// 0.2 as full. Quiet noise stays a sliver. A dead bar means this input
/// is not hearing the strings.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final filled = (level / 0.2).clamp(0.0, 1.0);
    const radius = BorderRadius.all(Radius.circular(4));
    return SizedBox(
      width: 96,
      height: 8,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: RiffColors.line,
          borderRadius: radius,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: filled,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: filled > 0.85 ? RiffColors.miss : RiffColors.hit,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
