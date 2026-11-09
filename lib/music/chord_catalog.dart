import '../models/fretting_finger.dart';
import 'chord_book.dart';
import 'chord_lane.dart';

const _i = FrettingFinger.indexFinger;
const _m = FrettingFinger.middle;
const _r = FrettingFinger.ring;
const _p = FrettingFinger.pinky;

/// Spellings a chord chart uses. Flats for Bb, Eb, and Ab. Sharps for
/// F#, C#, and G#. The same note is not written two ways in one name.
const chordPitchNames = [
  'C',
  'C#',
  'D',
  'Eb',
  'E',
  'F',
  'F#',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];

/// Every card in the book, in the order a group shows them.
///
/// Movable shapes are built from one fingering slid up the neck. Writing
/// all 12 roots by hand would drift, and a wrong fret would still look
/// like a chord. The pitch test checks each one against the formula.
final List<ChordBlock> chordBlocks = _build();

List<ChordBlock> _build() {
  final used = <String>{};
  final blocks = <ChordBlock>[
    ..._open(used),
    ..._sevenths(used),
    ..._sus(used),
    ..._more(used),
    ..._barres(used),
    ..._power(used),
  ];

  // The importer looks up a stack of notes by grip. The hand-written
  // book stays first, so an open G is still named G when a bigger shape
  // could also claim those frets.
  gripsToMatch = [
    ...chordBook,
    for (final block in blocks)
      if (!chordBook.contains(block.grip)) block.grip,
  ];
  return blocks;
}

/// The chip a group opens on, when the caller has not picked one yet.
String activeSection(ChordGroup group, String section) {
  final sections = sectionsFor(group);
  if (sections.isEmpty) return '';
  if (sections.contains(section)) return section;
  return sections.first;
}

List<String> sectionsFor(ChordGroup group) {
  final seen = <String>[];
  for (final block in chordBlocks) {
    if (block.group != group || block.section.isEmpty) continue;
    if (!seen.contains(block.section)) seen.add(block.section);
  }
  return seen;
}

List<ChordBlock> blocksIn(ChordGroup group, String section) {
  final shown = activeSection(group, section);
  return [
    for (final block in chordBlocks)
      if (block.group == group && block.section == shown) block,
  ];
}

/// Barre chips are two rows: the form, then the quality. The section
/// string is what [blocksIn] filters on.
String barreSection(String shape, String quality) {
  return switch (quality) {
    'Minor' => '$shape minor',
    '7' => '${shape}7',
    'm7' => '${shape}m7',
    'maj7' => '${shape}maj7',
    _ => '$shape major',
  };
}

String barreShape(String section) => section.startsWith('A') ? 'A' : 'E';

String barreQuality(String section) {
  if (section.endsWith('maj7')) return 'maj7';
  if (section.endsWith('m7')) return 'm7';
  if (section.endsWith('7')) return '7';
  if (section.endsWith('minor')) return 'Minor';
  return 'Major';
}

String _take(Set<String> used, String name, [String extra = '']) {
  if (used.add(name)) return name;
  final shaped = extra.isEmpty ? name : '$name $extra';
  used.add(shaped);
  return shaped;
}

ChordBlock _card(
  Set<String> used,
  ChordGroup group,
  String name,
  List<int?> frets,
  List<FrettingFinger?> fingers, {
  String section = '',
  String extra = '',
}) {
  return ChordBlock(
    group: group,
    section: section,
    label: _take(used, name, extra),
    grip: ChordGrip(name: name, frets: frets, fingers: fingers),
  );
}

List<ChordBlock> _open(Set<String> used) {
  // The grips the course already teaches, in the order the grid had.
  // F is not here. The full F is the first E-shape barre.
  return [
    _card(used, ChordGroup.open, 'G', openG.frets, openG.fingers),
    _card(used, ChordGroup.open, 'C', openC.frets, openC.fingers),
    _card(used, ChordGroup.open, 'D', openD.frets, openD.fingers),
    _card(used, ChordGroup.open, 'E', openE.frets, openE.fingers),
    _card(used, ChordGroup.open, 'Em', openEm.frets, openEm.fingers),
    _card(used, ChordGroup.open, 'A', openA.frets, openA.fingers),
    _card(used, ChordGroup.open, 'Am', openAm.frets, openAm.fingers),
    _card(used, ChordGroup.open, 'Dm', openDm.frets, openDm.fingers),
    _card(used, ChordGroup.open, 'Bm', openBm.frets, openBm.fingers),
  ];
}

