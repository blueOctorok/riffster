import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';

import '../models/instrument.dart';
import 'exclusive_guitar.dart';
import 'pluck_detector.dart';
import 'sample_clock.dart';
import 'silence_watch.dart';
import 'wav.dart';

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

/// Which input the switches are choosing. Only one is open at a time.
enum EarSource { cable, irig, mic }

/// The input to open, or null when every switch is off.
///
/// A preferred source wins when that device is plugged in. With no
/// preference, the Rocksmith cable wins, then an iRig. The room mic is
/// never chosen on its own. It has to be asked for, because a guitar
/// plug-in is supposed to take the seat.
EarSource? listeningChoice({
  required bool cable,
  required bool irig,
  required bool mic,
  required Set<EarSource> suppressed,
  EarSource? preferred,
}) {
  bool open(EarSource source) {
    final present = switch (source) {
      EarSource.cable => cable,
      EarSource.irig => irig,
      EarSource.mic => mic,
    };
    return present && !suppressed.contains(source);
  }

  if (preferred != null) return open(preferred) ? preferred : null;
  if (open(EarSource.cable)) return EarSource.cable;
  if (open(EarSource.irig)) return EarSource.irig;
  return null;
}

/// What the input panel shows once the input and the speaker are open.
class HeardInput {
  const HeardInput({
    required this.name,
    required this.isGuitar,
    required this.speakerReady,
    required this.inputs,
    required this.cablePresent,
    required this.irigPresent,
    required this.micPresent,
    this.active,
    this.irigSpeaker,
    this.exclusive = false,
    this.latencyMs = inputLatencyMs,
  });

  final String name;

  /// True when the open input is a guitar cable, not the room mic.
  final bool isGuitar;
  final bool speakerReady;

  /// The switch that is on. Null when the listener is quiet.
  final EarSource? active;
  final bool cablePresent;
  final bool irigPresent;
  final bool micPresent;

  /// Every input Windows offered. Empty when a guitar cable is in use.
  final List<String> inputs;

  /// Set when the iRig speaker is on but Windows did not start a guitar input.
  final String? irigSpeaker;

  /// True when the cable is open in exclusive mode.
  final bool exclusive;

  /// How far behind the string this path is, in milliseconds. A guess,
  /// used until the timing check has measured it.
  final int latencyMs;

  /// A name for the route the sound takes: which device, and which of
  /// the ways Windows opened it. Each route has its own delay, so a
  /// measured delay is saved under this name. Null when nothing is
  /// open.
  ///
  /// The guess is part of the name because every way of opening an
  /// input has a different guess, and nothing else tells them apart.
  String? get route => active == null ? null : '$name · $latencyMs';
}

/// Listens to a guitar cable and plays that signal out the speakers.
///
/// A PC microphone played through the speakers hears itself. The playback
/// buffer then fills, so the voice comes back later and later, and the loop
/// grows into a howl. The room mic is scored, and it is never sent to a speaker.
/// The Rocksmith cable has no headphone jack, so its guitar comes out the
/// PC speakers. An iRig still prefers its own speaker jack.
class GuitarEar {
  /// Called for each note the player starts. Set before [start].
  ///
  /// [midi] is null for a sound with no single pitch, such as a strum.
  /// [agoMs] is how long before this call the note reached the app. A
  /// low note takes longer to name than a high one, and the score must
  /// not depend on that.
  void Function(int? midi, double agoMs)? onPluck;

  /// Every chunk of raw sound, as 16-bit samples. Only the debug clip
  /// recorder listens.
  void Function(Uint8List bytes)? onSound;

  /// Loudness of the latest chunk, from 0 to about 1. Drives the level meter.
  void Function(double level)? onLevel;

  /// The pitch of the note that is ringing, in hertz, after every chunk.
  /// Null when no single note is. Drives the tuner.
  void Function(double? hertz)? onTone;

  /// Called once the devices are known, whether or not the speaker opened.
  void Function(HeardInput status)? onReady;

  /// Called with true when the open input turns out to send no sound,
  /// and with false when sound arrives again.
  void Function(bool silent)? onSilent;
  final _silence = SilenceWatch();

  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  var _instrument = Instrument.bass;
  var _sampleRate = 44100;
  late var _detector = _newDetector();
  late var _clock = SampleClock(_sampleRate);

  /// The app's clock. Chunks are stamped with it as they arrive.
  final _watch = Stopwatch()..start();
  var _started = false;
  var _closed = false;
  var _opening = false;
  var _speakerOn = false;

