import 'package:flutter/material.dart';

/// The fretboard the tab is drawn on.
///
/// [wood] is the board. [ink] is the open-note rings and anything else
/// drawn straight onto the wood. A light board needs dark ink, and a dark
/// board needs light ink, or the rings disappear into the wood. [grain]
/// is the color of the streaks, and [grainStrength] is how loudly this
/// wood shows them: ebony barely, rosewood a lot.
class NeckTheme {
  const NeckTheme({
    required this.name,
    required this.wood,
    required this.ink,
    required this.grain,
    required this.grainStrength,
  });

  final String name;
  final Color wood;
  final Color ink;
  final Color grain;
  final double grainStrength;

  /// True for a blonde board. Shadows and highlights swap on it.
  bool get isLight => wood.computeLuminance() > 0.5;

  @override
  bool operator ==(Object other) => other is NeckTheme && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Today's look. Dark board, cream ink, a few brown streaks.
const ebonyNeck = NeckTheme(
  name: 'Ebony',
  wood: Color(0xFF241F1A),
  ink: Color(0xFFF3EEE6),
  grain: Color(0xFF4A3B2E),
  grainStrength: 0.7,
);

/// A red-brown board with dark streaks, still dark enough for cream ink.
const rosewoodNeck = NeckTheme(
  name: 'Rosewood',
  wood: Color(0xFF5C3329),
  ink: Color(0xFFF6E6D6),
  grain: Color(0xFF2A130E),
  grainStrength: 1.0,
);

/// A blonde board. The ink flips to dark so it stays visible.
const mapleNeck = NeckTheme(
  name: 'Maple',
  wood: Color(0xFFE4C48A),
  ink: Color(0xFF2C2416),
  grain: Color(0xFFA9783A),
  grainStrength: 0.8,
);

const neckThemes = <NeckTheme>[ebonyNeck, rosewoodNeck, mapleNeck];
