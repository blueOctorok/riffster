import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../audio/guitar_ear.dart';
import '../../models/instrument.dart';
import '../../theme/riffster_theme.dart';
import '../input_sources.dart';
import '../room.dart';
import 'input_status.dart';
import 'level_meter.dart';
import 'recording_line.dart';
import 'tuner.dart';

/// Where the sound comes in and where it goes out: the three input
/// switches, what is connected, the timing check, the tuner, and the
/// speaker. It slides out from the chip at the foot of the rail.
class InputPanel extends StatelessWidget {
  const InputPanel({
    super.key,
    required this.status,
    required this.instrument,
    required this.level,
    required this.tone,
    required this.volume,
    required this.speakerOn,
    required this.onSource,
    required this.onLookAgain,
    required this.onVolume,
    required this.onSpeaker,
    required this.measuredDelayMs,
    required this.onTimingCheck,
    required this.onClose,
    this.clipStarted,
    this.onClip,
  });

  static const width = 340.0;

  final InputStatus status;

  /// The tuner measures against this instrument's open strings.
  final Instrument instrument;

  /// Loudness of the input. It changes many times a second, so only the
  /// meter listens to it. The rest of the panel stays as it is.
  final ValueListenable<double> level;

  /// The pitch that is ringing. Only the tuner listens to it.
  final ValueListenable<double?> tone;
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
  final VoidCallback onClose;

  /// When the open clip began, or null when none is recording.
  final DateTime? clipStarted;

  /// The clip recorder is a tool for building the app. This is null
  /// outside a debug build, and the button is not shown.
  final VoidCallback? onClip;

  @override
  Widget build(BuildContext context) {
    final input = status.input;
    final looking = status.looking;
    final canMonitor = status.canMonitor;
    final clipStarted = this.clipStarted;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Input', style: RiffText.title.copyWith(fontSize: 28)),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InputSources(
            active: input?.active,
            cablePresent: input?.cablePresent ?? false,
            irigPresent: input?.irigPresent ?? false,
            micPresent: input?.micPresent ?? false,
            enabled: !looking,
            onToggle: onSource,
          ),
          const SizedBox(height: 12),
          if (clipStarted != null)
            RecordingLine(started: clipStarted)
          else
            Text(
              status.line,
              key: const Key('input-status'),
              style: RiffText.label.copyWith(
                color: status.needsAttention ? RiffColors.miss : null,
              ),
            ),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: level,
            builder: (context, level, _) => LevelMeter(level: level),
          ),
          const SizedBox(height: 6),
          // A row would run out of room once the clip button and a
          // measured delay are both showing, so these wrap.
          Wrap(
            children: [
              TextButton(
                onPressed: looking || (input == null && !status.failed)
                    ? null
                    : onLookAgain,
                child: Text(looking ? 'Looking…' : 'Look again'),
              ),
              // The next two need an open input.
              if (status.listening)
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
              if (status.listening && onClip != null)
                clipStarted != null
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
            ],
          ),
          const _Rule(),
          Tuner(tone: tone, instrument: instrument),
          const _Rule(),
          Row(
            children: [
              const Icon(
                Icons.volume_down_rounded,
                size: 18,
                color: RiffColors.quiet,
              ),
              Expanded(
                child: Slider(
                  key: const Key('volume'),
                  value: volume,
                  onChanged: canMonitor ? onVolume : null,
                ),
              ),
              TextButton(
                onPressed: canMonitor ? () => onSpeaker(!speakerOn) : null,
                child: Text(
                  canMonitor && speakerOn ? 'Speaker on' : 'Speaker off',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A hairline between two parts of the panel.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(height: 1, child: ColoredBox(color: RiffColors.line)),
    );
  }
}
