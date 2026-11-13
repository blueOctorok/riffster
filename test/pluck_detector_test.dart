import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/audio/pitch.dart';
import 'package:riffster/audio/pluck_detector.dart';
import 'package:riffster/models/instrument.dart';

const _rate = 48000;

int _samples(double seconds) => (seconds * _rate).round();

List<double> _silence(double seconds) => List.filled(_samples(seconds), 0);

/// A plucked string, made the Karplus-Strong way: a burst of noise
/// goes round a loop one cycle long and is smoothed a little on every
/// trip. It starts bright and mellows, the way a real string does.
List<double> _string(int midi, double seconds, {double level = 0.4}) {
  final cycle = (_rate / hertzOfMidi(midi)).round();
  final random = math.Random(midi);
  var loop = [for (var i = 0; i < cycle; i++) random.nextDouble() * 2 - 1];
  // A finger is softer than raw noise. Smooth the burst first.
  for (var pass = 0; pass < 3; pass++) {
    loop = [
      for (var i = 0; i < cycle; i++)
        (loop[i] + loop[(i + 1) % cycle] + loop[(i + 2) % cycle]) / 3,
    ];
  }
  final peak = loop.map((sample) => sample.abs()).reduce(math.max);
  final out = <double>[];
  for (var n = 0; n < _samples(seconds); n++) {
    final at = n % cycle;
    out.add(loop[at] / peak * level);
    loop[at] = 0.998 * (loop[at] + loop[(at + 1) % cycle]) / 2;
  }
  return out;
}

/// A steady tone that moves from pitch to pitch with no break in the
/// wave, the way a hammer-on does. Each step is `(midi, seconds)`.
List<double> _legato(List<(int, double)> steps, {double octave = 0.5}) {
  final out = <double>[];
  var phase = 0.0;
  for (final (midi, seconds) in steps) {
    final turn = 2 * math.pi * hertzOfMidi(midi) / _rate;
    for (var n = 0; n < _samples(seconds); n++) {
      phase += turn;
      out.add(0.25 * (math.sin(phase) + octave * math.sin(2 * phase)));
    }
  }
  return out;
}

List<Pluck> _hear(
  List<double> sound, {
  Instrument instrument = Instrument.bass,
  int chunk = 256,
}) {
  final detector = PluckDetector(sampleRate: _rate, instrument: instrument);
  final plucks = <Pluck>[];
  for (var from = 0; from < sound.length; from += chunk) {
    plucks.addAll(
      detector.hear(sound.sublist(from, math.min(from + chunk, sound.length))),
    );
  }
  return plucks;
}

double _ms(Pluck pluck) => pluck.atSample * 1000 / _rate;

List<String> _names(List<Pluck> plucks) {
  return [for (final pluck in plucks) pitchName(pluck.midi!)];
}

