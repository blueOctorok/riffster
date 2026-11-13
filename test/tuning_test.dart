import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/audio/pitch.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/music/tuning.dart';
import 'package:riffster/theme/riffster_theme.dart';
import 'package:riffster/widgets/shell/tuner.dart';

/// The name of the open string [hertz] is measured against.
String _string(double hertz, Instrument instrument) {
  return instrument.stringNames[nearestString(hertz, instrument).string];
}

void main() {
  test('a pitch can sit between two notes', () {
    expect(midiOfHertz(440), 69);
    expect(midiOfHertz(880), 81);
    // Halfway from A4 to A#4, counted in semitones.
    expect(midiOfHertz(hertzOfMidi(69.5)), closeTo(69.5, 1e-9));
  });

  test('every open string in tune reads as itself, dead on', () {
    for (final instrument in Instrument.values) {
      final open = instrument.openStringMidi;
      for (var string = 0; string < open.length; string++) {
        final reading = nearestString(hertzOfMidi(open[string]), instrument);
        expect(reading.string, string);
        expect(reading.cents, closeTo(0, 1e-6));
      }
    }
  });

  test('a D string 57 cents flat is a flat D, not a sharp C sharp', () {
    // Measured on a real bass: the open D rang at 71.04 Hz, where a D
    // in tune is 73.42. The nearest note name is C sharp.
    expect(pitchName(midiOfHertz(71.04).round()), 'C#2');

    final reading = nearestString(71.04, Instrument.bass);
    expect(_string(71.04, Instrument.bass), 'D');
    expect(reading.cents, closeTo(-57, 0.5));
  });

  test('a pitch outside the strings is measured against the end one', () {
    expect(_string(30, Instrument.bass), 'E');
    expect(nearestString(30, Instrument.bass).cents, lessThan(-100));
    expect(_string(150, Instrument.bass), 'G');
    expect(nearestString(150, Instrument.bass).cents, greaterThan(100));
  });

  testWidgets('the tuner names the string and says which way to turn', (
    tester,
  ) async {
    final tone = ValueNotifier<double?>(null);
    addTearDown(tone.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: riffsterTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: Tuner(tone: tone, instrument: Instrument.bass),
          ),
        ),
      ),
    );

    String shown(String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

    expect(shown('tuner-words'), 'Play an open string');

    tone.value = 71.04;
    await tester.pumpAndSettle();
    expect(shown('tuner-string'), 'D');
    expect(shown('tuner-words'), '57 cents flat');

    tone.value = hertzOfMidi(38) * 1.002;
    await tester.pumpAndSettle();
    expect(shown('tuner-string'), 'D');
    expect(shown('tuner-words'), 'In tune');

    tone.value = hertzOfMidi(33.2);
    await tester.pumpAndSettle();
    expect(shown('tuner-string'), 'A');
    expect(shown('tuner-words'), '20 cents sharp');

    // The listener drops a ringing note for a moment whenever it
    // checks it. The reading stays up through a gap that short.
    tone.value = null;
    await tester.pump(const Duration(milliseconds: 300));
    expect(shown('tuner-words'), '20 cents sharp');

    // Real silence puts the needle to rest.
    await tester.pump(const Duration(milliseconds: 400));
    expect(shown('tuner-words'), 'Play an open string');
  });
}
