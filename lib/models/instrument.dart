/// The instrument a song is written for.
///
/// Both lists run from staff string 1 (the top line, the highest string)
/// down to the lowest string. The staff draws one line per entry, so a
/// four-string bass and a six-string guitar are the same code.
enum Instrument {
  guitar(
    label: 'Guitar',
    stringNames: ['e', 'B', 'G', 'D', 'A', 'E'],
    openStringMidi: [64, 59, 55, 50, 45, 40],
  ),

  /// A bass sounds one octave below the guitar's lowest four strings.
  bass(
    label: 'Bass',
    stringNames: ['G', 'D', 'A', 'E'],
    openStringMidi: [43, 38, 33, 28],
  );

  const Instrument({
    required this.label,
    required this.stringNames,
    required this.openStringMidi,
  });

  final String label;
  final List<String> stringNames;
  final List<int> openStringMidi;

  int get stringCount => openStringMidi.length;

  /// The lowest note worth listening for: the lowest open string, and
  /// two more semitones for a string tuned down a step.
  int get lowestMidi => openStringMidi.last - 2;

  /// The highest: fret 24 on the top string.
  int get highestMidi => openStringMidi.first + 24;
}
