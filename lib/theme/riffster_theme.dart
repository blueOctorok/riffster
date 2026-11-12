import 'package:flutter/material.dart';

import '../music/score_note.dart';

/// Every color the app uses, by what it is for.
///
/// The room is a warm, dark workshop. Cream is the light in it, and gold
/// is the one accent: the playhead, the thing you press, the thing that
/// is on.
abstract final class RiffColors {
  /// The room behind everything.
  static const room = Color(0xFF1A1814);

  /// The corners of the room, where the light does not reach.
  static const roomDeep = Color(0xFF100E0B);

  /// A raised panel.
  static const panel = Color(0xFF241F1A);
  static const panelLit = Color(0xFF2E2821);

  /// A hairline around a panel, and a slider's empty track.
  static const line = Color(0xFF3A342C);
  static const lineStrong = Color(0xFF4A433A);

  /// Text, from the loudest to the quietest.
  static const cream = Color(0xFFF3EEE6);
  static const quiet = Color(0xFF8A8175);
  static const faint = Color(0xFF5C564E);

  static const gold = Color(0xFFE4B15A);
  static const goldLit = Color(0xFFF6D28B);
  static const goldDeep = Color(0xFFB07E2C);

  /// Text that sits on gold.
  static const onGold = Color(0xFF1A1814);

  /// Ink on the paper chord cards.
  static const cardInk = Color(0xFF2A241C);
  static const cardQuiet = Color(0xFF6E675E);

  static const hit = Color(0xFF3DDC6E);
  static const miss = Color(0xFFE85D75);

  /// A hit is green, early or late is gold, and a miss is rose.
  static Color forMark(ScoreMark mark) {
    return switch (mark) {
      ScoreMark.hit => hit,
      ScoreMark.early || ScoreMark.late => gold,
      ScoreMark.miss => miss,
    };
  }
}

/// The two typefaces. Both ship inside the app under the SIL Open Font
/// License, so the look does not depend on what Windows has installed.
abstract final class RiffFonts {
  /// Titles, the countdown, and big numbers.
  static const display = 'Instrument Serif';

  /// Buttons, labels, and the fret numbers on the notes.
  static const text = 'Instrument Sans';
}

/// Text styles by job. A widget asks for "a label", not for 13 pixels.
abstract final class RiffText {
  static const wordmark = TextStyle(
    fontFamily: RiffFonts.display,
    fontSize: 26,
    height: 1,
    color: RiffColors.cream,
  );

  static const title = TextStyle(
    fontFamily: RiffFonts.display,
    fontSize: 36,
    height: 1.05,
    color: RiffColors.cream,
  );

  /// A number you read from across the room: the heard note, the streak.
  static const figure = TextStyle(
    fontFamily: RiffFonts.display,
    fontSize: 34,
    height: 1,
    color: RiffColors.cream,
  );

  static const body = TextStyle(
    fontFamily: RiffFonts.text,
    fontSize: 14,
    color: RiffColors.cream,
  );

  static const label = TextStyle(
    fontFamily: RiffFonts.text,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: RiffColors.quiet,
  );

  /// The small capitals over a figure: HEARD, IN A ROW.
  static const caption = TextStyle(
    fontFamily: RiffFonts.text,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: RiffColors.quiet,
  );
}

/// How long things take to move. Short, so the app feels quick.
abstract final class RiffMotion {
  static const quick = Duration(milliseconds: 120);
  static const settle = Duration(milliseconds: 220);
  static const slide = Duration(milliseconds: 320);

  /// Fast at first, then easing into place.
  static const ease = Curves.easeOutCubic;
}

abstract final class RiffShadows {
  /// Under a panel that sits on the room.
  static const panel = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Under the fretboard, which sits higher than a panel.
  static const board = [
    BoxShadow(color: Color(0x99000000), blurRadius: 36, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// The light a lit gold control throws.
  static const goldGlow = [
    BoxShadow(color: Color(0x55E4B15A), blurRadius: 18, spreadRadius: 1),
  ];
}

/// The Material theme. Every stock button, slider, and tooltip in the app
/// takes its look from here, so a screen never styles one by hand.
ThemeData riffsterTheme() {
  const scheme = ColorScheme.dark(
    surface: RiffColors.room,
    primary: RiffColors.gold,
    onPrimary: RiffColors.onGold,
    onSurface: RiffColors.cream,
    outline: RiffColors.lineStrong,
  );
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );
  const buttonText = TextStyle(
    fontFamily: RiffFonts.text,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 14);

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: RiffColors.room,
    fontFamily: RiffFonts.text,
    splashFactory: NoSplash.splashFactory,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: buttonShape,
        textStyle: buttonText,
        padding: buttonPadding,
        animationDuration: RiffMotion.quick,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: buttonShape,
        textStyle: buttonText,
        padding: buttonPadding,
        foregroundColor: RiffColors.cream,
        side: const BorderSide(color: RiffColors.lineStrong),
        animationDuration: RiffMotion.quick,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: buttonShape,
        textStyle: buttonText,
        animationDuration: RiffMotion.quick,
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 3,
      activeTrackColor: RiffColors.gold,
      inactiveTrackColor: RiffColors.line,
      thumbColor: RiffColors.goldLit,
      overlayColor: Color(0x33E4B15A),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: RiffColors.panelLit,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border.fromBorderSide(BorderSide(color: RiffColors.lineStrong)),
      ),
      textStyle: TextStyle(
        fontFamily: RiffFonts.text,
        fontSize: 12,
        color: RiffColors.cream,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: RiffColors.panel,
      titleTextStyle: TextStyle(
        fontFamily: RiffFonts.display,
        fontSize: 26,
        color: RiffColors.cream,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: RiffColors.panelLit,
      contentTextStyle: TextStyle(
        fontFamily: RiffFonts.text,
        color: RiffColors.cream,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