void main() {
  test('every open bass string and its 12th fret reads the right note', () {
    for (final open in Instrument.bass.openStringMidi) {
      for (final midi in [open, open + 12]) {
        final plucks = _hear([..._silence(0.1), ..._string(midi, 0.5)]);
        expect(_names(plucks), [pitchName(midi)], reason: pitchName(midi));
        expect(_ms(plucks.single), closeTo(100, 5), reason: pitchName(midi));
      }
    }
  });

  test('a low E reads E1 even when its octave is louder than the root', () {
    final sound = _legato([(28, 0.5)], octave: 1.5);
    expect(_names(_hear([..._silence(0.1), ...sound])), ['E1']);
  });

  test('two notes with no gap between them are two plucks', () {
    final plucks = _hear([
      ..._silence(0.1),
      ..._string(33, 0.4),
      ..._string(40, 0.4),
    ]);

    expect(_names(plucks), ['A1', 'E2']);
    expect(_ms(plucks[0]), closeTo(100, 5));
    expect(_ms(plucks[1]), closeTo(500, 5));
  });

  test('the same note plucked again while it rings is a second pluck', () {
    final plucks = _hear([
      ..._silence(0.1),
      ..._string(28, 0.3),
      ..._string(28, 0.3),
      ..._string(28, 0.3),
    ]);

    expect(_names(plucks), ['E1', 'E1', 'E1']);
    expect(_ms(plucks[1]), closeTo(400, 5));
    expect(_ms(plucks[2]), closeTo(700, 5));
  });

  test('a fast line with no gaps is heard note for note', () {
    const line = [28, 31, 33, 35, 33, 31];
    final plucks = _hear([
      ..._silence(0.1),
      for (final midi in line) ..._string(midi, 0.09),
    ]);

    expect(_names(plucks), [for (final midi in line) pitchName(midi)]);
    for (final (index, pluck) in plucks.indexed) {
      expect(_ms(pluck), closeTo(100 + index * 90, 5));
    }
  });

  test('a hammer-on is a new note, with no pluck to hear', () {
    final plucks = _hear([
      ..._silence(0.1),
      ..._legato([(33, 0.4), (35, 0.4), (33, 0.4)]),
    ]);

    expect(_names(plucks), ['A1', 'B1', 'A1']);
    expect(_ms(plucks[1]), closeTo(500, 10));
    expect(_ms(plucks[2]), closeTo(900, 10));
  });

  test('a note left to ring is one pluck, and silence is none', () {
    expect(_hear([..._silence(0.1), ..._string(28, 3)]), hasLength(1));
    expect(_hear([..._silence(0.1), ..._string(43, 3)]), hasLength(1));
    expect(_hear(_silence(1)), isEmpty);
  });

  test('a guitar is heard from its low E to high up the top string', () {
    for (final midi in [40, 64, 76, 83]) {
      final plucks = _hear([
        ..._silence(0.1),
        ..._string(midi, 0.4),
      ], instrument: Instrument.guitar);
      expect(_names(plucks), [pitchName(midi)], reason: pitchName(midi));
      expect(_ms(plucks.single), closeTo(100, 5), reason: pitchName(midi));
    }
  });

  test('a strummed chord is reported once, at the strum', () {
    final strings = [_string(40, 0.5), _string(47, 0.5), _string(52, 0.5)];
    final chord = [
      for (var n = 0; n < strings.first.length; n++)
        (strings[0][n] + strings[1][n] + strings[2][n]) / 3,
    ];
    final plucks = _hear([
      ..._silence(0.1),
      ...chord,
    ], instrument: Instrument.guitar);

    expect(plucks, isNotEmpty);
    expect(plucks.map((pluck) => pluck.atSample).toSet(), hasLength(1));
    expect(_ms(plucks.first), closeTo(100, 5));
  });

  test('the answer does not depend on how the sound is cut up', () {
    final sound = [..._silence(0.1), ..._string(33, 0.4), ..._string(40, 0.4)];
    final small = _hear(sound, chunk: 64);
    final large = _hear(sound, chunk: 4800);

    expect(small.map((pluck) => '$pluck'), large.map((pluck) => '$pluck'));
  });

  test('the ringing pitch is known far finer than its note name', () {
    final detector = PluckDetector(
      sampleRate: _rate,
      instrument: Instrument.bass,
    );
    expect(detector.ringingHertz, isNull);

    // An open D that has slipped 30 cents flat. Its name is still D2.
    final flatD = hertzOfMidi(38 - 0.3);
    final turn = 2 * math.pi * flatD / _rate;
    detector.hear(_silence(0.1));
    final plucks = detector.hear([
      for (var n = 0; n < _samples(0.5); n++)
        0.25 * (math.sin(turn * n) + 0.5 * math.sin(2 * turn * n)),
    ]);

    expect(_names(plucks), ['D2']);
    // A fifth of a hertz down here is about five cents.
    expect(detector.ringingHertz, closeTo(flatD, 0.2));

    detector.hear(_silence(0.5));
    expect(detector.ringingHertz, isNull);
  });
}
