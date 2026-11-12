import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/audio/pitch.dart';
import 'package:riffster/audio/sample_clock.dart';

const _rate = 12000.0;

Float64List _tone(double hertz, int length, {double octave = 0}) {
  return Float64List.fromList([
    for (var i = 0; i < length; i++)
      math.sin(2 * math.pi * hertz * i / _rate) +
          octave * math.sin(4 * math.pi * hertz * i / _rate),
  ]);
}

int? _midiIn(Float64List samples) {
  final period = periodIn(
    samples,
    start: 0,
    length: samples.length,
    shortest: 20,
    longest: 340,
  );
  return period == null ? null : midiOfPeriod(period, _rate);
}

void main() {
  test('a concert A is MIDI 69, and a quiet window is nothing', () {
    expect(_midiIn(_tone(440, 1024)), 69);
    expect(_midiIn(Float64List(1024)), isNull);
    expect(pitchName(69), 'A4');
  });

  test('the root is heard, even under a louder octave overtone', () {
    expect(_midiIn(_tone(41.2, 1024, octave: 1.5)), 28);
    expect(pitchName(28), 'E1');
  });

  test('a window too short to see a low note repeat gives no answer', () {
    // One cycle of a low E is 291 samples here. It has to be seen twice.
    expect(_midiIn(_tone(41.2, 400)), isNull);
    expect(_midiIn(_tone(41.2, 620)), 28);
  });

  test('the cycle length is found between two samples', () {
    final period = periodIn(
      _tone(98, 1024),
      start: 0,
      length: 1024,
      shortest: 20,
      longest: 340,
    );
    expect(period, closeTo(_rate / 98, 0.05));
  });

  test('late chunks do not move the time a sample was heard', () {
    final clock = SampleClock(48000);
    final random = math.Random(3);
    // A chunk every 5 ms. Most are held up, some by 15 ms. Now and
    // then one gets straight through.
    for (var chunk = 1; chunk <= 400; chunk++) {
      final late = chunk % 20 == 0 ? 0 : random.nextInt(15000);
      clock.arrived(
        samplesHeard: chunk * 240,
        atMicros: 1000000 + chunk * 5000 + late,
      );
    }

    // Sample 48,000 is exactly one second in.
    expect(clock.microsAt(48000), closeTo(2000000, 1));
  });

  test('a sound card that runs slow is followed', () {
    final clock = SampleClock(48000);
    // The card is slow by one part in a thousand, far worse than a
    // real one, so each chunk takes 5.005 ms.
    for (var chunk = 1; chunk <= 4000; chunk++) {
      clock.arrived(samplesHeard: chunk * 240, atMicros: chunk * 5005);
    }

    final newest = 4000 * 240;
    expect(clock.microsAt(newest), closeTo(4000 * 5005, 4500));
  });
}
