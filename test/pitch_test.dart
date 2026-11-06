import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/audio/pitch.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/score_note.dart';

List<double> _tone(double frequency, {double overtone = 0}) {
  const rate = 44100;
  return [
    for (var i = 0; i < 4096; i++)
      math.sin(2 * math.pi * frequency * i / rate) +
          overtone * math.sin(2 * math.pi * frequency * 2 * i / rate),
  ];
}

void main() {
  test('a concert A is MIDI 69, and a quiet window is nothing', () {
    expect(midiFromSamples(_tone(440), 44100), 69);
    expect(midiFromSamples(List.filled(4096, 0), 44100), isNull);
  });

  test('the low E is heard, even with a strong octave overtone', () {
    expect(midiFromSamples(_tone(82.41, overtone: 0.6), 44100), 40);
    expect(pitchName(40), 'E2');
  });

  test('the playhead picks the notes of the nearest beat', () {
    final notes = [
      TabNote(timeMs: 0, string: 1, fret: 0, durationMs: 200, midi: 64),
      TabNote(timeMs: 1000, string: 1, fret: 3, durationMs: 200, midi: 67),
      TabNote(timeMs: 1000, string: 2, fret: 0, durationMs: 200, midi: 59),
    ];

    expect(notesNear(notes, 900), hasLength(2));
    expect(notesNear(notes, 2000), isEmpty);
  });
}
