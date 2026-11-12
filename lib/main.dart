import 'package:flutter/material.dart';

import 'app.dart';
import 'data/settings_store.dart';

Future<void> main() async {
  // Reading the settings file talks to Windows, and Flutter has to be
  // set up before anything can do that.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RiffsterApp(store: await SettingsStore.open()));
}