List<ChordBlock> _sevenths(Set<String> used) {
  ChordBlock card(
    String section,
    String name,
    List<int?> frets,
    List<FrettingFinger?> fingers,
  ) => _card(used, ChordGroup.seventh, name, frets, fingers, section: section);

  return [
    card('7', 'A7', [0, 2, 0, 2, 0, null], [null, _m, null, _i, null, null]),
    card('7', 'B7', [2, 0, 2, 1, 2, null], [_r, null, _m, _i, _p, null]),
    card('7', 'C7', [0, 1, 3, 2, 3, null], [null, _i, _r, _m, _p, null]),
    card('7', 'D7', [2, 1, 2, 0, null, null], [_m, _i, _r, null, null, null]),
    card('7', 'E7', [0, 0, 1, 0, 2, 0], [null, null, _i, null, _m, null]),
    card('7', 'G7', [1, 0, 0, 0, 2, 3], [_i, null, null, null, _m, _r]),
    card('7', 'F#7', fSharp7.frets, fSharp7.fingers),
    card('m7', 'Am7', [0, 1, 0, 2, 0, null], [null, _i, null, _m, null, null]),
    card('m7', 'Dm7', [1, 1, 2, 0, null, null], [_i, _i, _m, null, null, null]),
    card('m7', 'Em7', openEm7.frets, openEm7.fingers),
    card(
      'maj7',
      'Amaj7',
      [0, 2, 1, 2, 0, null],
      [null, _r, _i, _m, null, null],
    ),
    card(
      'maj7',
      'Cmaj7',
      [0, 0, 0, 2, 3, null],
      [null, null, null, _m, _r, null],
    ),
    card(
      'maj7',
      'Dmaj7',
      [2, 2, 2, 0, null, null],
      [_i, _i, _i, null, null, null],
    ),
    card(
      'maj7',
      'Fmaj7',
      [0, 1, 2, 3, null, null],
      [null, _i, _m, _r, null, null],
    ),
    card('maj7', 'Gmaj7', [2, 0, 0, 0, 2, 3], [_m, null, null, null, _i, _r]),
  ];
}

List<ChordBlock> _sus(Set<String> used) {
  ChordBlock card(
    String name,
    List<int?> frets,
    List<FrettingFinger?> fingers,
  ) => _card(used, ChordGroup.sus, name, frets, fingers);

  return [
    card('Asus2', [0, 0, 2, 2, 0, null], [null, null, _m, _i, null, null]),
    card('Dsus2', [0, 3, 2, 2, null, null], [null, _r, _m, _i, null, null]),
    card('Esus2', [0, 0, 4, 4, 2, 0], [null, null, _p, _r, _i, null]),
    card('Asus4', [0, 3, 2, 2, 0, null], [null, _p, _m, _i, null, null]),
    card('Dsus4', [3, 3, 2, 0, null, null], [_p, _r, _i, null, null, null]),
    card('Esus4', [0, 0, 2, 2, 2, 0], [null, null, _r, _m, _i, null]),
    card('Gsus4', [3, 1, 0, 0, 3, 3], [_p, _i, null, null, _r, _r]),
  ];
}

List<ChordBlock> _more(Set<String> used) {
  ChordBlock card(
    String name,
    List<int?> frets,
    List<FrettingFinger?> fingers,
  ) => _card(used, ChordGroup.more, name, frets, fingers);

  return [
    card('Ddim', [1, 3, 1, 0, null, null], [_i, _r, _m, null, null, null]),
    card('Adim', [null, 1, 2, 1, 0, null], [null, _i, _r, _m, null, null]),
    card('Edim', [null, null, 0, 2, 1, 0], [null, null, null, _m, _i, null]),
    card('Caug', [0, 1, 1, 2, 3, null], [null, _i, _i, _m, _r, null]),
    card('Eaug', [0, 1, 1, 2, 3, 0], [null, _i, _i, _m, _r, null]),
    card('Gaug', [3, 0, 0, 1, 2, 3], [_p, null, null, _i, _m, _r]),
    card('Cadd9', [3, 3, 0, 2, 3, null], [_p, _r, null, _i, _m, null]),
    card('Aadd9', [0, 2, 4, 2, 0, null], [null, _m, _r, _i, null, null]),
  ];
}

