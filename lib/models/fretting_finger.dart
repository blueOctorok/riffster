/// Which fretting finger holds a note. Open strings have no finger.
///
/// The index finger is [indexFinger], not `index`, because every Dart
/// enum already has a field by that name.
enum FrettingFinger {
  indexFinger,
  middle,
  ring,
  pinky,
}
