import '../models/fretting_finger.dart';
import '../models/instrument.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';
import '../music/melody_on_bass.dart';
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
      final tuning = track['tuning'];
      tracks.add(
        ImportedTrack(
          name: name is String && name.trim().isNotEmpty
              ? name.trim()
              : 'Guitar',
          notes: notes,
          tuning: tuning is List
              ? [for (final pitch in tuning.whereType<num>()) pitch.round()]
              : _standardGuitar,
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

  /// [track] as it is written in the file. The stage has to have a staff
  /// for it, so this is only for a part whose [ImportedTrack.instrument]
  /// is known.
  TabSong toSong(ImportedTrack track, {required String fallbackTitle}) {
    final instrument = track.instrument!;
    return TabSong(
      title: _titleWith(track.name, fallbackTitle),
      tempoBpm: tempoBpm,
      notes: assignPositionFingers(track.notes, instrument: instrument),
      instrument: instrument,
      bars: bars,
    );
  }

  /// The melody of [track] as a line for the bass. Any part will do: a
  /// lead guitar, a voice, a keyboard. Only its pitches and times are
  /// used, and nothing leaves this computer.
  TabSong toMelodyOnBass(
    ImportedTrack track, {
    required String fallbackTitle,
    required Register register,
  }) {
    return TabSong(
      // The two registers are two songs in the Library, each with its
      // own scores, so they need two names.
      title: _titleWith(
        register == Register.high
            ? '${track.name} on bass, high'
            : '${track.name} on bass',
        fallbackTitle,
      ),
      tempoBpm: tempoBpm,
      notes: assignPositionFingers(
        melodyOnBass(track.notes, register: register),
        instrument: Instrument.bass,
      ),
      instrument: Instrument.bass,
      bars: bars,
    );
  }

  /// The title on the practice screen. The part is added when it has a
  /// name that is not already the song title.
  String _titleWith(String part, String fallbackTitle) {
    final songTitle = title.isNotEmpty ? title : fallbackTitle;
    final showPart = part.isNotEmpty && part != songTitle;
    return showPart ? '$songTitle — $part' : songTitle;
  }
}

final _standardGuitar = Instrument.guitar.openStringMidi;

class ImportedTrack {
  ImportedTrack({required this.name, required this.notes, List<int>? tuning})
    : tuning = tuning ?? _standardGuitar;

  final String name;
  final List<TabNote> notes;

  /// The pitch of each open string as the file has it, from the top line
  /// of the staff down. Empty for a part with no strings, such as a voice
  /// or a keyboard. A file that does not say is read as a guitar.
  final List<int> tuning;

  /// The instrument this part is written for. Null when the stage has no
  /// staff for it: five strings, seven, or none.
  ///
  /// The count alone is not enough, because a ukulele has four strings
  /// too. The part also has to be [isAsLowAs] the instrument.
  Instrument? get instrument {
    for (final instrument in Instrument.values) {
      final sameStrings = tuning.length == instrument.stringCount;
      if (sameStrings && isAsLowAs(instrument)) return instrument;
    }
    return null;
  }

  /// True when the lowest string sits within a fourth of [instrument]'s
  /// own. That lets in a part tuned down a step, and the low B of a
  /// five-string bass, and keeps a guitar apart from a bass.
  bool isAsLowAs(Instrument instrument) {
    if (tuning.isEmpty) return false;
    return (tuning.last - instrument.openStringMidi.last).abs() <= 5;
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
