import 'package:flutter/material.dart';

import 'data/settings_store.dart';
import 'screens/instrument_chooser.dart';
import 'screens/practice_screen.dart';
import 'theme/riffster_theme.dart';

class RiffsterApp extends StatefulWidget {
  const RiffsterApp({super.key, required this.store});

  final SettingsStore store;

  @override
  State<RiffsterApp> createState() => _RiffsterAppState();
}

class _RiffsterAppState extends State<RiffsterApp> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return MaterialApp(
      title: 'Riffster',
      debugShowCheckedModeBanner: false,
      theme: riffsterTheme(),
      // The very first launch asks which instrument. After that the
      // answer is on disk and the app opens straight onto the stage.
      // A cross-fade shows a little of whatever is behind the two
      // screens while both are half see-through. With nothing there,
      // that is black, and the fade dips dark in the middle. The room
      // color behind them makes the dip invisible.
      home: ColoredBox(
        color: RiffColors.room,
        child: AnimatedSwitcher(
          duration: RiffMotion.slide,
          child: store.instrument == null
              ? InstrumentChooser(
                  onChosen: (instrument) {
                    setState(() => store.instrument = instrument);
                  },
                )
              : PracticeScreen(store: store),
        ),
      ),
    );
  }
}
