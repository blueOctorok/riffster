import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:riffster/audio/pluck_detector.dart';
import 'package:riffster/models/instrument.dart';

/// The samples in a 16-bit mono WAV file, each from -1 to 1.
({int sampleRate, Float64List samples}) readWav(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  final sampleRate = data.getUint32(24, Endian.little);
  // The sound follows a 'data' tag and a four-byte length. Other
  // blocks may sit before it, so each one is stepped over.
  var at = 12;
  while (String.fromCharCodes(bytes, at, at + 4) != 'data') {
    at += 8 + data.getUint32(at + 4, Endian.little);
  }
  final length = data.getUint32(at + 4, Endian.little) ~/ 2;
  final samples = Float64List(length);
  for (var i = 0; i < length; i++) {
    samples[i] = data.getInt16(at + 8 + i * 2, Endian.little) / 32768;
  }
  return (sampleRate: sampleRate, samples: samples);
}

/// 'E1' is 28 and 'A#2' is 46. A '?' is null: any sound will do.
int? midiOfName(String name) {
  if (name == '?') return null;
  const letters = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final sharp = name.contains('#') ? 1 : 0;
  final octave = int.parse(name.substring(1 + sharp));
  return letters[name[0]]! + sharp + (octave + 1) * 12;
}

/// What the detector hears in [samples], fed in the small pieces the
/// cable sends. A strum is reported twice, first with no pitch and
/// then with one. The second replaces the first.
List<int?> heardNotes(
  Float64List samples, {
  required int sampleRate,
  required Instrument instrument,
}) {
  final detector = PluckDetector(sampleRate: sampleRate, instrument: instrument);
  final plucks = <Pluck>[];
  const chunk = 256;
  for (var from = 0; from < samples.length; from += chunk) {
    final piece = samples.sublist(from, math.min(from + chunk, samples.length));
    for (final pluck in detector.hear(piece)) {
      if (plucks.isNotEmpty && plucks.last.atSample == pluck.atSample) {
        plucks.removeLast();
      }
      plucks.add(pluck);
    }
  }
  return [for (final pluck in plucks) pluck.midi];
}

/// How far what was [heard] is from what was [played].
///
/// The two lists are lined up by the longest run of notes they share
/// in the same order. What is left over in [played] was missed, and
/// what is left over in [heard] was never played.
({int missing, int extra}) clipScore({
  required List<int?> played,
  required List<int?> heard,
}) {
  // shared[i][j] is the longest shared run of the first i played
  // notes and the first j heard ones. Each cell is built from the
  // three cells before it, so nothing is worked out twice.
  final shared = [
    for (var i = 0; i <= played.length; i++) List.filled(heard.length + 1, 0),
  ];
  for (var i = 1; i <= played.length; i++) {
    for (var j = 1; j <= heard.length; j++) {
      final same = played[i - 1] == null || played[i - 1] == heard[j - 1];
      shared[i][j] = same
          ? shared[i - 1][j - 1] + 1
          : math.max(shared[i - 1][j], shared[i][j - 1]);
    }
  }
  final matched = shared[played.length][heard.length];
  return (missing: played.length - matched, extra: heard.length - matched);
}
