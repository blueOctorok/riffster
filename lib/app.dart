import 'package:flutter/material.dart';

import 'screens/practice_screen.dart';

class RiffsterApp extends StatelessWidget {
  const RiffsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riffster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1814),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1A1814),
          primary: Color(0xFFE4B15A),
          onPrimary: Color(0xFF1A1814),
          onSurface: Color(0xFFF3EEE6),
        ),
      ),
      home: const PracticeScreen(),
    );
  }
}
