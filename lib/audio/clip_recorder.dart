import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'wav.dart';

/// Saves what the cable heard to a file, next to the notes that were
/// meant to be played. A tool for building the app, not part of it.
///
/// The detector is tuned against these clips. Each one is a real
/// instrument with a written answer, so "did that change make it
/// hear better" is a number from a test and not a feeling.
class ClipRecorder {
  ClipRecorder._();

  /// Clips are saved into the project's test folder, so there is only
  /// a recorder in a debug build that was started from the project.
  static ClipRecorder? forThisBuild() {
    if (!kDebugMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    return File('pubspec.yaml').existsSync() ? ClipRecorder._() : null;
  }

  static const folder = 'test/clips';

  BytesBuilder? _sound;

  /// When this take started. The bar counts up from it, so a restart of
  /// the song cannot be mistaken for the recording having stopped.
  DateTime? _started;

  bool get recording => _sound != null;

  DateTime? get started => _started;

  void start() {
    _sound = BytesBuilder(copy: false);
    _started = DateTime.now();
  }

  /// The next chunk of raw 16-bit sound. Dropped unless recording.
  void add(Uint8List bytes) => _sound?.add(bytes);

  /// Stops and writes `name.wav` and `name.txt`. [notes] is the answer:
  /// the note names in the order they were meant to be played.
  Future<String> save({
    required String name,
    required int sampleRate,
    required List<String> notes,
  }) async {
    final sound = _sound!.takeBytes();
    _sound = null;
    _started = null;
    await Directory(folder).create(recursive: true);
    await File('$folder/$name.wav').writeAsBytes(
      wavBytes(sound, sampleRate: sampleRate),
    );
    await File('$folder/$name.txt').writeAsString(
      '# The notes played, in order. Fix this line if you played '
      'something else.\n${notes.join(' ')}\n',
    );
    return '$folder/$name.wav';
  }
}
