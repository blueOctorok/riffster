import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/import/imported_score.dart';
import 'package:riffster/import/part_choices.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';

import 'support/sample_score.dart';

ImportedTrack _track(String name, List<int> tuning) {
  return ImportedTrack(
    name: name,
    tuning: tuning,
    notes: const [
      TabNote(timeMs: 0, string: 1, fret: 0, durationMs: 500, midi: 43),
    ],
  );
}

Map<String, PartUse> _uses(Instrument playing) {
  return {
    for (final choice in partChoicesFor(playing, sampleScore().tracks))
      choice.track.name: choice.use,
  };
}

String _detail(Instrument playing, ImportedTrack track) {
  return partChoicesFor(playing, [track]).single.detail;
}

void main() {
  test('a part is the instrument its strings say it is', () {
    expect(_track('Bass', [43, 38, 33, 28]).instrument, Instrument.bass);
    expect(_track('Drop D bass', [43, 38, 33, 26]).instrument, Instrument.bass);
    expect(
      _track('Guitar', [64, 59, 55, 50, 45, 40]).instrument,
      Instrument.guitar,
    );
    expect(
      _track('Drop D', [64, 59, 55, 50, 45, 38]).instrument,
      Instrument.guitar,
    );
    // Four strings, and far too high to be a bass.
    expect(_track('Ukulele', [69, 64, 60, 67]).instrument, isNull);
    expect(_track('Five', [43, 38, 33, 28, 23]).instrument, isNull);
    expect(_track('Seven', [64, 59, 55, 50, 45, 40, 35]).instrument, isNull);
    expect(_track('Voice', []).instrument, isNull);
  });

  test('on bass: its own part as written, a melody from any other', () {
    expect(_uses(Instrument.bass), {
      'Bass': PartUse.written,
      'Lead guitar': PartUse.melody,
      'Rhythm guitar': PartUse.melody,
      'Vocals': PartUse.melody,
      'Low bass': PartUse.unavailable,
    });
  });

  test('on guitar: the guitar parts as written, and nothing else', () {
    expect(_uses(Instrument.guitar), {
      'Bass': PartUse.unavailable,
      'Lead guitar': PartUse.written,
      'Rhythm guitar': PartUse.written,
      'Vocals': PartUse.unavailable,
      'Low bass': PartUse.unavailable,
    });
  });

  test('a part that cannot be played says why', () {
    final fiveString = _track('Five', [43, 38, 33, 28, 23]);
    final sevenString = _track('Seven', [64, 59, 55, 50, 45, 40, 35]);
    final bass = _track('Bass', [43, 38, 33, 28]);

    expect(
      _detail(Instrument.bass, fiveString),
      '5 strings · not supported yet',
    );
    expect(
      _detail(Instrument.guitar, sevenString),
      '7 strings · not supported yet',
    );
    expect(
      _detail(Instrument.guitar, bass),
      'A bass part · switch to Bass to play it',
    );
    expect(
      _detail(Instrument.guitar, _track('Voice', [])),
      'Not a guitar part',
    );
  });

  test('a part in another tuning says which', () {
    expect(
      _detail(Instrument.bass, _track('Bass', [43, 38, 33, 28])),
      '1 note',
    );
    expect(
      _detail(Instrument.bass, _track('Bass', [43, 38, 33, 26])),
      '1 note · tuned D1 A1 D2 G2',
    );
  });
}
