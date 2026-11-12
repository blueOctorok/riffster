import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/models/instrument.dart';
import 'package:riffster/music/chord_book.dart';
import 'package:riffster/music/chord_catalog.dart';
import 'package:riffster/music/chord_lane.dart';

void main() {
  test('every card sounds the chord its name claims', () {
    expect(chordBlocks, isNotEmpty);
    for (final block in chordBlocks) {
      final root = _root(block.grip.name);
      final formula = _formula(block.grip.name);
      final sounded = _relative(_classes(block.grip), root);
      expect(
        formula.$1.difference(sounded),
        isEmpty,
        reason: '${block.label} is missing a tone: $sounded',
      );
      expect(
        sounded.difference(formula.$2),
        isEmpty,
        reason: '${block.label} has a tone that chord does not: $sounded',
      );
    }
  });

  test('a group opens on one screen of cards, not the whole book', () {
    expect(blocksIn(ChordGroup.open, ''), hasLength(9));
    expect(blocksIn(ChordGroup.barre, ''), hasLength(12));
    expect(blocksIn(ChordGroup.barre, 'E major').first.label, 'F');
    expect(blocksIn(ChordGroup.barre, 'A major').first.label, 'Bb');
    expect(
      blocksIn(ChordGroup.barre, 'E minor').map((block) => block.label),
      contains('Bm E-shape'),
    );
    expect(blocksIn(ChordGroup.seventh, '7'), hasLength(7));
    expect(blocksIn(ChordGroup.seventh, 'm7'), hasLength(3));
    expect(blocksIn(ChordGroup.sus, ''), hasLength(7));
    expect(blocksIn(ChordGroup.power, 'Low E'), hasLength(12));
    expect(blocksIn(ChordGroup.power, 'A string'), hasLength(12));
    expect(blocksIn(ChordGroup.more, ''), hasLength(8));
    expect(
      chordBlocks.map((block) => block.label).toSet(),
      hasLength(chordBlocks.length),
    );
  });

  test('an imported open G is still named G', () {
    final notes = notesForGrip(openG, 0, 1000);
    expect(matchingGrip(notes)?.name, 'G');
  });
}

Set<int> _classes(ChordGrip grip) {
  return {
    for (var string = 1; string <= 6; string++)
      if (grip.frets[string - 1] != null)
        (Instrument.guitar.openStringMidi[string - 1] +
                grip.frets[string - 1]!) %
            12,
  };
}

Set<int> _relative(Set<int> sounded, int root) {
  return {for (final pitch in sounded) (pitch - root + 12) % 12};
}

int _root(String name) {
  final bare = name
      .replaceAll('add9', '')
      .replaceAll('maj7', '')
      .replaceAll('m7', '')
      .replaceAll('sus2', '')
      .replaceAll('sus4', '')
      .replaceAll('dim', '')
      .replaceAll('aug', '')
      .replaceAll('7', '')
      .replaceAll('m', '')
      .replaceAll('5', '');
  final root = chordPitchNames.indexOf(bare);
  expect(root, isNonNegative, reason: 'no root in $name');
  return root;
}

/// Tones the chord must sound, then every tone it is allowed to sound.
(Set<int>, Set<int>) _formula(String name) {
  if (name.endsWith('add9')) return ({0, 2, 4}, {0, 2, 4, 7});
  if (name.endsWith('maj7')) return ({0, 4, 11}, {0, 4, 7, 11});
  if (name.endsWith('m7')) return ({0, 3, 10}, {0, 3, 7, 10});
  if (name.endsWith('sus2')) return ({0, 2, 7}, {0, 2, 7});
  if (name.endsWith('sus4')) return ({0, 5, 7}, {0, 5, 7});
  if (name.endsWith('dim')) return ({0, 3, 6}, {0, 3, 6});
  if (name.endsWith('aug')) return ({0, 4, 8}, {0, 4, 8});
  if (name.endsWith('7')) return ({0, 4, 10}, {0, 4, 7, 10});
  if (name.endsWith('m')) return ({0, 3, 7}, {0, 3, 7});
  if (name.endsWith('5')) return ({0, 7}, {0, 7});
  return ({0, 4, 7}, {0, 4, 7});
}
