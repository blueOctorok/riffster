import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/guitar_ear.dart';
import '../audio/pitch.dart';
import '../data/demo_song.dart';
import '../import/guitar_pro_reader.dart';
import '../import/open_guitar_pro.dart';
import '../models/fretting_finger.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';
import '../music/chord_catalog.dart';
import '../music/chord_lane.dart';
import '../music/score_note.dart';
import '../theme/neck_theme.dart';
import '../widgets/chord_lane_bar.dart';
import '../widgets/chord_palette.dart';
import '../widgets/chord_picker.dart';
import '../widgets/finger_colors.dart';
import '../widgets/sideways_tab.dart';

/// The practice screen. It scrolls the loaded song, or one chord from the course.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  final _reader = GuitarProReader();
  late final Ticker _ticker;
  TabSong _song = demoSong;
  Duration _position = Duration.zero;

  /// The chord grid. The lane is an ordinary song, so the staff and the
  /// scorer do not learn a second kind of note.
  var _chords = false;
  var _loop = false;

  /// Which page of the chord book is open. Remembered while the window
  /// is open, so leaving and coming back does not dump you on Open.
  var _group = ChordGroup.open;
  var _section = '';
  final _lane = <LaneChord>[];
  TabSong _built = songFromLane(const []);

  /// The song's place, kept while the course is open so Song can return there.
  Duration _songPosition = Duration.zero;

  /// Where the song was when Play was pressed. The ticker itself restarts at zero.
  Duration _resumeFrom = Duration.zero;
  bool _playing = false;
  bool _opening = false;

  /// Play was running when the slider was grabbed, so letting go continues
  /// from the new spot instead of from where the ticker had been.
  bool _resumeAfterScrub = false;

  /// Ebony is the dark board the app opened with. Maple and rosewood
  /// only change the wood under the same notes.
  NeckTheme _neck = ebonyNeck;

  final _ear = GuitarEar();
  Timer? _guitarWatch;
  final _marks = <TabNote, ScoreMark>{};
  String? _heard;
  String? _inputName;
  String? _irigSpeaker;
  List<String> _inputs = const [];
  var _inputIsGuitar = false;
  var _exclusive = false;
  var _latencyMs = inputLatencyMs;
  var _looking = false;
  var _speakerReady = false;
  var _speakerOn = false;

  /// Full is the monitor level that sounded right. Lower turns only the
  /// speaker copy down. The pitch copy stays at the raw cable level.
  var _volume = 1.0;
  var _level = 0.0;
  ScoreMark? _mark;
  var _earFailed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    // Widget tests must not open the microphone or the speaker.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _ear.onPitch = _onGuitar;
    _ear.onLevel = _onLevel;
    _ear.onReady = _onReady;
    _ear.start().catchError((Object _) {
      if (mounted) setState(() => _earFailed = true);
    });
    // A cable plugged in after the window opens is invisible until we ask
    // Windows again. The first list is taken at startup.
    _guitarWatch = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _inputIsGuitar || _looking) return;
      _ear.lookForGuitar();
    });
  }

  @override
  void dispose() {
    _guitarWatch?.cancel();
    _ticker.dispose();
    _reader.dispose();
    _ear.dispose();
    super.dispose();
  }

  /// The song, the course step, or the lane being built.
  TabSong get _active {
    if (_chords) return _built;
    return _song;
  }

  void _onTick(Duration elapsed) {
    final position = _resumeFrom + elapsed;
    final end = Duration(milliseconds: _active.lengthMs + 800);
    final at = position.inMilliseconds;
    // Restart the ticker. Its elapsed time does not rewind on its own,
    // and the lead-in stays so the first chord comes in with a warning.
    if (_loop &&
        _chords &&
        _active.lengthMs > 0 &&
        position >= Duration(milliseconds: _active.lengthMs)) {
      _marks.clear();
      _resumeFrom = Duration.zero;
      _ticker.stop();
      _ticker.start();
      setState(() {
        _position = Duration.zero;
        _playing = true;
        _mark = null;
      });
      return;
    }
    if (position >= end) {
      _ticker.stop();
      expireUnplayed(_marks, _active.notes, at);
      setState(() {
        _position = end;
        _playing = false;
      });
      return;
    }
    expireUnplayed(_marks, _active.notes, at);
    setState(() => _position = position);
  }

  void _scrubStarted() {
    _resumeAfterScrub = _playing;
    if (_playing) _ticker.stop();
  }

  void _scrubTo(double milliseconds) {
    final length = _active.lengthMs;
    final next = milliseconds.round().clamp(0, length).toInt();
    // Notes from here forward can be played again.
    _marks.removeWhere((note, _) => note.timeMs >= next);
    setState(() => _position = Duration(milliseconds: next));
  }

  void _scrubEnded(double milliseconds) {
    _scrubTo(milliseconds);
    if (!_resumeAfterScrub) return;
    _resumeFrom = _position;
    _ticker.start();
    _resumeAfterScrub = false;
  }

  void _toggle() {
    if (_playing) {
      _ticker.stop();
      setState(() => _playing = false);
      return;
    }
    final end = Duration(milliseconds: _active.lengthMs);
    if (_position >= end) {
      _position = Duration.zero;
      _marks.clear();
    }
    _resumeFrom = _position;
    expireUnplayed(_marks, _active.notes, _position.inMilliseconds);
    _ticker.start();
    setState(() => _playing = true);
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final song = await openGuitarPro(context, _reader);
      if (!mounted || song == null) return;
      _ticker.stop();
      setState(() {
        _song = song;
        _chords = false;
        _position = Duration.zero;
        _songPosition = Duration.zero;
        _resumeFrom = Duration.zero;
        _playing = false;
        _marks.clear();
        _mark = null;
      });
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        FormatException(:final message) => message,
        StateError(:final message) => message,
        _ => 'Could not read that file.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _enterChords() {
    _ticker.stop();
    setState(() {
      if (!_chords) _songPosition = _position;
      _chords = true;
      _position = Duration.zero;
      _resumeFrom = Duration.zero;
      _playing = false;
      _marks.clear();
      _mark = null;
    });
  }

  void _leaveChords() {
    _ticker.stop();
    setState(() {
      _chords = false;
      _position = _songPosition;
      _resumeFrom = _songPosition;
      _playing = false;
      _marks.clear();
      _mark = null;
    });
  }

  void _acceptLane(LaneDrag drag, int index) {
    setState(() {
      final block = drag.block;
      if (block != null) {
        _lane.insert(index, LaneChord(block));
      } else {
        final from = drag.from;
        if (from == null || from == index || from + 1 == index) return;
        final placed = _lane.removeAt(from);
        final at = index > from ? index - 1 : index;
        _lane.insert(at, placed);
      }
      _built = songFromLane(_lane);
      _marks.clear();
    });
  }

  void _setLaneDuration(int index, int durationMs) {
    setState(() {
      _lane[index].durationMs = durationMs;
      _built = songFromLane(_lane);
      _marks.clear();
    });
  }

  void _removeLane(int index) {
    _ticker.stop();
    setState(() {
      _lane.removeAt(index);
      _built = songFromLane(_lane);
      _position = Duration.zero;
      _resumeFrom = Duration.zero;
      _playing = false;
      _marks.clear();
      _mark = null;
    });
  }

  void _onReady(HeardInput status) {
    if (!mounted) return;
    setState(() {
      _inputName = status.name;
      _inputs = status.inputs;
      _irigSpeaker = status.irigSpeaker;
      _inputIsGuitar = status.isGuitar;
      _exclusive = status.exclusive;
      _latencyMs = status.latencyMs;
      _speakerReady = status.speakerReady;
      _speakerOn = status.isGuitar && status.speakerReady;
    });
  }

  Future<void> _lookAgain() async {
    if (_looking) return;
    setState(() {
      _looking = true;
      _earFailed = false;
      _heard = null;
      _mark = null;
    });
    try {
      await _ear.restart();
    } catch (_) {
      if (mounted) setState(() => _earFailed = true);
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  void _onLevel(double level) {
    if (!mounted) return;
    setState(() => _level = level);
  }

  void _onGuitar(int midi) {
    if (!mounted) return;
    // The buffer is late. Judge the moment the string was plucked.
    final playedAt = _position.inMilliseconds - _latencyMs;
    ScoreMark? mark;
    if (_playing) {
      final written = notesNear(_active.notes, playedAt);
      mark = scoreMoment(
        written: written,
        playedAtMs: playedAt,
        playedMidi: midi,
      );
      applyPlayedMark(_marks, written, mark);
    }
    setState(() {
      _heard = pitchName(midi);
      _mark = mark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final clock = _clockLabel(_position);
    final songClock = _clockLabel(Duration(milliseconds: active.lengthMs));
    final onChords = _chords;
    // The staff has a fixed height. Stretching it made the strings
    // far apart, which is the opposite of a tab you can read.
    final staff = SizedBox(
      height: SidewaysTab.height,
      child: DragTarget<LaneDrag>(
        onAcceptWithDetails: (details) {
          if (!_chords) return;
          _acceptLane(details.data, _lane.length);
        },
        builder: (context, candidate, _) {
          return DecoratedBox(
            key: const Key('staff'),
            decoration: BoxDecoration(
              color: _neck.wood,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: _chords && candidate.isNotEmpty
                  ? Border.all(color: const Color(0xFFE4B15A), width: 2)
                  : null,
            ),
            child: SidewaysTab(
              song: active,
              position: _position,
              neck: _neck,
              marks: Map<TabNote, ScoreMark>.of(_marks),
            ),
          );
        },
      ),
    );
    final positionSlider = Slider(
      key: const Key('position'),
      value: _position.inMilliseconds.clamp(0, active.lengthMs).toDouble(),
      max: active.lengthMs <= 0 ? 1 : active.lengthMs.toDouble(),
      activeColor: const Color(0xFFE4B15A),
      inactiveColor: const Color(0xFF3A342C),
      onChangeStart: (_) => _scrubStarted(),
      onChanged: _opening ? null : _scrubTo,
      onChangeEnd: _scrubEnded,
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riffster',
              style: TextStyle(fontSize: 14, letterSpacing: 0.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: Text(
                    active.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${active.tempoBpm} bpm',
                  style: const TextStyle(color: Color(0xFF8A8175)),
                ),
                const Spacer(),
                Text(
                  '$clock / $songClock',
                  style: const TextStyle(color: Color(0xFF8A8175)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _opening ? null : _open,
                  child: Text(_opening ? 'Opening…' : 'Open'),
                ),
                const SizedBox(width: 8),
                onChords
                    ? FilledButton(
                        onPressed: _enterChords,
                        child: const Text('Chords'),
                      )
                    : OutlinedButton(
                        onPressed: _opening ? null : _enterChords,
                        child: const Text('Chords'),
                      ),
                if (onChords) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _leaveChords,
                    child: const Text('Song'),
                  ),
                  const SizedBox(width: 8),
                  _loop
                      ? FilledButton(
                          onPressed: () => setState(() => _loop = false),
                          child: const Text('Looping'),
                        )
                      : OutlinedButton(
                          onPressed: () => setState(() => _loop = true),
                          child: const Text('Loop'),
                        ),
                ],
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _opening || (onChords && _lane.isEmpty)
                      ? null
                      : _toggle,
                  child: Text(_playing ? 'Pause' : 'Play'),
                ),
              ],
            ),
            if (!onChords) ...[
              const SizedBox(height: 14),
              const _FingerLegend(),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    _listenLabel,
                    style: TextStyle(color: _listenColor),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _looking || (_inputName == null && !_earFailed)
                      ? null
                      : _lookAgain,
                  child: Text(_looking ? 'Looking…' : 'Look again'),
                ),
                _LevelMeter(level: _level),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      key: const Key('volume'),
                      value: _volume,
                      activeColor: const Color(0xFFE4B15A),
                      inactiveColor: const Color(0xFF3A342C),
                      onChanged: _speakerReady && _inputIsGuitar
                          ? (value) {
                              setState(() => _volume = value);
                              _ear.volume = value;
                            }
                          : null,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _speakerReady && _inputIsGuitar
                      ? () {
                          setState(() => _speakerOn = !_speakerOn);
                          _ear.speakerOn = _speakerOn;
                        }
                      : null,
                  child: Text(
                    _speakerOn && _speakerReady ? 'Speaker on' : 'Speaker off',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (onChords) ...[
              const SizedBox(height: 8),
              ChordPicker(
                group: _group,
                section: _section,
                onGroup: (group) => setState(() {
                  _group = group;
                  _section = '';
                }),
                onSection: (section) => setState(() => _section = section),
              ),
              const SizedBox(height: 8),
              const Text(
                'X muted · O open · 1 index, 2 middle, 3 ring, 4 pinky',
                style: TextStyle(color: Color(0xFF8A8175), fontSize: 12),
              ),
              const SizedBox(height: 8),
              ChordPalette(
                blocks: blocksIn(_group, activeSection(_group, _section)),
              ),
              const SizedBox(height: 10),
              ChordLaneBar(
                lane: _lane,
                onDrop: _acceptLane,
                onDuration: _setLaneDuration,
                onRemove: _removeLane,
              ),
              const SizedBox(height: 8),
              staff,
              const SizedBox(height: 8),
              positionSlider,
            ] else ...[
              _NeckPicker(
                selected: _neck,
                onSelected: (neck) => setState(() => _neck = neck),
              ),
              const SizedBox(height: 8),
              staff,
              const SizedBox(height: 8),
              positionSlider,
            ],
          ],
        ),
      ),
    );
  }

  String get _listenLabel {
    if (_earFailed) {
      return 'No guitar input. Plug in the Rocksmith cable, then press Look again.';
    }
    final where = _inputName == null
        ? 'Listening'
        : (_inputIsGuitar
              ? (_exclusive ? '$_inputName · exclusive' : _inputName!)
              : _irigSpeaker != null
              ? '$_irigSpeaker is connected. Windows did not start the guitar input. Plug in the Rocksmith cable, then press Look again.'
              : 'Plug in the Rocksmith cable. It can be plugged in after the app is open. Hearing $_inputName until then. Inputs: ${_inputs.isEmpty ? 'none' : _inputs.join(', ')}');
    if (_heard == null) return where;
    if (_mark == null) return '$where · $_heard';
    return '$where · $_heard · ${_markLabel(_mark!)}';
  }

  Color get _listenColor {
    return switch (_mark) {
      ScoreMark.hit => const Color(0xFF3DDC6E),
      ScoreMark.early || ScoreMark.late => const Color(0xFFE4B15A),
      ScoreMark.miss => const Color(0xFFE85D75),
      null => const Color(0xFF8A8175),
    };
  }
}

