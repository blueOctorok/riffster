import 'dart:math' as math;
import 'dart:typed_data';

/// Wraps raw 16-bit mono samples in a WAV file.
///
/// A WAV is the samples with a 44-byte label on the front that says
/// how to play them: how many a second, how many bits each.
Uint8List wavBytes(Uint8List pcm16, {required int sampleRate}) {
  final header = ByteData(44);
  void tag(int at, String text) {
    for (var i = 0; i < text.length; i++) {
      header.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  header.setUint32(4, 36 + pcm16.length, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  // 1 is plain samples, and then one channel.
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  // Bytes a second, then bytes a sample, then bits a sample.
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  header.setUint32(40, pcm16.length, Endian.little);
  return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm16]);
}

/// The count-in click as 16-bit samples: a short tone that dies away.
///
/// The exclusive cable path makes the same sound in native code. This
/// copy is for the path where Windows still mixes the speakers.
Uint8List clickPcm({required int sampleRate, required double hertz}) {
  const seconds = 0.03;
  const level = 0.35;
  final length = (sampleRate * seconds).round();
  final samples = ByteData(length * 2);
  for (var i = 0; i < length; i++) {
    final fade = 1 - i / length;
    final sample = level * fade * fade * math.sin(2 * math.pi * hertz * i / sampleRate);
    samples.setInt16(i * 2, (sample * 32767).round(), Endian.little);
  }
  return samples.buffer.asUint8List();
}
