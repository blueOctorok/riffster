import 'package:flutter/material.dart';

import 'app.dart';
import 'data/library_store.dart';
import 'data/settings_store.dart';

Future<void> main() async {
  // Reading the settings and the Library talks to Windows, and Flutter
  // has to be set up before anything can do that.
  WidgetsFlutterBinding.ensureInitialized();
  // Both are read at once. `.wait` on a pair of futures gives back the
  // pair of results, each with its own type.
  final (store, library) = await (
    SettingsStore.open(),
    LibraryStore.open(),
  ).wait;
  runApp(RiffsterApp(store: store, library: library));
}
