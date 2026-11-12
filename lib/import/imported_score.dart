import '../models/fretting_finger.dart';
import '../models/instrument.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';
import '../music/part_names.dart';
import '../music/position_fingering.dart';

/// A Guitar Pro file after alphaTab has turned it into plain numbers.
class ImportedScore {
  const ImportedScore({
    required this.title,
    required this.tempoBpm,
    required this.tracks,
    this.bars = const [],
  });

  final String title;
  final int tempoBpm;
  final List<ImportedTrack> tracks;

  /// Where the file's bar lines fall. Every part shares them.
  final List<SongBar> bars;

  factory ImportedScore.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'];
    if (rawTracks is! List) {
      throw const FormatException('The file reader did not return any tracks.');
    }

    final tracks = <ImportedTrack>[];
    for (final raw in rawTracks) {
      if (raw is! Map) continue;
      final track = Map<String, dynamic>.from(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
      final notes = _notesFromJson(track['notes']);
      if (notes.isEmpty) continue;
      final name = track['name'];
      final strings = track['strings'];
      tracks.add(
        ImportedTrack(
          name: name is String && name.trim().isNotEmpty ? name.trim() : 'Guitar',
          notes: notes,
          stringCount: strings is num ? strings.round() : 6,
        ),
      );
    }

    final title = json['title'];
    final tempo = json['tempoBpm'];
    return ImportedScore(
      title: title is String ? title.trim() : '',
      tempoBpm: tempo is num && tempo > 0 ? tempo.round() : 120,
      tracks: namePlayableParts(tracks),
      bars: _barsFromJson(json['bars']),
    );
  }

  /// The title on the practice screen. The track name is added when the
  /// file has a part name that is not already the song title.
  TabSong toSong(ImportedTrack track, {required String fallbackTitle}) {
    final songTitle = title.isNotEmpty ? title : fallbackTitle;
    final showTrack = track.name.isNotEmpty && track.name != songTitle;
    final instrument = track.instrument;
    return TabSong(
      title: showTrack ? '$songTitle — ${track.name}' : songTitle,
      tempoBpm: tempoBpm,
      notes: assignPositionFingers(track.notes, instrument: instrument),
      instrument: instrument,
      bars: bars,
    );
  }
}

class ImportedTrack {
  const ImportedTrack({
    required this.name,
    required this.notes,
    this.stringCount = 6,
  });

  final String name;
  final List<TabNote> notes;

  /// How many strings the file gave this part.
  final int stringCount;

  /// Four strings is a bass. Anything else sits on the six-line staff.
  Instrument get instrument {
    return stringCount == Instrument.bass.stringCount
        ? Instrument.bass
        : Instrument.guitar;
  }
}

List<SongBar> _barsFromJson(Object? raw) {
  if (raw is! List) return const [];
  final bars = <SongBar>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final start = item['startMs'];
    final end = item['endMs'];
    final beats = item['beats'];
    if (start is! num || end is! num || end <= start) continue;
    bars.add(
      SongBar(
        startMs: start.round(),
        endMs: end.round(),
        beats: beats is num && beats > 0 ? beats.round() : 4,
      ),
    );
  }
  return bars;
}

List<TabNote> _notesFromJson(Object? raw) {
  if (raw is! List) return const [];
  final notes = <TabNote>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final note = Map<String, dynamic>.from(
      item.map((key, value) => MapEntry(key.toString(), value)),
    );
    final time = note['timeMs'];
    final duration = note['durationMs'];
    final string = note['string'];
    final fret = note['fret'];
    final midi = note['midi'];
    if (time is! num ||
        duration is! num ||
        string is! num ||
        fret is! num ||
        midi is! num) {
      continue;
    }
    final fretNumber = fret.round();
    notes.add(
      TabNote(
        timeMs: time.round(),
        string: string.round(),
        fret: fretNumber,
        durationMs: duration.round(),
        midi: midi.round(),
        // Open strings stay hollow. A fret number is not a finger.
        finger: fretNumber == 0 ? null : _fingerFromJson(note['finger']),
      ),
    );
  }
  return notes;
}

FrettingFinger? _fingerFromJson(Object? raw) {
  if (raw is! num) return null;
  return switch (raw.round()) {
    1 => FrettingFinger.indexFinger,
    2 => FrettingFinger.middle,
    3 => FrettingFinger.ring,
    4 => FrettingFinger.pinky,
    _ => null,
  };
}
