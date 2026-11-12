import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/data/demo_song.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/models/tab_song.dart';
import 'package:riffster/music/song_timeline.dart';

TabNote _note(int timeMs, {int string = 1, int midi = 64}) {
  return TabNote(
    timeMs: timeMs,
    string: string,
    fret: 0,
    durationMs: 200,
    midi: midi,
  );
}

void main() {
  test('notes that start together are one moment, in time order', () {
    final timeline = SongTimeline(
      TabSong(
        title: 'Out of order',
        tempoBpm: 120,
        notes: [
          _note(900),
          _note(300, string: 2, midi: 59),
          _note(300),
          _note(0),
        ],
      ),
    );

    expect([for (final moment in timeline.moments) moment.timeMs], [
      0,
      300,
      900,
    ]);
    expect(timeline.moments[1].notes, hasLength(2));
  });

  test('a song rests one bar before its first note', () {
    // 100 bpm is 600 ms a beat, so one bar is 2400 ms.
    final guitar = SongTimeline(warmUpFor(Instrument.guitar));
    expect(guitar.firstNoteMs, 0);
    expect(guitar.restMs, -2400);

    final late = SongTimeline(
      TabSong(title: 'Long intro', tempoBpm: 120, notes: [_note(30000)]),
    );
    expect(late.restMs, 28000);
  });

  test('the nearest moment is found only inside the same beat', () {
    final timeline = SongTimeline(
      TabSong(
        title: 'Three',
        tempoBpm: 120,
        notes: [_note(0), _note(1000), _note(2000)],
      ),
    );

    expect(timeline.momentNear(1100)?.timeMs, 1000);
    expect(timeline.momentNear(760)?.timeMs, 1000);
    expect(timeline.momentNear(600), isNull);
    expect(timeline.momentNear(-200)?.timeMs, 0);
    expect(timeline.momentNear(2251), isNull);
    // At half speed the same real window is half as wide in song time.
    expect(timeline.momentNear(1126, speed: 0.5), isNull);
    expect(timeline.momentNear(1124, speed: 0.5)?.timeMs, 1000);
  });

  test('one grace note does not set the spacing for the whole song', () {
    final timeline = SongTimeline(
      TabSong(
        title: 'Mostly quarters',
        tempoBpm: 100,
        notes: [
          for (var i = 0; i < 30; i++) _note(i * 600),
          _note(630),
        ],
      ),
    );

    // Gaps are one 30, one 570, and twenty-eight 600s.
    expect(timeline.tightGapMs, 570);
  });

  test('the bass warm-up is written for four strings, an octave down', () {
    final bass = warmUpFor(Instrument.bass);

    expect(bass.instrument, Instrument.bass);
    for (final note in bass.notes) {
      expect(note.string, inInclusiveRange(1, 4));
      expect(
        note.midi,
        Instrument.bass.openStringMidi[note.string - 1] + note.fret,
      );
    }
    // Three bars of four beats at 100 bpm.
    expect(bass.bars, hasLength(3));
    expect(bass.bars.last.endMs, 7200);
  });
}
