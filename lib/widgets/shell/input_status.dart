import '../../audio/guitar_ear.dart';

/// What the app knows about its input at this moment. The chip on the
/// rail shows the short version, and the input panel the long one.
class InputStatus {
  const InputStatus({
    required this.input,
    this.failed = false,
    this.silent = false,
    this.looking = false,
  });

  /// Null until the devices have been found for the first time.
  final HeardInput? input;

  /// True when no input could be opened at all.
  final bool failed;

  /// True when an input is open and no sound is arriving from it.
  final bool silent;

  /// True while the input is being closed and opened again.
  final bool looking;

  /// True when one of the three switches is on.
  bool get listening => input?.active != null;

  /// Only a guitar cable may reach the speakers. A room mic played out
  /// loud hears itself and howls.
  bool get canMonitor {
    final input = this.input;
    return input != null && input.isGuitar && input.speakerReady;
  }

  /// True when the player needs to do something before a note counts.
  bool get needsAttention => failed || (silent && listening);

  /// A word or two for the chip.
  String get shortLabel {
    if (looking || (input == null && !failed)) return 'Looking…';
    if (failed) return 'No input';
    if (silent && listening) return 'No sound';
    return switch (input?.active) {
      EarSource.cable => 'Cable',
      EarSource.irig => 'iRig',
      EarSource.mic => 'Mic',
      null => 'Input off',
    };
  }

  /// The whole story, for the panel.
  String get line {
    if (failed) {
      return 'No input. Plug in the Rocksmith cable, then press Look again.';
    }
    final input = this.input;
    if (input == null) return 'Looking for an input…';
    if (silent && listening) {
      return 'No sound is arriving. Close any other app using this input.';
    }
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
