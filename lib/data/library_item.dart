import '../models/tab_song.dart';

/// Where a song in the Library came from.
enum SongSource {
  /// A part the player opened from a file of their own.
  yours(label: 'Your songs'),

  /// Written for this app.
  original(label: 'Riffster originals'),

  /// A tune old enough to belong to everyone, arranged for this app.
  oldTune(label: 'Old tunes');

  const SongSource({required this.label});

  final String label;
}

/// One song in the Library.
class LibraryItem {
  LibraryItem({required this.song, required this.source, this.about = ''})
    : id = libraryIdOf(song);

  /// The same for the same title on the same instrument, so opening a
  /// part a second time replaces the first and keeps its scores.
  final String id;
  final TabSong song;
  final SongSource source;

  /// One line under the title: the feel of a riff, or who wrote a tune
  /// and when.
  final String about;
}

/// The name a song goes by in the Library, and the name of its file:
/// its title and instrument in lower case, with every run of anything
/// that is not a letter or a digit turned into one dash.
String libraryIdOf(TabSong song) {
  final words = '${song.title} ${song.instrument.name}'.toLowerCase();
  final dashed = words.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return dashed.replaceAll(RegExp(r'^-|-$'), '');
}
