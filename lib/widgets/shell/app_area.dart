import 'package:flutter/material.dart';

import '../../models/instrument.dart';

/// The places in the app, in the order the rail lists them.
enum AppArea {
  home(label: 'Home', icon: Icons.home_rounded),
  songs(label: 'Songs', icon: Icons.queue_music_rounded),
  practice(label: 'Practice', icon: Icons.speed_rounded),
  build(label: 'Build', icon: Icons.dashboard_customize_rounded),
  create(label: 'Create', icon: Icons.auto_awesome_rounded),
  library(label: 'Library', icon: Icons.collections_bookmark_rounded);

  const AppArea({required this.label, required this.icon});

  final String label;
  final IconData icon;

  /// Whether this area can be opened today. The others are listed so
  /// the shape of the app is visible, and are marked as on the way.
  /// When an area is built, its line here is the one thing to change.
  bool readyFor(Instrument instrument) {
    return switch (this) {
      home || songs => true,
      // Build is the chord book so far, and that is guitar shapes.
      build => instrument == Instrument.guitar,
      practice || create || library => false,
    };
  }
}
