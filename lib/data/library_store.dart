import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/tab_song.dart';
import 'library_item.dart';
import 'originals.dart';
import 'song_file.dart';

/// Every song the player can come back to, and the best score on each.
///
/// The songs that ship with the app are in the program itself. A part
/// opened from a file is written to a `library` folder in the app's own
/// data folder, one small file per song, so it opens again without the
/// file it came from. The scores for all of them sit beside those, in
/// one `scores.json`.
///
/// Like the settings, a missing or damaged file is skipped and never
/// stops the app from opening.
///
/// Whatever changes the Library changes the copy in memory at once and
/// hands back a future for the write to disk. The app does not wait on
/// it. A test does, so it can look at the file.
class LibraryStore {
  LibraryStore._(this._folder);

  /// A library that forgets when the app closes. Tests use this so they
  /// never touch the disk.
  LibraryStore.inMemory() : _folder = null;

  static Future<LibraryStore> open() async {
    final support = await getApplicationSupportDirectory();
    return openIn(Directory('${support.path}/library'));
  }

  /// Reads the Library kept in [folder], which need not exist yet.
  static Future<LibraryStore> openIn(Directory folder) async {
    final store = LibraryStore._(folder);
    await store._read();
    return store;
  }

  final Directory? _folder;
  final _yours = <String, LibraryItem>{};

  /// For each song, the best share of notes played on time at each
  /// speed. Both are whole percents: `{"low-road-bass": {"70": 96}}`
  /// is 96% on time at 70% speed.
  final _best = <String, Map<int, int>>{};

  /// The player's own songs by title, then the ones that came with the
  /// app.
  List<LibraryItem> get items {
    final yours = _yours.values.toList()
      ..sort((a, b) => a.song.title.compareTo(b.song.title));
    return [
      ...yours,
      // A song of the player's own with the same name stands in for
      // the one that came with the app.
      for (final item in builtInSongs)
        if (!_yours.containsKey(item.id)) item,
    ];
  }

  /// Keeps [song], in place of any song with the same title on the same
  /// instrument.
  Future<void> save(TabSong song) {
    final item = LibraryItem(song: song, source: SongSource.yours);
    _yours[item.id] = item;
    return _write('${item.id}.json', songToJson(song));
  }

  /// Takes one of the player's own songs out, with its scores.
  Future<void> remove(LibraryItem item) async {
    if (_yours.remove(item.id) == null) return;
    _best.remove(item.id);
    await (_delete('${item.id}.json'), _writeScores()).wait;
  }

  /// The best score at each speed [id] has been played at, fastest
  /// first. Empty for a song that has not been played through.
  List<({int speedPercent, int onTimePercent})> bestScores(String id) {
    final bySpeed = _best[id] ?? const {};
    final speeds = bySpeed.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final speed in speeds)
        (speedPercent: speed, onTimePercent: bySpeed[speed]!),
    ];
  }

  /// Notes a finished run of the song called [id]. Only a score better
  /// than the one kept for that speed changes anything, and a song that
  /// is not in the Library keeps no score.
  Future<void> recordRun(
    String id, {
    required double speed,
    required double accuracy,
  }) async {
    if (!items.any((item) => item.id == id)) return;
    final speedPercent = (speed * 100).round();
    final onTimePercent = (accuracy * 100).round();
    final bySpeed = _best.putIfAbsent(id, () => {});
    if (onTimePercent <= (bySpeed[speedPercent] ?? -1)) return;
    bySpeed[speedPercent] = onTimePercent;
    await _writeScores();
  }

  Future<void> _read() async {
    final folder = _folder!;
    if (!await folder.exists()) return;
    await for (final file in folder.list()) {
      if (file is! File || !file.path.endsWith('.json')) continue;
      final json = await _decoded(file);
      if (file.uri.pathSegments.last == _scoresFile) {
        _readScores(json);
        continue;
      }
      final song = songFromJson(json);
      if (song == null) continue;
      final item = LibraryItem(song: song, source: SongSource.yours);
      _yours[item.id] = item;
    }
  }

  void _readScores(Object? json) {
    if (json is! Map) return;
    for (final MapEntry(key: id, value: bySpeed) in json.entries) {
      if (id is! String || bySpeed is! Map) continue;
      _best[id] = {
        for (final MapEntry(key: speed, value: onTime) in bySpeed.entries)
          // The `?` drops the entry when the key is not a number.
          if (speed is String && onTime is int) ?int.tryParse(speed): onTime,
      };
    }
  }

  Future<void> _writeScores() {
    return _write(_scoresFile, {
      for (final MapEntry(key: id, value: bySpeed) in _best.entries)
        // JSON only allows text as a key, so the speed is written as text.
        id: {
          for (final MapEntry(key: speed, value: onTime) in bySpeed.entries)
            '$speed': onTime,
        },
    });
  }

  /// The worst a failed write can cost is the last song or score, and
  /// the copy in memory is right until the app closes.
  Future<void> _write(String name, Object json) async {
    final folder = _folder;
    if (folder == null) return;
    try {
      await folder.create(recursive: true);
      await File('${folder.path}/$name').writeAsString(jsonEncode(json));
    } on FileSystemException {
      // A full or read-only disk. The Library still works until the
      // app closes.
    }
  }

  Future<void> _delete(String name) async {
    final folder = _folder;
    if (folder == null) return;
    try {
      await File('${folder.path}/$name').delete();
    } on FileSystemException {
      // Already gone, which is what was wanted.
    }
  }
}

const _scoresFile = 'scores.json';

Future<Object?> _decoded(File file) async {
  try {
    return jsonDecode(await file.readAsString());
  } on FormatException {
    return null;
  } on FileSystemException {
    return null;
  }
}