/// E-shape root sits on the low E. A-shape root sits on the A string.
/// Fret 1 is one fret up from the open chord of that shape, so the
/// first E-shape major is F and the first A-shape major is Bb.
List<ChordBlock> _barres(Set<String> used) {
  final blocks = <ChordBlock>[];
  for (var fret = 1; fret <= 12; fret++) {
    blocks.add(_eBarre(used, fret, 'E major', '', _eMajor));
    blocks.add(_eBarre(used, fret, 'E minor', 'm', _eMinor));
    blocks.add(_eBarre(used, fret, 'E7', '7', _e7));
    blocks.add(_eBarre(used, fret, 'Em7', 'm7', _em7));
    blocks.add(_eBarre(used, fret, 'Emaj7', 'maj7', _emaj7));
    blocks.add(_aBarre(used, fret, 'A major', '', _aMajor));
    blocks.add(_aBarre(used, fret, 'A minor', 'm', _aMinor));
    blocks.add(_aBarre(used, fret, 'A7', '7', _a7));
    blocks.add(_aBarre(used, fret, 'Am7', 'm7', _am7));
    blocks.add(_aBarre(used, fret, 'Amaj7', 'maj7', _amaj7));
  }
  return blocks;
}

ChordBlock _eBarre(
  Set<String> used,
  int fret,
  String section,
  String suffix,
  _Shape shape,
) {
  final name = '${chordPitchNames[(4 + fret) % 12]}$suffix';
  final placed = shape(fret);
  return _card(
    used,
    ChordGroup.barre,
    name,
    placed.$1,
    placed.$2,
    section: section,
    extra: 'E-shape',
  );
}

ChordBlock _aBarre(
  Set<String> used,
  int fret,
  String section,
  String suffix,
  _Shape shape,
) {
  final name = '${chordPitchNames[(9 + fret) % 12]}$suffix';
  final placed = shape(fret);
  return _card(
    used,
    ChordGroup.barre,
    name,
    placed.$1,
    placed.$2,
    section: section,
    extra: 'A-shape',
  );
}

typedef _Shape = (List<int?>, List<FrettingFinger?>) Function(int fret);

_Shape get _eMajor =>
    (fret) => (
      [fret, fret, fret + 1, fret + 2, fret + 2, fret],
      [_i, _i, _m, _p, _r, _i],
    );

_Shape get _eMinor =>
    (fret) => (
      [fret, fret, fret, fret + 2, fret + 2, fret],
      [_i, _i, _i, _p, _r, _i],
    );

_Shape get _e7 =>
    (fret) => (
      [fret, fret, fret + 1, fret, fret + 2, fret],
      [_i, _i, _m, _i, _r, _i],
    );

_Shape get _em7 =>
    (fret) =>
        ([fret, fret, fret, fret, fret + 2, fret], [_i, _i, _i, _i, _r, _i]);

_Shape get _emaj7 =>
    (fret) => (
      [fret, fret, fret + 1, fret + 1, fret + 2, fret],
      [_i, _i, _m, _m, _r, _i],
    );

_Shape get _aMajor =>
    (fret) => (
      [fret, fret + 2, fret + 2, fret + 2, fret, null],
      [_i, _p, _r, _m, _i, null],
    );

_Shape get _aMinor =>
    (fret) => (
      [fret, fret + 1, fret + 2, fret + 2, fret, null],
      [_i, _m, _p, _r, _i, null],
    );

_Shape get _a7 =>
    (fret) => (
      [fret, fret + 2, fret, fret + 2, fret, null],
      [_i, _r, _i, _m, _i, null],
    );

_Shape get _am7 =>
    (fret) => (
      [fret, fret + 1, fret, fret + 2, fret, null],
      [_i, _m, _i, _r, _i, null],
    );

_Shape get _amaj7 =>
    (fret) => (
      [fret, fret + 2, fret + 1, fret + 2, fret, null],
      [_i, _p, _m, _r, _i, null],
    );

List<ChordBlock> _power(Set<String> used) {
  final blocks = <ChordBlock>[];
  for (var fret = 0; fret <= 11; fret++) {
    final lowRoot = fret == 0 ? null : _i;
    final fifth = fret == 0 ? _i : _r;
    final octave = fret == 0 ? _m : _p;
    final lowName = '${chordPitchNames[(4 + fret) % 12]}5';
    blocks.add(
      _card(
        used,
        ChordGroup.power,
        lowName,
        [null, null, null, fret + 2, fret + 2, fret],
        [null, null, null, octave, fifth, lowRoot],
        section: 'Low E',
        extra: 'low E',
      ),
    );
    final aName = '${chordPitchNames[(9 + fret) % 12]}5';
    blocks.add(
      _card(
        used,
        ChordGroup.power,
        aName,
        [null, null, fret + 2, fret + 2, fret, null],
        [null, null, octave, fifth, lowRoot, null],
        section: 'A string',
        extra: 'A-string',
      ),
    );
  }
  return blocks;
}
