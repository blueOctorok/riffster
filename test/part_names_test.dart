import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/import/imported_score.dart';
import 'package:riffster/models/tab_note.dart';
import 'package:riffster/music/part_names.dart';

TabNote _note({required int timeMs, required int midi, int string = 1}) {
  return TabNote(
    timeMs: timeMs,
    string: string,
    fret: 1,
    durationMs: 200,
    midi: midi,
  );
}

ImportedTrack _track(String name, List<TabNote> notes) {
  return ImportedTrack(name: name, notes: notes);
}

void main() {
  test('a real part name is kept, and Track 1 is described from the notes', () {
    final named = namePlayableParts([
      _track('Solo', [_note(timeMs: 0, midi: 60)]),
      _track('Track 1', [
        _note(timeMs: 0, midi: 64),
        _note(timeMs: 400, midi: 67),
      ]),
      _track('Track 2', [
        _note(timeMs: 0, midi: 60, string: 1),
        _note(timeMs: 0, midi: 64, string: 2),
        _note(timeMs: 0, midi: 67, string: 3),
      ]),
      _track('Track 3', [
        _note(timeMs: 0, midi: 60, string: 2),
        _note(timeMs: 0, midi: 64, string: 1),
      ]),
      _track('Track 4', [
        _note(timeMs: 0, midi: 64),
        _note(timeMs: 200, midi: 67),
      ]),
      _track('Track 5', [
        _note(timeMs: 0, midi: 67),
        _note(timeMs: 200, midi: 71),
      ]),
    ]);

    expect(named.map((track) => track.name), [
      'Solo',
      'Single notes',
      'Chords',
      'Two notes',
      'Harmony 1',
      'Harmony 2',
    ]);
  });

  test('an unnamed copy of an earlier part is left out', () {
    final notes = [_note(timeMs: 0, midi: 60), _note(timeMs: 200, midi: 64)];
    final named = namePlayableParts([
      _track('Track 1', notes),
      _track('Track 2', notes),
    ]);

    expect(named, hasLength(1));
    expect(named.single.name, 'Single notes');
  });
}
