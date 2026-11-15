import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/fretting_finger.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/music/drill_line.dart';
import 'package:riffster/music/place_on_neck.dart';
import 'package:riffster/music/scale_line.dart';

void main() {
  test('a finger warm-up is 1-2-3-4 on one string, then the next', () {
    final song = practiceDrill(
      instrument: Instrument.bass,
      pitchClass: pitchNames.indexOf('E'),
      kind: DrillKind.fingerWarmup,
    );

    expect(song.title, 'E finger warm-up');
    expect(song.bars, hasLength(4));
    // Four bars of eighths.
    expect(song.notes, hasLength(32));

    final first = song.notes.take(4).toList();
    expect(first.map((note) => note.string), everyElement(4));
    expect(first.map((note) => note.fret), [0, 1, 2, 3]);
    expect(first.map((note) => note.finger), [
      null,
      FrettingFinger.indexFinger,
      FrettingFinger.middle,
      FrettingFinger.ring,
    ]);

    // The way back down keeps the fingers of the shape it climbed.
    expect(song.notes[16].fret, 2);
    expect(song.notes[16].finger, FrettingFinger.middle);
  });

  test('a harder warm-up moves to the next position', () {
    final song = practiceDrill(
      instrument: Instrument.bass,
      pitchClass: pitchNames.indexOf('E'),
      kind: DrillKind.fingerWarmup,
      level: DrillLevel.hard,
      bars: DrillBars.eight,
    );

    // The first shape is 31 notes. The next one starts four frets up.
    expect(song.notes[31].string, 4);
    expect(song.notes[31].fret, 4);
    expect(song.notes[31].finger, FrettingFinger.indexFinger);
  });

  test('string crossing stays on one fret and changes string', () {
    final song = practiceDrill(
      instrument: Instrument.bass,
      pitchClass: pitchNames.indexOf('A'),
      kind: DrillKind.stringCrossing,
    );

    // A is five frets above the low E, on both of the low strings.
    expect(song.notes.first.fret, 5);
    expect(song.notes[0].string, 4);
    expect(song.notes[1].string, 3);
    expect(song.notes[1].fret, song.notes[0].fret);
    expect(song.title, 'A string crossing');
  });

  test('octave jumps and root and fifth are those intervals', () {
    final octaves = practiceDrill(
      instrument: Instrument.bass,
      pitchClass: pitchNames.indexOf('E'),
      kind: DrillKind.octaveJumps,
    );
    final fifths = practiceDrill(
      instrument: Instrument.bass,
      pitchClass: pitchNames.indexOf('E'),
      kind: DrillKind.rootAndFifth,
    );

    for (var i = 1; i < octaves.notes.length; i++) {
      expect((octaves.notes[i].midi - octaves.notes[i - 1].midi).abs(), 12);
    }
    for (var i = 1; i < fifths.notes.length; i++) {
      expect((fifths.notes[i].midi - fifths.notes[i - 1].midi).abs(), 7);
    }
  });

  test('a rhythm drill rests, and the next note stays on the grid', () {
    final song = practiceDrill(
      instrument: Instrument.bass,
      pitchClass: pitchNames.indexOf('E'),
      kind: DrillKind.oneNoteRhythm,
      level: DrillLevel.medium,
      value: NoteValue.quarter,
      bars: DrillBars.two,
    );

    // On, off, on, off, across eight quarter slots. The note is the open E.
    expect(song.notes, hasLength(4));
    expect(song.notes.map((note) => note.midi), everyElement(28));
    // A quarter at 80 bpm is 750 ms, and one slot is a rest.
    expect(song.notes[1].timeMs - song.notes[0].timeMs, 1500);
    expect(song.bars, hasLength(2));
  });

  test('a scale walk stays in the box and repeats for the same knobs', () {
    line(DrillBars bars) => practiceDrill(
      instrument: Instrument.guitar,
      pitchClass: pitchNames.indexOf('C'),
      kind: DrillKind.scaleWalk,
      bars: bars,
      value: NoteValue.quarter,
    );

    final short = line(DrillBars.two);
    final longer = line(DrillBars.four);
    final again = line(DrillBars.four);

    expect(short.notes.first.midi, lowestRoot(Instrument.guitar, 0));
    expect(
      short.notes.map((note) => note.midi),
      longer.notes.take(short.notes.length).map((note) => note.midi),
    );
    expect(
      again.notes.map((note) => note.midi),
      longer.notes.map((note) => note.midi),
    );
    for (var i = 1; i < longer.notes.length; i++) {
      expect(
        (longer.notes[i].midi - longer.notes[i - 1].midi).abs(),
        lessThanOrEqualTo(2),
      );
    }
  });

  test('every drill sits on the neck, on both instruments', () {
    for (final instrument in Instrument.values) {
      for (final kind in DrillKind.values) {
        for (final level in DrillLevel.values) {
          for (final root in ['E', 'C', 'B']) {
            final song = practiceDrill(
              instrument: instrument,
              pitchClass: pitchNames.indexOf(root),
              kind: kind,
              level: level,
              bars: DrillBars.two,
            );
            expect(song.bars, hasLength(2), reason: '$kind $level $root');
            expect(song.notes, isNotEmpty);
            for (final note in song.notes) {
              expect(note.string, inInclusiveRange(1, instrument.stringCount));
              expect(note.fret, inInclusiveRange(0, topPlacedFret));
              expect(
                note.midi,
                instrument.openStringMidi[note.string - 1] + note.fret,
              );
            }
          }
        }
      }
    }
  });
}
