import 'package:flutter/material.dart';

/// The fretboard the tab is drawn on.
///
/// [wood] is the board. [ink] is the strings, the open-note rings, and the
/// string names. A light board needs dark ink, and a dark board needs light
/// ink, or the strings disappear into the wood.
class NeckTheme {
  const NeckTheme({required this.name, required this.wood, required this.ink});

  final String name;
  final Color wood;
  final Color ink;

  @override
  bool operator ==(Object other) => other is NeckTheme && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Today's look. Dark board, cream strings.
const ebonyNeck = NeckTheme(
  name: 'Ebony',
  wood: Color(0xFF241F1A),
  ink: Color(0xFFF3EEE6),
);

/// A red-brown board, still dark enough for cream strings.
const rosewoodNeck = NeckTheme(
  name: 'Rosewood',
  wood: Color(0xFF5C3329),
  ink: Color(0xFFF6E6D6),
);

/// A blonde board. The strings flip to dark so they stay visible.
const mapleNeck = NeckTheme(
  name: 'Maple',
  wood: Color(0xFFE4C48A),
  ink: Color(0xFF2C2416),
);

const neckThemes = <NeckTheme>[ebonyNeck, rosewoodNeck, mapleNeck];
