import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';

import 'pitch.dart';

/// How long after the pluck the buffer reaches Dart.
///
/// The playhead has already moved by then. Scoring uses an earlier moment
/// so an on-time note is not called late. This is a first guess.
const inputLatencyMs = 50;

/// Speaker mix, in frames. At 48 kHz this is about 5 ms.
const _speakerBufferFrames = 256;

/// How long the speaker waits for audio before it starts. A longer wait
/// hides gaps. A shorter wait stays closer to the string.
const _speakerPrefillSeconds = 0.005;

/// What the practice screen shows once the input and the speaker are open.
class HeardInput {
  const HeardInput({
    required this.name,
    required this.isGuitar,
    required this.speakerReady,
    required this.inputs,
    this.irigSpeaker,
  });

  final String name;

  /// True when the open input is a guitar cable, not the room mic.
  final bool isGuitar;
  final bool speakerReady;

  /// Every input Windows offered. Empty when a guitar cable is in use.
  final List<String> inputs;

  /// Set when the iRig speaker is on but Windows did not start a guitar input.
  final String? irigSpeaker;
}

/// Listens to a guitar cable and plays that signal out the speakers.
///
/// A PC microphone played through the speakers hears itself. The playback
/// buffer then fills, so the voice comes back later and later, and the loop
/// grows into a howl. The room mic is scored, and it is never sent to a speaker.
/// The Rocksmith cable has no headphone jack, so its guitar comes out the
/// PC speakers. An iRig still prefers its own speaker jack.
class GuitarEar {
  /// Called when a new pluck has a pitch. Set before [start].
  void Function(int midi)? onPitch;

  /// Loudness of the latest chunk, from 0 to about 1. Drives the level meter.
  void Function(double level)? onLevel;

  /// Called once the devices are known, whether or not the speaker opened.
  void Function(HeardInput status)? onReady;

  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  final _window = <double>[];
  var _holding = false;
  var _sampleRate = 44100;
  var _started = false;
  var _closed = false;
  var _opening = false;
  var _speakerOn = false;
  var _guitarInputOpen = false;
  var _monitorReady = false;
  AudioSource? _monitor;
  SoundHandle? _monitorHandle;

  /// The speaker follows the guitar while this is true.
  bool get speakerOn => _speakerOn;

  set speakerOn(bool value) {
    // A room mic must not be able to turn the loop on.
    if (value && !_guitarInputOpen) {
      _speakerOn = false;
      return;
    }
    _speakerOn = value;
    final handle = _monitorHandle;
    final monitor = _monitor;
    if (!_monitorReady ||
        handle == null ||
        monitor == null ||
        !SoLoud.instance.isInitialized) {
      return;
    }
    if (value) {
      try {
        SoLoud.instance.resetBufferStream(monitor);
      } catch (_) {}
    }
    SoLoud.instance.setVolume(handle, value ? 1 : 0);
  }

  /// Asks Windows again, and switches over if the guitar cable is there now.
  ///
  /// Starting the app and then plugging the cable in does not update the
  /// open stream. This only restarts when a guitar input has appeared.
  Future<void> lookForGuitar() async {
    if (_closed || _opening || _guitarInputOpen) return;
    try {
      final devices = await _recorder.listInputDevices();
      if (_closed || _guitarInputOpen || guitarInput(devices) == null) return;
      await restart();
    } catch (_) {}
  }

  /// Closes the current input and asks Windows again.
  ///
  /// A device plugged in after the window opened is invisible until this runs.
  Future<void> restart() async {
    if (_closed || _opening) return;
    await stop();
    _monitorReady = false;
    _monitorHandle = null;
    _monitor = null;
    if (SoLoud.instance.isInitialized) {
      SoLoud.instance.deinit();
    }
    await start();
  }

  Future<void> start() async {
    if (_started || _closed || _opening) return;
    _opening = true;
    try {
      await _start();
    } finally {
      _opening = false;
    }
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('The guitar input is not allowed.');
    }
    if (_closed) return;

