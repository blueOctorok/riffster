import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/instrument.dart';
import '../models/tab_song.dart';
import '../widgets/part_picker.dart';
import 'guitar_pro_reader.dart';
import 'imported_score.dart';
import 'part_choices.dart';

const guitarProExtensions = ['gp', 'gp3', 'gp4', 'gp5', 'gpx'];

/// Asks for a Guitar Pro file and returns the part the player chose,
/// as a song for [playing].
///
/// A cancelled dialog returns null. The song on the stage stays.
Future<TabSong?> openGuitarPro(
  BuildContext context,
  GuitarProReader reader, {
  required Instrument playing,
}) async {
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
    throw const FormatException('That file has no notes to play.');
  }

  if (!context.mounted) return null;
  return choosePart(
    context,
    score,
    playing: playing,
    fallbackTitle: picked.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
  );
}

/// Turns one part of [score] into a song for [playing].
///
/// The picker is skipped only when there is nothing to decide: a file
/// with one part, written for the instrument in hand.
Future<TabSong?> choosePart(
  BuildContext context,
  ImportedScore score, {
  required Instrument playing,
  required String fallbackTitle,
}) async {
  final choices = partChoicesFor(playing, score.tracks);
  final nothingToDecide =
      choices.length == 1 && choices.single.use == PartUse.written;
  final picked = nothingToDecide
      ? (track: choices.single.track, melody: null)
      : await showPartPicker(context, playing: playing, choices: choices);
  if (picked == null) return null;

  final register = picked.melody;
  return register == null
      ? score.toSong(picked.track, fallbackTitle: fallbackTitle)
      : score.toMelodyOnBass(
          picked.track,
          fallbackTitle: fallbackTitle,
          register: register,
        );
}
