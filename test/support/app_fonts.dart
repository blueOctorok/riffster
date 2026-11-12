import 'dart:io';

import 'package:flutter/services.dart';
import 'package:riffster/theme/riffster_theme.dart';

/// Loads the app's real typefaces and icons into a test.
///
/// A widget test draws every letter as a plain square unless told
/// otherwise. Squares are far wider than real letters, so text wraps
/// that would not wrap in the app. A test that measures the layout, or
/// saves a picture of it, has to load the real fonts first.
///
/// Reading files is real work, so call this inside `tester.runAsync`.
Future<void> loadAppFonts() async {
  const files = {
    RiffFonts.display: [
      'InstrumentSerif-Regular.ttf',
      'InstrumentSerif-Italic.ttf',
    ],
    RiffFonts.text: [
      'InstrumentSans-Regular.ttf',
      'InstrumentSans-Medium.ttf',
      'InstrumentSans-SemiBold.ttf',
      'InstrumentSans-Bold.ttf',
    ],
  };
  for (final MapEntry(key: family, value: names) in files.entries) {
    final loader = FontLoader(family);
    for (final name in names) {
      loader.addFont(_fontFile('assets/fonts/$name'));
    }
    await loader.load();
  }
  // The icons are a font too. Without it every icon is an empty box.
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      _fontFile(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ),
    );
  await icons.load();
}

Future<ByteData> _fontFile(String path) async {
  return ByteData.sublistView(await File(path).readAsBytes());
}
