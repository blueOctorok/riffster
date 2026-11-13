/// Notices an open input that sends no sound at all.
///
/// A live input sends chunks all the time, even in a quiet room. They
/// are just chunks of near-zero. So no chunks at all means Windows
/// opened the input and nothing is flowing, which happens when another
/// program is holding the cable. The app would otherwise sit there
/// looking ready and hearing nothing.
class SilenceWatch {
  /// One empty look can be bad luck: the input may have opened a moment
  /// before the look. Two in a row is a dead input.
  static const looksBeforeReopen = 2;

  var _heardSinceLook = false;
  var _emptyLooks = 0;
  var _silent = false;

  /// True from the first reopen until sound arrives again.
  bool get silent => _silent;

  /// A chunk of sound arrived.
  void heard() => _heardSinceLook = true;

  /// Called at each regular look. [open] is whether an input is meant
  /// to be sending sound. Returns true when it is time to reopen it.
  bool look({required bool open}) {
    final empty = open && !_heardSinceLook;
    _heardSinceLook = false;
    if (!empty) {
      _emptyLooks = 0;
      _silent = false;
      return false;
    }
    _emptyLooks++;
    if (_emptyLooks < looksBeforeReopen) return false;
    // Start the count again, so a dead input is retried at the same
    // steady pace and not on every look.
    _emptyLooks = 0;
    _silent = true;
    return true;
  }
}
