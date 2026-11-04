import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/tab_song.dart';
import 'guitar_pro_reader.dart';
import 'imported_score.dart';

const guitarProExtensions = ['gp', 'gp3', 'gp4', 'gp5', 'gpx'];

/// Asks for a Guitar Pro file and returns the part the player chose.
///
/// A cancelled dialog returns null. The warm-up stays on screen.
Future<TabSong?> openGuitarPro(
  BuildContext context,
  GuitarProReader reader,
) async {
  final files = await FilePicker.pickFiles(
    dialogTitle: 'Open a Guitar Pro file',
    type: FileType.custom,
    allowedExtensions: guitarProExtensions,
  );
  if (files.isEmpty) return null;

  final picked = files.first;
  final path = picked.path;
  if (path == null) return null;

  final score = await reader.read(await File(path).readAsBytes());
  if (score.tracks.isEmpty) {
    throw const FormatException('That file has no guitar notes.');
  }

  if (!context.mounted) return null;
  final track = score.tracks.length == 1
      ? score.tracks.first
      : await _chooseTrack(context, score.tracks);
  if (track == null) return null;

  final fallback = picked.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
  return score.toSong(track, fallbackTitle: fallback);
}

String _noteCountLabel(int count) {
  return count == 1 ? '1 note' : '$count notes';
}

Future<ImportedTrack?> _chooseTrack(
  BuildContext context,
  List<ImportedTrack> tracks,
) {
  return showDialog<ImportedTrack>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Which part is yours?'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final track in tracks)
                ListTile(
                  title: Text(track.name),
                  subtitle: Text(_noteCountLabel(track.notes.length)),
                  onTap: () => Navigator.pop(context, track),
                ),
            ],
          ),
        ),
      );
    },
  );
}
