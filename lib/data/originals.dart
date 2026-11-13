import '../models/instrument.dart';
import '../models/tab_song.dart';
import '../music/place_on_neck.dart';
import '../music/position_fingering.dart';
import '../music/riff_text.dart';
import 'library_item.dart';

/// The songs that come with the app, all for bass.
///
/// The riffs and melodies were written for Riffster and copy nobody's
/// song. The old tunes are by composers dead for well over a century,
/// or have no known author, and each line here was set down from the
/// bare melody and from no modern arrangement.
///
/// They are written as note names and beats (see [readRiffText]), and
/// the same code that places a melody from a file picks the frets.
final List<LibraryItem> builtInSongs = [
  // Riffs, each a different feel. They are short so they loop.
  _song(
    'Low Road',
    about: 'Rock. Straight eighths on the low E.',
    tempoBpm: 104,
    line: '''
      E1:.5 E1:.5 E1:.5 E1:.5 G1:.5 G1:.5 A1:.5 B1:.5 |
      E1:.5 E1:.5 E1:.5 E1:.5 D2:.5 B1:.5 A1:.5 G1:.5 |
      C2:.5 C2:.5 C2:.5 C2:.5 B1:.5 B1:.5 A1:.5 G1:.5 |
      A1:.5 A1:.5 B1:.5 B1:.5 E1:2
    ''',
  ),
  _song(
    'Back Porch',
    about: 'Blues shuffle in A. Long, short, long, short.',
    tempoBpm: 92,
    line: '''
      A1:2/3 A1:1/3 C#2:2/3 C#2:1/3 E2:2/3 E2:1/3 F#2:2/3 E2:1/3 |
      D2:2/3 D2:1/3 F#2:2/3 F#2:1/3 A2:2/3 A2:1/3 B2:2/3 A2:1/3 |
      A1:2/3 A1:1/3 C#2:2/3 C#2:1/3 E2:2/3 E2:1/3 F#2:2/3 E2:1/3 |
      E2:2/3 E2:1/3 D2:2/3 D2:1/3 C#2:2/3 B1:1/3 A1:1
    ''',
  ),
  _song(
    'Pocket Change',
    about: 'Funk in E. The rests are part of it.',
    tempoBpm: 96,
    line: '''
      E1:.75 E1:.25 -:.5 E2:.5 -:.25 D2:.25 E2:.5 -:.5 G1:.25 A1:.25 |
      E1:.75 E1:.25 -:.5 E2:.5 -:.25 D2:.25 B1:.5 A1:.5 G1:.5
    ''',
  ),
  _song(
    'Island Time',
    about: 'Reggae in A minor. Nothing on beat one.',
    tempoBpm: 76,
    line: '''
      -:1 A1:.5 A1:.5 C2:1 E2:.5 C2:.5 |
      -:1 G1:.5 G1:.5 B1:1 D2:.5 B1:.5 |
      -:1 F1:.5 F1:.5 A1:1 C2:.5 A1:.5 |
      -:1 E1:.5 E1:.5 G1:.5 A1:.5 B1:1
    ''',
  ),
  _song(
    'Second Shift',
    about: 'Soul in C. A long note, then a climb.',
    tempoBpm: 108,
    line: '''
      C2:1.5 C2:.5 E2:.5 G2:.5 A2:.5 G2:.5 |
      F1:1.5 F1:.5 A1:.5 C2:.5 D2:.5 C2:.5 |
      C2:1.5 C2:.5 E2:.5 G2:.5 A2:.5 G2:.5 |
      G1:1.5 G1:.5 B1:.5 D2:.5 B1:.5 G1:.5
    ''',
  ),
  _song(
    'Walk It Home',
    about: 'Jazz walk. A note on every beat.',
    tempoBpm: 120,
    line: '''
      D2:1 F2:1 A2:1 G#2:1 |
      G2:1 B1:1 D2:1 Db2:1 |
      C2:1 E2:1 G2:1 A2:1 |
      A1:1 C#2:1 E2:1 Eb2:1
    ''',
  ),
  _song(
    'Glitter Floor',
    about: 'Disco in G. Low, high, low, high.',
    tempoBpm: 116,
    line: '''
      G1:.5 G2:.5 G1:.5 G2:.5 G1:.5 G2:.5 G1:.5 G2:.5 |
      Bb1:.5 Bb2:.5 Bb1:.5 Bb2:.5 C2:.5 C3:.5 C2:.5 C3:.5 |
      G1:.5 G2:.5 G1:.5 G2:.5 G1:.5 G2:.5 G1:.5 G2:.5 |
      F1:.5 F2:.5 F1:.5 F2:.5 D2:.5 D3:.5 D2:.5 D3:.5
    ''',
  ),
  _song(
    'Iron Horse',
    about: 'Metal gallop in E. One long, two short.',
    tempoBpm: 132,
    line: '''
      E1:.5 E1:.25 E1:.25 E1:.5 E1:.25 E1:.25 E1:.5 E1:.25 E1:.25 E1:.5 E1:.25 E1:.25 |
      E1:.5 E1:.25 E1:.25 E1:.5 E1:.25 E1:.25 G1:.5 G1:.25 G1:.25 A1:.5 A1:.25 A1:.25 |
      E1:.5 E1:.25 E1:.25 E1:.5 E1:.25 E1:.25 E1:.5 E1:.25 E1:.25 E1:.5 E1:.25 E1:.25 |
      C2:.5 C2:.25 C2:.25 C2:.5 C2:.25 C2:.25 D2:.5 D2:.25 D2:.25 D2:.5 D2:.25 D2:.25
    ''',
  ),
  _song(
    'Sabor',
    about: 'Latin in A minor. Each bar leans into the next.',
    tempoBpm: 100,
    line: '''
      A1:1.5 E2:1.5 A1:1 |
      -:1.5 E2:1.5 D2:1 |
      -:1.5 A2:1.5 E2:1 |
      -:1.5 B1:1.5 A1:1
    ''',
  ),
  _song(
    'Lamplight',
    about: 'Ballad in D. Slow, with room to breathe.',
    tempoBpm: 66,
    line: '''
      D2:2 A1:1 D2:1 |
      B1:2 F#1:1 B1:1 |
      G1:2 D2:1 G1:1 |
      A1:2 A1:.5 B1:.5 C#2:1
    ''',
  ),
  _song(
    'Three Chords Fast',
    about: 'Punk. Eighths, and no letting up.',
    tempoBpm: 160,
    line: '''
      A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 |
      D2:.5 D2:.5 D2:.5 D2:.5 D2:.5 D2:.5 D2:.5 D2:.5 |
      A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 A1:.5 |
      E1:.5 E1:.5 E1:.5 E1:.5 E1:.5 F#1:.5 G#1:.5 E1:.5
    ''',
  ),
  _song(
    'Corner Store',
    about: 'Hip-hop in G minor. Short phrases with gaps.',
    tempoBpm: 88,
    line: '''
      G1:1 -:.5 G1:.5 Bb1:.5 C2:.5 -:.5 D2:.5 |
      F1:1 -:.5 F1:.5 D2:.5 C2:.5 Bb1:.5 G1:.5
    ''',
  ),

  // Melodies, higher up, where a bass sings.
  _song(
    'Open Window',
    about: 'A melody in D, up the neck.',
    tempoBpm: 84,
    line: '''
      D3:1 F#3:1 A3:1.5 G3:.5 |
      F#3:1 E3:1 D3:2 |
      B2:1 D3:1 E3:1.5 F#3:.5 |
      E3:2 A2:2
    ''',
  ),
  _song(
    'Paper Boats',
    about: 'A melody in A minor.',
    tempoBpm: 96,
    line: '''
      A2:1 C3:.5 B2:.5 A2:1 E2:1 |
      G2:1 A2:.5 G2:.5 E2:2 |
      F2:1 A2:.5 G2:.5 F2:1 D2:1 |
      E2:1 G#2:1 A2:2
    ''',
  ),
  _song(
    'Last Train Out',
    about: 'A melody on five notes, in E minor.',
    tempoBpm: 104,
    line: '''
      E2:.5 G2:.5 A2:1 B2:.5 A2:.5 G2:1 |
      E2:.5 G2:.5 A2:1 D3:1 B2:1 |
      E3:1 D3:.5 B2:.5 A2:1 G2:1 |
      A2:.5 G2:.5 E2:1 E2:2
    ''',
  ),

  // Old tunes.
  _song(
    'Ode to Joy',
    source: SongSource.oldTune,
    about: 'Beethoven, 1824.',
    tempoBpm: 108,
    line: '''
      E2:1 E2:1 F2:1 G2:1 | G2:1 F2:1 E2:1 D2:1 |
      C2:1 C2:1 D2:1 E2:1 | E2:1.5 D2:.5 D2:2 |
      E2:1 E2:1 F2:1 G2:1 | G2:1 F2:1 E2:1 D2:1 |
      C2:1 C2:1 D2:1 E2:1 | D2:1.5 C2:.5 C2:2 |
      D2:1 D2:1 E2:1 C2:1 | D2:1 E2:.5 F2:.5 E2:1 C2:1 |
      D2:1 E2:.5 F2:.5 E2:1 D2:1 | C2:1 D2:1 G1:2 |
      E2:1 E2:1 F2:1 G2:1 | G2:1 F2:1 E2:1 D2:1 |
      C2:1 C2:1 D2:1 E2:1 | D2:1.5 C2:.5 C2:2
    ''',
  ),
  _song(
    'Amazing Grace',
    source: SongSource.oldTune,
    about: 'American hymn tune, 1829. Three beats to the bar.',
    tempoBpm: 84,
    beatsPerBar: 3,
    line: '''
      -:2 A1:1 |
      D2:2 F#2:.5 D2:.5 | F#2:2 E2:1 | D2:2 B1:1 | A1:2 A1:1 |
      D2:2 F#2:.5 D2:.5 | F#2:2 E2:1 | A2:3 | A2:2 F#2:1 |
      A2:1.5 F#2:.5 A2:.5 F#2:.5 | D2:2 A1:1 |
      B1:1.5 D2:.5 D2:.5 B1:.5 | A1:2 A1:1 |
      D2:2 F#2:.5 D2:.5 | F#2:2 E2:1 | D2:3 | D2:2 -:1
    ''',
  ),
  _song(
    'Greensleeves',
    source: SongSource.oldTune,
    about: 'English, 16th century. Three beats to the bar.',
    tempoBpm: 96,
    beatsPerBar: 3,
    line: '''
      -:2 A1:1 |
      C2:2 D2:1 | E2:1.5 F#2:.5 E2:1 | D2:2 B1:1 | G1:1.5 A1:.5 B1:1 |
      C2:2 A1:1 | A1:1.5 G#1:.5 A1:1 | B1:2 G#1:1 | E1:2 A1:1 |
      C2:2 D2:1 | E2:1.5 F#2:.5 E2:1 | D2:2 B1:1 | G1:1.5 A1:.5 B1:1 |
      C2:1.5 B1:.5 A1:1 | G#1:1.5 F#1:.5 G#1:1 | A1:3 | A1:3 |
      G2:3 | G2:1.5 F#2:.5 E2:1 | D2:2 B1:1 | G1:1.5 A1:.5 B1:1 |
      C2:2 A1:1 | A1:1.5 G#1:.5 A1:1 | B1:2 G#1:1 | E1:3 |
      G2:3 | G2:1.5 F#2:.5 E2:1 | D2:2 B1:1 | G1:1.5 A1:.5 B1:1 |
      C2:1.5 B1:.5 A1:1 | G#1:1.5 F#1:.5 G#1:1 | A1:3 | A1:3
    ''',
  ),
];

LibraryItem _song(
  String title, {
  required String about,
  required int tempoBpm,
  required String line,
  SongSource source = SongSource.original,
  int beatsPerBar = 4,
}) {
  final read = readRiffText(line, tempoBpm: tempoBpm, beatsPerBar: beatsPerBar);
  return LibraryItem(
    source: source,
    about: about,
    song: TabSong(
      title: title,
      tempoBpm: tempoBpm,
      instrument: Instrument.bass,
      bars: read.bars,
      notes: assignPositionFingers(
        placeOnNeck(read.pitches, instrument: Instrument.bass),
        instrument: Instrument.bass,
      ),
    ),
  );
}
