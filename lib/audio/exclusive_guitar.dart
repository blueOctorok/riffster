import 'dart:io';

import 'package:flutter/services.dart';

/// A guitar cable opened so Windows is not mixing it for other apps.
class ExclusiveOpen {
  const ExclusiveOpen({
    required this.name,
    required this.sampleRate,
    required this.renderExclusive,
  });

  final String name;
  final int sampleRate;

  /// True when the speakers were taken over too. False when playback had to
  /// stay in the shared mixer.
  final bool renderExclusive;
}

/// Windows-only. The copy from cable to speaker stays in native code.
class ExclusiveGuitar {
  static const _methods = MethodChannel('riffster/guitar');
  static const _pcm = EventChannel('riffster/guitar_pcm');

  static Stream<Uint8List> get pcm {
    return _pcm.receiveBroadcastStream().map((event) {
      if (event is Uint8List) return event;
      return Uint8List.fromList((event as List).cast<int>());
    });
  }

  static Future<ExclusiveOpen?> start() async {
    if (!Platform.isWindows) return null;
    try {
      final raw = await _methods.invokeMethod<Map<Object?, Object?>>('start');
      if (raw == null || raw['ok'] != true) return null;
      final rate = raw['sampleRate'];
      return ExclusiveOpen(
        name: raw['name'] as String? ?? 'Guitar',
        sampleRate: rate is int ? rate : 48000,
        renderExclusive: raw['renderExclusive'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  /// 0 is silent and 1 is the four-times monitor. Pitch is not changed.
  static Future<void> setVolume(double volume) async {
    if (!Platform.isWindows) return;
    try {
      await _methods.invokeMethod<void>('setVolume', volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  static Future<void> setSpeaker(bool on) async {
    if (!Platform.isWindows) return;
    try {
      await _methods.invokeMethod<void>('setSpeaker', on);
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!Platform.isWindows) return;
    try {
      await _methods.invokeMethod<void>('stop');
    } catch (_) {}
  }
}