  /// 0 is silent. 1 is as loud as this path is meant to be. On the exclusive
  /// path that is the four-times boost. The shared path is already boosted
  /// by Windows, so 1 there is left alone.
  var _volume = 1.0;
  var _guitarInputOpen = false;
  var _monitorReady = false;
  var _exclusive = false;
  var _latencyMs = inputLatencyMs;

  /// The room mic starts suppressed. A guitar input is chosen on its own.
  /// Turning a switch off adds that source here so the next look does not
  /// turn it straight back on.
  final _suppressed = <EarSource>{EarSource.mic};
  EarSource? _preferred;
  EarSource? _openSource;
  var _sawCable = false;
  var _sawIrig = false;
  var _cablePresent = false;
  var _irigPresent = false;
  var _micPresent = false;
  StreamSubscription<Uint8List>? _exclusivePcm;
  AudioSource? _monitor;
  SoundHandle? _monitorHandle;

  /// The count-in click and its higher beat-one version, for the path
  /// where Windows mixes the speakers. The exclusive path makes its own.
  AudioSource? _click;
  AudioSource? _accentClick;

  /// Which instrument to listen for. A bass is heard an octave lower
  /// than a guitar, so the detector is rebuilt for its range.
  set instrument(Instrument value) {
    if (value == _instrument) return;
    _instrument = value;
    _listenAfresh();
  }

  PluckDetector _newDetector() {
    return PluckDetector(sampleRate: _sampleRate, instrument: _instrument);
  }

  /// Starts counting samples from zero, for a new input or instrument.
  void _listenAfresh() {
    _detector = _newDetector();
    _clock = SampleClock(_sampleRate);
  }

  /// The speaker follows the guitar while this is true.
  bool get speakerOn => _speakerOn;

  /// How loud the guitar is in the speakers. 1 is the level that sounded right.
  double get volume => _volume;

  set volume(double value) {
    _volume = value.clamp(0.0, 1.0).toDouble();
    if (_exclusive) {
      unawaited(ExclusiveGuitar.setVolume(_volume));
      return;
    }
    _applySharedVolume();
  }

  /// How far behind the string the open path is. Scoring subtracts this.
  int get latencyMs => _latencyMs;

  /// Samples a second on the open input.
  int get sampleRate => _sampleRate;

  /// True when a click can be heard: a guitar cable is open. With the
  /// room mic there is no click, because the mic would hear it.
  bool get canClick => _guitarInputOpen && _monitorReady;

  /// A short tick out of the speakers, for the count-in. [accent] is
  /// the higher one on beat one.
  void click({bool accent = false}) {
    if (!canClick) return;
    if (_exclusive) {
      unawaited(ExclusiveGuitar.click(accent: accent));
      return;
    }
    final source = accent ? _accentClick : _click;
    if (source == null || !SoLoud.instance.isInitialized) return;
    SoLoud.instance.play(source);
  }

  set speakerOn(bool value) {
    // A room mic must not be able to turn the loop on.
    if (value && !_guitarInputOpen) {
      _speakerOn = false;
      if (_exclusive) unawaited(ExclusiveGuitar.setSpeaker(false));
      return;
    }
    _speakerOn = value;
    if (_exclusive) {
      unawaited(ExclusiveGuitar.setSpeaker(value));
      return;
    }
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
    _applySharedVolume();
  }

  void _applySharedVolume() {
    final handle = _monitorHandle;
    if (handle == null || !SoLoud.instance.isInitialized) return;
    SoLoud.instance.setVolume(handle, _speakerOn ? _volume : 0);
  }

  /// Asks Windows again. A cable plugged in after launch takes the seat
  /// from the room mic. A switch the player turned off stays off. An
  /// open input that has gone silent is closed and opened again.
  Future<void> lookForGuitar() async {
    if (_closed || _opening) return;
    final wasSilent = _silence.silent;
    final reopen = _silence.look(open: _started && _openSource != null);
    if (_silence.silent != wasSilent) onSilent?.call(_silence.silent);
    try {
      final devices = await _recorder.listInputDevices();
      if (_closed || _opening) return;
      _notePresence(devices);
      final next = listeningChoice(
        cable: _cablePresent,
        irig: _irigPresent,
        mic: _micPresent,
        suppressed: _suppressed,
        preferred: _preferred,
      );
      if (next == _openSource && _started && !reopen) return;
      await restart();
    } catch (_) {}
  }

