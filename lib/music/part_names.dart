import '../import/imported_score.dart';
import '../models/tab_note.dart';

final _genericName = RegExp(
  r'^(track|part|guitar|instrument|inst|untitled) ?\d*$',
  caseSensitive: false,
);

/// Replaces "Track 1" style names with a description of the notes.
///
/// A name the file actually chose, such as "Solo", is kept. An unnamed part
/// that is an exact copy of an earlier part is dropped. The others stay,
/// because any of them might be the line the player wants. The label comes
/// from the shape: mostly one note at a time, chords, a pair of notes, or
/// the same rhythm as another part with different pitches.
List<ImportedTrack> namePlayableParts(List<ImportedTrack> tracks) {
  final kept = <ImportedTrack>[];
  final seenPitches = <String>{};
  for (final track in tracks) {
    final pitches = _pitchKey(track.notes);
    if (_isGeneric(track.name) && seenPitches.contains(pitches)) continue;
    seenPitches.add(pitches);
    kept.add(track);
  }

  final rhythmCounts = <String, int>{};
  for (final track in kept) {
    final rhythm = _rhythmKey(track.notes);
    rhythmCounts[rhythm] = (rhythmCounts[rhythm] ?? 0) + 1;
  }

  final roles = <int, _PartRole>{};
  final roleTotals = <_PartRole, int>{};
  for (var i = 0; i < kept.length; i++) {
    if (!_isGeneric(kept[i].name)) continue;
    final role = _role(kept[i].notes, rhythmCounts[_rhythmKey(kept[i].notes)] ?? 1);
    roles[i] = role;
    roleTotals[role] = (roleTotals[role] ?? 0) + 1;
  }

  final seenRoles = <_PartRole, int>{};
  return [
    for (var i = 0; i < kept.length; i++)
      roles.containsKey(i) ? _renamed(kept[i], roles[i]!, roleTotals, seenRoles) : kept[i],
  ];
}

bool _isGeneric(String name) => _genericName.hasMatch(name.trim());

enum _PartRole { line, chords, doubles, harmony }

_PartRole _role(List<TabNote> notes, int partsWithThisRhythm) {
  // Same attacks as another part, different pitches: two guitars in harmony.
  if (partsWithThisRhythm > 1) return _PartRole.harmony;

  final sizes = _sizes(notes);
  var chords = 0;
  var doubles = 0;
  for (final size in sizes) {
    if (size >= 3) chords++;
    if (size == 2) doubles++;
  }
  // Half or more. A line that strums a chord now and then stays a line.
  if (chords * 2 >= sizes.length) return _PartRole.chords;
  if (doubles * 2 >= sizes.length) return _PartRole.doubles;
  return _PartRole.line;
}

ImportedTrack _renamed(
  ImportedTrack track,
  _PartRole role,
  Map<_PartRole, int> totals,
  Map<_PartRole, int> seen,
) {
  const labels = {
    _PartRole.line: 'Single notes',
    _PartRole.chords: 'Chords',
    _PartRole.doubles: 'Two notes',
    _PartRole.harmony: 'Harmony',
  };
  final number = (seen[role] ?? 0) + 1;
  seen[role] = number;
  final label = labels[role]!;
  final name = (totals[role] ?? 1) == 1 ? label : '$label $number';
  return ImportedTrack(name: name, notes: track.notes, tuning: track.tuning);
}

/// How many notes sound at each moment.
List<int> _sizes(List<TabNote> notes) {
  final byTime = <int, int>{};
  for (final note in notes) {
    byTime[note.timeMs] = (byTime[note.timeMs] ?? 0) + 1;
  }
  return byTime.values.toList();
}

/// Times plus how many notes sit on each one. Two parts are a harmony only
/// when both of those match. A chord and a single note that happen to start
/// together are not the same rhythm.
String _rhythmKey(List<TabNote> notes) {
  final sizes = <int, int>{};
  for (final note in notes) {
    sizes[note.timeMs] = (sizes[note.timeMs] ?? 0) + 1;
  }
  final times = sizes.keys.toList()..sort();
  return [for (final time in times) '$time:${sizes[time]}'].join(',');
}

String _pitchKey(List<TabNote> notes) {
  final byTime = <int, List<int>>{};
  for (final note in notes) {
    byTime.putIfAbsent(note.timeMs, () => []).add(note.midi);
  }
  final times = byTime.keys.toList()..sort();
  return [
    for (final time in times) '$time:${(List<int>.of(byTime[time]!)..sort()).join('.')}',
  ].join('|');
}
