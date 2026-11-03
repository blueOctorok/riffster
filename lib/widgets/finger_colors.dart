import 'package:flutter/material.dart';

import '../models/fretting_finger.dart';

/// Finger colors for the staff dots and the legend.
///
/// Index is blue, middle is green, ring is gold, pinky is rose.
/// Open strings are not in this map.
const fingerColor = <FrettingFinger, Color>{
  FrettingFinger.indexFinger: Color(0xFF3B82F6),
  FrettingFinger.middle: Color(0xFF3DDC6E),
  FrettingFinger.ring: Color(0xFFF0C43A),
  FrettingFinger.pinky: Color(0xFFE85D75),
};

const fingerNumberColor = <FrettingFinger, Color>{
  FrettingFinger.indexFinger: Color(0xFFFFFFFF),
  FrettingFinger.middle: Color(0xFF1A1814),
  FrettingFinger.ring: Color(0xFF1A1814),
  FrettingFinger.pinky: Color(0xFFFFFFFF),
};

const fingerLabel = <FrettingFinger, String>{
  FrettingFinger.indexFinger: 'Index',
  FrettingFinger.middle: 'Middle',
  FrettingFinger.ring: 'Ring',
  FrettingFinger.pinky: 'Pinky',
};