  /// Turns one source on, or off when it is already the open one.
  ///
  /// The other two go off. One recording device is open, so the cable
  /// and the iRig and the mic are never heard together.
  Future<void> choose(EarSource source) async {
    if (_closed || _opening) return;
    if (_openSource == source) {
      _preferred = null;
      _suppressed.addAll(EarSource.values);
    } else {
      _preferred = source;
      _suppressed
        ..clear()
        ..addAll(EarSource.values.where((item) => item != source));
    }
    await restart();
  }

  /// Closes the current input and asks Windows again.
  ///
  /// A device plugged in after the window opened is invisible until this runs.
  Future<void> restart() async {
    if (_closed || _opening) return;
    await stop();
    _closeSpeaker();
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
    _notePresence(devices);
    final source = listeningChoice(
      cable: _cablePresent,
      irig: _irigPresent,
      mic: _micPresent,
      suppressed: _suppressed,
      preferred: _preferred,
    );
    _openSource = source;
    final device = source == null ? null : deviceFor(devices, source);
    _sampleRate = _sampleRateFor(device);
    _listenAfresh();
    final inputName = device?.label ?? 'Off';
    _guitarInputOpen = source == EarSource.cable || source == EarSource.irig;
    // The room mic is scored and never played. Opening it must not arm
    // the speaker, or the laptop hears itself and the loop howls.
    _speakerOn = _guitarInputOpen;
    _latencyMs = inputLatencyMs;
    if (source == null || device == null) {
      _started = true;
      _report(name: inputName, devices: devices);
      return;
    }
    // Exclusive mode copies the cable buffer to the speakers on an audio
    // thread. The bytes never visit Dart on the way to the speaker, which
    // is the delay that was left. Pitch still uses the copy that arrives here.
    // It always prefers the Rocksmith cable, so an iRig chosen while that
    // cable is also plugged in stays on the shared recorder.
    final exclusiveOk =
        source == EarSource.cable ||
        (source == EarSource.irig && !_cablePresent);
    if (_guitarInputOpen && exclusiveOk && await _openExclusive(source)) {
      return;
    }
    if (_closed) return;
    if (_guitarInputOpen) {
      await _openSpeaker(throughIrig: source == EarSource.irig);
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
    _report(name: inputName, devices: devices);
  }

  void _report({
    required String name,
    required List<InputDevice> devices,
    bool exclusive = false,
  }) {
    onReady?.call(
      HeardInput(
        name: name,
        isGuitar: _guitarInputOpen,
        speakerReady: _monitorReady,
        inputs: [for (final item in devices) item.label],
        active: _openSource,
        cablePresent: _cablePresent,
        irigPresent: _irigPresent,
        micPresent: _micPresent,
        irigSpeaker: _guitarInputOpen ? null : _irigSpeakerName(),
        exclusive: exclusive,
        latencyMs: _latencyMs,
      ),
    );
  }

  /// A guitar that was just plugged in takes the seat from the room mic.
  /// Unplugging a source clears a switch-off, so the next plug-in can
  /// turn that source back on.
  void _notePresence(List<InputDevice> devices) {
    final cableNow = devices.any((device) => isRocksmithCable(device.label));
    final irigNow = devices.any((device) => isIrigInput(device.label));
    if (cableNow && !_sawCable && _preferred == EarSource.mic) {
      _preferred = EarSource.cable;
      _suppressed
        ..clear()
        ..addAll([EarSource.irig, EarSource.mic]);
    } else if (irigNow &&
        !_sawIrig &&
        !cableNow &&
        _preferred == EarSource.mic) {
      _preferred = EarSource.irig;
      _suppressed
        ..clear()
        ..addAll([EarSource.cable, EarSource.mic]);
    }
    if (!cableNow) {
      _suppressed.remove(EarSource.cable);
      if (_preferred == EarSource.cable) _preferred = null;
    }
    if (!irigNow) {
      _suppressed.remove(EarSource.irig);
      if (_preferred == EarSource.irig) _preferred = null;
    }
    _sawCable = cableNow;
    _sawIrig = irigNow;
    _cablePresent = cableNow;
    _irigPresent = irigNow;
    _micPresent = devices.any((device) => isRoomMic(device.label));
  }

  /// Subscribes first so the first buffers are not thrown away, then asks
  /// Windows for the cable. A null result means exclusive was refused and
  /// the shared recorder should open instead.
  Future<bool> _openExclusive(EarSource source) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    _exclusivePcm = ExclusiveGuitar.pcm.listen(_onBytes, onError: (_) {});
    final opened = await ExclusiveGuitar.start();
    if (_closed || opened == null || opened.sampleRate <= 0) {
      await _exclusivePcm?.cancel();
      _exclusivePcm = null;
      await ExclusiveGuitar.stop();
      return false;
    }
    final wantedCable = source == EarSource.cable;
    final gotCable = isRocksmithCable(opened.name);
    if (wantedCable != gotCable) {
      await _exclusivePcm?.cancel();
      _exclusivePcm = null;
      await ExclusiveGuitar.stop();
      return false;
    }
    _exclusive = true;
    _sampleRate = opened.sampleRate;
    _listenAfresh();
    _latencyMs = opened.renderExclusive ? 20 : 35;
    _monitorReady = true;
    _started = true;
    unawaited(ExclusiveGuitar.setVolume(_volume));
    _report(name: opened.name, devices: const [], exclusive: true);
    return true;
  }