String _markLabel(ScoreMark mark) {
  return switch (mark) {
    ScoreMark.hit => 'Hit',
    ScoreMark.miss => 'Miss',
    ScoreMark.early => 'Early',
    ScoreMark.late => 'Late',
  };
}

String _clockLabel(Duration position) {
  final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${position.inMinutes}:$seconds';
}

class _NeckPicker extends StatelessWidget {
  const _NeckPicker({required this.selected, required this.onSelected});

  final NeckTheme selected;
  final ValueChanged<NeckTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final neck in neckThemes) ...[
          neck == selected
              ? FilledButton(
                  onPressed: () => onSelected(neck),
                  child: Text(neck.name),
                )
              : OutlinedButton(
                  onPressed: () => onSelected(neck),
                  child: Text(neck.name),
                ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// A short bar that jumps when the guitar sends a signal.
///
/// A real pluck is often only a fifth of full scale, so the bar treats
/// 0.2 as full. Quiet noise stays a sliver. A dead bar means this input
/// is not hearing the strings.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final filled = (level / 0.2).clamp(0.0, 1.0);
    return SizedBox(
      width: 96,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF3A342C),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: filled,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: filled > 0.85
                    ? const Color(0xFFE85D75)
                    : const Color(0xFF3DDC6E),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FingerLegend extends StatelessWidget {
  const _FingerLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final finger in FrettingFinger.values) ...[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: fingerColor[finger],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            fingerLabel[finger]!,
            style: const TextStyle(color: Color(0xFF8A8175), fontSize: 13),
          ),
          const SizedBox(width: 16),
        ],
      ],
    );
  }
}
