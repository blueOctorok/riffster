import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/instrument.dart';
import '../music/score_note.dart';
import '../theme/neck_theme.dart';

/// The few things the app remembers between launches: which instrument
/// you play, which wood the board is, and the delay measured on each
/// input.
///
/// They live in one small JSON file in the app's own data folder. A
/// missing or damaged file is the same as a first launch, so a bad save
/// can never stop the app from opening.
class SettingsStore {
  SettingsStore._(this._file);

  /// A store that forgets when the app closes. Tests use this so they
  /// never touch the disk.
  SettingsStore.inMemory({this._instrument}) : _file = null;

  static Future<SettingsStore> open() async {
    final folder = await getApplicationSupportDirectory();
    final store = SettingsStore._(File('${folder.path}/settings.json'));
    try {
      final saved = jsonDecode(await store._file!.readAsString());
      if (saved is Map) {
        store._instrument = Instrument.values.asNameMap()[saved['instrument']];
        store._neck = neckThemes.firstWhere(
          (neck) => neck.name == saved['neck'],
          orElse: () => ebonyNeck,
        );
        store._timingFeel =
            TimingFeel.values.asNameMap()[saved['timingFeel']] ??
            TimingFeel.medium;
        final delays = saved['inputDelaysMs'];
        if (delays is Map) {
          for (final MapEntry(:key, :value) in delays.entries) {
            if (key is String && value is num) {
              store._inputDelaysMs[key] = value.toDouble();
            }
          }
        }
      }
    } on Exception {
      // No file yet, or one that cannot be read. Start fresh.
    }
    return store;
  }

  final File? _file;
  Instrument? _instrument;
  NeckTheme _neck = ebonyNeck;
  TimingFeel _timingFeel = TimingFeel.medium;
  final _inputDelaysMs = <String, double>{};

  /// Null until the first launch's question has been answered.
  Instrument? get instrument => _instrument;

  set instrument(Instrument? value) {
    _instrument = value;
    _save();
  }

  NeckTheme get neck => _neck;

  set neck(NeckTheme value) {
    _neck = value;
    _save();
  }

  TimingFeel get timingFeel => _timingFeel;

  set timingFeel(TimingFeel value) {
    _timingFeel = value;
    _save();
  }

  /// How far behind the string an input was measured to be, or null
  /// when the timing check has not been run on it. [route] names the
  /// input and the way Windows opened it.
  double? inputDelayMs(String route) => _inputDelaysMs[route];

  void setInputDelayMs(String route, double delayMs) {
    _inputDelaysMs[route] = delayMs;
    _save();
  }

  void _save() {
    final text = jsonEncode({
      'instrument': _instrument?.name,
      'neck': _neck.name,
      'timingFeel': _timingFeel.name,
      'inputDelaysMs': _inputDelaysMs,
    });
    // Nothing waits for the write. If it fails, the choice is asked
    // again next time, which is harmless.
    _file?.writeAsString(text).ignore();
  }
}