  Future<void> stop() async {
    await _exclusivePcm?.cancel();
    _exclusivePcm = null;
    if (_exclusive) {
      _exclusive = false;
      await ExclusiveGuitar.stop();
    }
    final recording = _subscription != null;
    await _subscription?.cancel();
    _subscription = null;
    if (recording) await _recorder.cancel();
    _started = false;
  }

  Future<void> dispose() async {
    _closed = true;
    await stop();
    _closeSpeaker();
    await _recorder.dispose();
  }

  /// Shuts the shared speaker engine. Its sounds go with it.
  void _closeSpeaker() {
    _monitorReady = false;
    _monitor = null;
    _monitorHandle = null;
    _click = null;
    _accentClick = null;
    if (SoLoud.instance.isInitialized) {
      SoLoud.instance.deinit();
    }
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
        volume: _speakerOn ? _volume : 0,
      );
      _click = await _loadClick(hertz: 1046.5);
      _accentClick = await _loadClick(hertz: 1568);
      _monitorReady = true;
    } catch (_) {
      _closeSpeaker();
    }
  }

  Future<AudioSource> _loadClick({required double hertz}) {
    final click = clickPcm(sampleRate: _sampleRate, hertz: hertz);
    return SoLoud.instance.loadMem(
      'click-$hertz.wav',
      wavBytes(click, sampleRate: _sampleRate),
    );
  }

  void _onBytes(Uint8List bytes) {
    if (_closed) return;
    _silence.heard();
    final nowMicros = _watch.elapsedMicroseconds;
    _play(bytes);
    onSound?.call(bytes);

    final data = ByteData.sublistView(bytes);
    final samples = Float64List(bytes.length ~/ 2);
    var sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final sample = data.getInt16(i * 2, Endian.little) / 32768;
      samples[i] = sample;
      sum += sample * sample;
    }
    if (samples.isEmpty) return;
    onLevel?.call(math.sqrt(sum / samples.length));

    final plucks = _detector.hear(samples);
    _clock.arrived(samplesHeard: _detector.samplesHeard, atMicros: nowMicros);
    for (final pluck in plucks) {
      final agoMicros = nowMicros - _clock.microsAt(pluck.atSample);
      onPluck?.call(pluck.midi, agoMicros / 1000);
    }
    onTone?.call(_detector.ringingHertz);
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
  final source = listeningChoice(
    cable: devices.any((device) => isRocksmithCable(device.label)),
    irig: devices.any((device) => isIrigInput(device.label)),
    mic: false,
    suppressed: const {EarSource.mic},
    preferred: null,
  );
  if (source == null) return null;
  return deviceFor(devices, source);
}

/// The recording device for one switch.
InputDevice? deviceFor(List<InputDevice> devices, EarSource source) {
  for (final device in devices) {
    final matches = switch (source) {
      EarSource.cable => isRocksmithCable(device.label),
      EarSource.irig => isIrigInput(device.label),
      EarSource.mic => isRoomMic(device.label),
    };
    if (matches) return device;
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

/// The iRig's recording side. Its speaker jack is a different device.
bool isIrigInput(String label) {
  return !isRocksmithCable(label) && label.toLowerCase().contains('irig');
}

/// A laptop or room microphone. The guitar cables are not this.
bool isRoomMic(String label) {
  return !isRocksmithCable(label) && !isIrigInput(label);
}

int _sampleRateFor(InputDevice? device) {
  final rates = device?.sampleRates ?? const <int>[];
  if (rates.contains(48000)) return 48000;
  if (rates.contains(44100)) return 44100;
  if (rates.isNotEmpty) return rates.first;
  return 44100;
}