    final devices = await _recorder.listInputDevices();
    if (_closed) return;
    final device = guitarInput(devices);
    _sampleRate = _sampleRateFor(device);
    final inputName = device?.label ?? 'the PC mic';
    _guitarInputOpen = device != null;
    _speakerOn = _guitarInputOpen;
    if (_guitarInputOpen) {
      await _openSpeaker(throughIrig: _playsThroughIrig(device!.label));
    }
    if (_closed) return;

    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        device: device,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
    if (_closed) {
      await _recorder.cancel();
      return;
    }
    _started = true;
    _subscription = stream.listen(_onBytes, onError: (_) {});
    onReady?.call(
      HeardInput(
        name: inputName,
        isGuitar: device != null,
        speakerReady: _monitorReady,
        inputs: device != null
            ? const []
            : [for (final item in devices) item.label],
        irigSpeaker: device == null ? _irigSpeakerName() : null,
      ),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_started) {
      await _recorder.cancel();
      _started = false;
    }
    _window.clear();
    _holding = false;
  }

  Future<void> dispose() async {
    _closed = true;
    await stop();
    _monitorHandle = null;
    _monitor = null;
    _monitorReady = false;
    if (SoLoud.instance.isInitialized) {
      SoLoud.instance.deinit();
    }
    await _recorder.dispose();
  }

  /// Plays the guitar. An iRig uses its own jack. The Rocksmith cable uses
  /// the PC speakers, because that cable has no jack of its own.
  ///
  /// The engine waits a few milliseconds before the first sound so a short
  /// gap does not click. The capture side is asked for a short buffer too.
  Future<void> _openSpeaker({required bool throughIrig}) async {
    try {
      PlaybackDevice? irig;
      if (throughIrig) {
        final outputs = SoLoud.instance.listPlaybackDevices();
        for (final output in outputs) {
          if (output.name.toLowerCase().contains('irig')) {
            irig = output;
            break;
          }
        }
      }
      await SoLoud.instance.init(
        device: irig,
        sampleRate: _sampleRate,
        bufferSize: _speakerBufferFrames,
        channels: Channels.stereo,
        lowLatency: true,
      );
      if (_closed) {
        SoLoud.instance.deinit();
        return;
      }
      final monitor = SoLoud.instance.setBufferStream(
        maxBufferSizeBytes: 64 * 1024,
        bufferingType: BufferingType.released,
        bufferingTimeNeeds: _speakerPrefillSeconds,
        sampleRate: _sampleRate,
        channels: Channels.mono,
        format: BufferType.s16le,
      );
      _monitor = monitor;
      _monitorHandle = SoLoud.instance.play(
        monitor,
        volume: _speakerOn ? 1 : 0,
      );
      _monitorReady = true;
    } catch (_) {
      _monitorReady = false;
      _monitor = null;
      _monitorHandle = null;
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.deinit();
      }
    }
  }

  void _onBytes(Uint8List bytes) {
    if (_closed) return;
    _play(bytes);

    final data = ByteData.sublistView(bytes);
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little) / 32768;
      _window.add(sample);
      sum += sample * sample;
      count++;
    }
    if (count > 0) onLevel?.call(math.sqrt(sum / count));

    const size = 2048;
    while (_window.length >= size) {
      final midi = midiFromSamples(_window.sublist(0, size), _sampleRate);
      _window.removeRange(0, 1024);
      _hear(midi);
    }
  }

  void _play(Uint8List bytes) {
    final monitor = _monitor;
    if (!_speakerOn || !_monitorReady || monitor == null || bytes.isEmpty) {
      return;
    }
    try {
      // Bytes still waiting to be spoken. 16-bit mono is 2 bytes a sample,
      // so this cap is about 40 ms. Past that, the string and the speaker
      // have drifted, and the newest chunk replaces the pile.
      final queued = SoLoud.instance.getBufferSize(monitor);
      final slackBytes = _sampleRate * 2 * 40 ~/ 1000;
      if (queued > slackBytes) {
        SoLoud.instance.resetBufferStream(monitor);
      }
      SoLoud.instance.addAudioDataStream(monitor, bytes);
    } catch (_) {
      // A full buffer must not stop pitch detection.
    }
  }

  /// A new pluck is a pitch after silence. A ringing note stays one attack,
  /// so a long tone is not scored on every buffer.
  void _hear(int? midi) {
    if (midi == null) {
      _holding = false;
      return;
    }
    if (_holding) return;
    _holding = true;
    onPitch?.call(midi);
  }
}

/// The iRig speaker, when Windows started that side and not the guitar input.
String? _irigSpeakerName() {
  try {
    for (final output in SoLoud.instance.listPlaybackDevices()) {
      if (output.name.toLowerCase().contains('irig')) return output.name;
    }
  } catch (_) {}
  return null;
}

/// A guitar cable Windows has started as a recording device.
///
/// The Rocksmith Real Tone cable shows up as "Rocksmith USB Guitar Adapter".
/// It wins over an iRig, because the iRig's guitar side may still be off.
/// A room microphone is not a match.
InputDevice? guitarInput(List<InputDevice> devices) {
  for (final device in devices) {
    if (isRocksmithCable(device.label)) return device;
  }
  for (final device in devices) {
    if (device.label.toLowerCase().contains('irig')) return device;
  }
  return null;
}

/// The Real Tone cable. Matching the name is enough. The audio itself is
/// ordinary PCM, and the app does not open Rocksmith's song files.
bool isRocksmithCable(String label) {
  final name = label.toLowerCase();
  return name.contains('rocksmith') ||
      name.contains('real tone') ||
      name.contains('guitar adapter');
}

/// An iRig input can play back through the iRig jack. The Rocksmith cable
/// cannot, so its monitor is the PC speakers.
bool _playsThroughIrig(String label) {
  return !isRocksmithCable(label) && label.toLowerCase().contains('irig');
}

int _sampleRateFor(InputDevice? device) {
  final rates = device?.sampleRates ?? const <int>[];
  if (rates.contains(48000)) return 48000;
  if (rates.contains(44100)) return 44100;
  if (rates.isNotEmpty) return rates.first;
  return 44100;
}
