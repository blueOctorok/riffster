import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/clip_recorder.dart';
import '../audio/guitar_ear.dart';
import '../audio/pitch.dart';
import '../data/demo_song.dart';
import '../data/settings_store.dart';
import '../import/guitar_pro_reader.dart';
import '../import/open_guitar_pro.dart';
import '../models/fretting_finger.dart';
import '../models/instrument.dart';
import '../models/tab_song.dart';
import '../music/chord_catalog.dart';
import '../music/chord_lane.dart';
import '../music/practice_run.dart';
import '../theme/neck_theme.dart';
import '../theme/riffster_theme.dart';
import '../widgets/chord_lane_bar.dart';
import '../widgets/chord_palette.dart';
import '../widgets/chord_picker.dart';
import '../widgets/finger_colors.dart';
import '../widgets/instrument_switch.dart';
import '../widgets/practice/feedback_strip.dart';
import '../widgets/practice/input_bar.dart';
import '../widgets/practice/run_summary_card.dart';
import '../widgets/practice/timing_check_dialog.dart';
import '../widgets/practice/transport_dock.dart';
import '../widgets/room.dart';
import '../widgets/stage/stage_view.dart';

/// The practice screen. It scrolls the loaded song, or the chords you
/// have dropped into the lane.
///
/// This screen owns the things with a lifetime: the two runs, the
/// frame timer, and the audio input. It hands them to widgets that
/// listen for themselves, so a frame of animation or a jump of the
/// level meter never rebuilds the screen.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.store});

  final SettingsStore store;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  final _reader = GuitarProReader();
  final _ear = GuitarEar();
  late final Ticker _ticker;

  /// The song and the chord lane each keep their own run. Leaving the
  /// song for the chord book and coming back finds its place, its
  /// marks, and its loop exactly as they were.
  late final PracticeRun _songRun;
  final _laneRun = PracticeRun(songFromLane(const []));

  /// The ticker reports time since it started. The run wants the time
  /// since the last frame, so the last reading is kept to subtract.
  var _lastTick = Duration.zero;

  /// Time since the run's clock last moved. A pluck lands between two
  /// frames, and the run only knows the time of the last one.
  final _sinceFrame = Stopwatch();

  /// The count-in beat that last clicked, so each beat clicks once.
  int? _countBeat;

  /// Null outside a debug build.
  final _clips = ClipRecorder.forThisBuild();

  var _chords = false;

  /// Which page of the chord book is open. Remembered while the window
  /// is open, so leaving and coming back does not dump you on Open.
  var _group = ChordGroup.open;
  var _section = '';
  final _lane = <LaneChord>[];
  var _opening = false;

  /// The bars the song's loop covers, counted from zero. A null end
  /// means the last bar, whatever song is loaded.
  var _loopFromBar = 0;
  int? _loopToBar;

  Timer? _guitarWatch;
  HeardInput? _input;
  var _looking = false;
  var _earFailed = false;
  var _speakerOn = false;

  /// Full is the monitor level that sounded right. Lower turns only the
  /// speaker copy down. The pitch copy stays at the raw cable level.
  var _volume = 1.0;
  final _level = ValueNotifier(0.0);

  PracticeRun get _run => _chords ? _laneRun : _songRun;
  SettingsStore get _store => widget.store;

  bool get _canPlay => !_opening && _run.timeline.moments.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _songRun = PracticeRun(warmUpFor(_store.instrument ?? Instrument.bass));
    _ticker = createTicker(_onTick);
    _songRun.addListener(_syncTicker);
    _laneRun.addListener(_syncTicker);
    // Widget tests must not open the microphone or the speaker.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _ear.instrument = _run.song.instrument;
    _ear.onPluck = _onPluck;
    _ear.onSound = _clips?.add;
    _ear.onLevel = (level) => _level.value = level;
    _ear.onReady = _onReady;
    _ear.start().catchError((Object _) {
      if (mounted) setState(() => _earFailed = true);
    });
    // A cable plugged in after the window opens is invisible until we ask
    // Windows again. The first list is taken at startup.
    _guitarWatch = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _looking) return;
      _ear.lookForGuitar();
    });
  }

  @override
  void dispose() {
    _guitarWatch?.cancel();
    _ticker.dispose();
    _songRun.dispose();
    _laneRun.dispose();
    _level.dispose();
    _reader.dispose();
    _ear.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final step = elapsed - _lastTick;
    _lastTick = elapsed;
    _sinceFrame
      ..reset()
      ..start();
    _run.advance(step);
    _clickOnCountBeat();
  }

  /// The frame timer runs only while something is moving. A still
  /// stage costs nothing, which matters on a laptop battery.
  void _syncTicker() {
    final wanted = _run.needsFrames;
    if (wanted == _ticker.isActive) return;
    if (wanted) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  /// The delay the timing check found on the open input, if it has
  /// been run there.
  double? get _measuredDelayMs {
    final route = _input?.route;
    return route == null ? null : _store.inputDelayMs(route);
  }

  void _onPluck(int? midi, double agoMs) {
    if (!mounted) return;
    // Three delays, all in real milliseconds. The cable and Windows
    // hold the sound for a while: measured by the timing check, or
    // else guessed. The detector then took [agoMs] to name the note.
    // Against those, the run's clock stopped at the last frame, so
    // that much of the delay has not happened yet as far as the run
    // knows.
    final cableMs =
        _measuredDelayMs ?? _input?.latencyMs.toDouble() ?? inputLatencyMs;
    final sinceFrameMs = _sinceFrame.elapsedMicroseconds / 1000;
    _run.pluck(midi, latencyMs: cableMs + agoMs - sinceFrameMs);
  }

  /// Ticks once on each beat of the count-in, higher on the first.
  void _clickOnCountBeat() {
    // Null whenever nothing is being counted, so a count that starts
    // over clicks its first beat again.
    final beat = _run.countIn?.beatAt(_run.positionMs).floor();
    final counted = beat != null && beat >= 0 && beat < CountIn.beats;
    if (counted && beat != _countBeat) _ear.click(accent: beat == 0);
    _countBeat = beat;
  }

  Future<void> _checkTiming() async {
    final route = _input?.route;
    if (route == null) return;
    _run.pause();
    final delayMs = await showTimingCheck(context, _ear);
    if (delayMs == null || !mounted) return;
    setState(() => _store.setInputDelayMs(route, delayMs));
  }

  /// Starts a clip, or saves the one being recorded with the notes on
  /// the stage as its answer.
  Future<void> _toggleClip() async {
    final clips = _clips!;
    if (!clips.recording) {
      setState(clips.start);
      return;
    }
    final song = _run.song;
    final stamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final path = await clips.save(
      name: '${song.instrument.name}-$stamp',
      sampleRate: _ear.sampleRate,
      notes: [
        for (final moment in _run.timeline.moments)
          // A chord has no one pitch to check, so it is a wildcard.
          moment.notes.length == 1 ? pitchName(moment.notes.first.midi) : '?',
      ],
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $path with the notes beside it.')),
    );
  }

  void _onReady(HeardInput status) {
    if (!mounted) return;
    setState(() {
      _input = status;
      _speakerOn = status.isGuitar && status.speakerReady;
    });
  }

  /// Runs something that closes and reopens the input, and shows
  /// "Looking…" while it does.
  Future<void> _reopenInput(Future<void> Function() reopen) async {
    if (_looking) return;
    setState(() {
      _looking = true;
      _earFailed = false;
    });
    try {
      await reopen();
    } catch (_) {
      if (mounted) setState(() => _earFailed = true);
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  /// Puts [song] on the stage and leaves the chord book.
  void _showSong(TabSong song) {
    _laneRun.pause();
    _songRun.load(song);
    setState(() {
      _chords = false;
      _loopFromBar = 0;
      _loopToBar = null;
    });
    _syncTicker();
    _ear.instrument = song.instrument;
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final song = await openGuitarPro(context, _reader);
      if (mounted && song != null) _showSong(song);
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        FormatException(:final message) => message,
        StateError(:final message) => message,
        _ => 'Could not read that file.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _chooseInstrument(Instrument instrument) {
    _store.instrument = instrument;
    _showSong(warmUpFor(instrument));
  }

  /// Swaps between the song and the chord book. Whichever is left
  /// behind is paused where it stands.
  void _setChords(bool chords) {
    _run.pause();
    setState(() => _chords = chords);
    _syncTicker();
    _ear.instrument = _run.song.instrument;
  }

  void _toggleLoop() {
    if (_canPlay) _run.loop = _run.loop == null ? _loopRange() : null;
  }

  void _setLoopBars(int fromBar, int toBar) {
    setState(() {
      _loopFromBar = fromBar;
      _loopToBar = toBar;
    });
    _run.loop = _loopRange();
  }

  /// The stretch that repeats. A song with bar lines loops whole bars,
  /// so every pass stays in time. The chord lane has no bars and loops
  /// from its start to its end.
  LoopRange? _loopRange() {
    final song = _run.song;
    if (song.lengthMs <= 0) return null;
    final bars = song.bars;
    if (bars.isEmpty) return LoopRange(0, song.lengthMs);
    return LoopRange(
      bars[_loopFromBar].startMs,
      bars[_loopToBar ?? bars.length - 1].endMs,
    );
  }

  /// The lane changed, so its song is built again. [keepPlace] leaves
  /// the playhead where it is, so a chord can be dropped mid-loop.
  void _rebuildLane({required bool keepPlace}) {
    final wasLooping = _laneRun.loop != null;
    _laneRun.load(songFromLane(_lane), keepPlace: keepPlace);
    // Loading clears the loop, and the lane's length has changed anyway.
    if (wasLooping) _laneRun.loop = _loopRange();
    setState(() {});
  }

  void _acceptLane(LaneDrag drag, int index) {
    final block = drag.block;
    if (block != null) {
      _lane.insert(index, LaneChord(block));
    } else {
      final from = drag.from;
      if (from == null || from == index || from + 1 == index) return;
      final placed = _lane.removeAt(from);
      _lane.insert(index > from ? index - 1 : index, placed);
    }
    _rebuildLane(keepPlace: true);
  }

  void _setLaneDuration(int index, int durationMs) {
    _lane[index].durationMs = durationMs;
    _rebuildLane(keepPlace: true);
  }

  void _removeLane(int index) {
    _lane.removeAt(index);
    _rebuildLane(keepPlace: false);
  }

  /// The keys that work anywhere on the screen. Wrapping the screen in
  /// these also stops Space from "pressing" whichever button was
  /// clicked last, which is what Space does by default.
  Map<ShortcutActivator, VoidCallback> get _keys {
    void play() {
      if (_canPlay) _run.toggle();
    }

    void restart() {
      if (_canPlay) _run.restart();
    }

    void slower() => _run.nudgeSpeed(-1);
    void faster() => _run.nudgeSpeed(1);
    return {
      const SingleActivator(LogicalKeyboardKey.space): play,
      const SingleActivator(LogicalKeyboardKey.keyR): restart,
      const SingleActivator(LogicalKeyboardKey.keyL): _toggleLoop,
      const SingleActivator(LogicalKeyboardKey.minus): slower,
      const SingleActivator(LogicalKeyboardKey.numpadSubtract): slower,
      // Plus is Shift and the equals key. Either way means faster.
      const SingleActivator(LogicalKeyboardKey.equal): faster,
      const SingleActivator(LogicalKeyboardKey.equal, shift: true): faster,
      const SingleActivator(LogicalKeyboardKey.numpadAdd): faster,
    };
  }

  @override
  Widget build(BuildContext context) {
    final run = _run;
    final song = run.song;
    final bars = song.bars;
    return Scaffold(
      body: Room(
        child: CallbackShortcuts(
          bindings: _keys,
          child: Focus(
            autofocus: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    instrument: _songRun.song.instrument,
                    onInstrument: _chooseInstrument,
                    opening: _opening,
                    onOpen: _open,
                    chords: _chords,
                    onChords: _setChords,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _SongHeading(song: song)),
                      const SizedBox(width: 20),
                      FeedbackStrip(run: run),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_chords) ..._chordBook(),
                  _stage(run),
                  const SizedBox(height: 16),
                  TransportDock(
                    run: run,
                    enabled: _canPlay,
                    loopFromBar: _loopFromBar,
                    loopToBar: _loopToBar ?? bars.length - 1,
                    onLoop: _toggleLoop,
                    onLoopBars: _setLoopBars,
                  ),
                  const SizedBox(height: 10),
                  InputBar(
                    input: _input,
                    failed: _earFailed,
                    looking: _looking,
                    level: _level,
                    volume: _volume,
                    speakerOn: _speakerOn,
                    onSource: (source) {
                      _reopenInput(() => _ear.choose(source));
                    },
                    onLookAgain: () => _reopenInput(_ear.restart),
                    onVolume: (volume) {
                      setState(() => _volume = volume);
                      _ear.volume = volume;
                    },
                    onSpeaker: (on) {
                      setState(() => _speakerOn = on);
                      _ear.speakerOn = on;
                    },
                    measuredDelayMs: _measuredDelayMs,
                    onTimingCheck: _checkTiming,
                    clipRecording: _clips?.recording ?? false,
                    onClip: _clips == null ? null : _toggleClip,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const _FingerLegend(),
                      const Spacer(),
                      _NeckPicker(
                        selected: _store.neck,
                        onSelected: (neck) {
                          setState(() => _store.neck = neck);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _chordBook() {
    return [
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
        style: RiffText.label,
      ),
      const SizedBox(height: 8),
      ChordPalette(blocks: blocksIn(_group, activeSection(_group, _section))),
      const SizedBox(height: 10),
      ChordLaneBar(
        lane: _lane,
        onDrop: _acceptLane,
        onDuration: _setLaneDuration,
        onRemove: _removeLane,
      ),
      const SizedBox(height: 14),
    ];
  }

  /// The stage, with the end-of-run card over its right side. The card
  /// stays off the left, where the last notes you played still show.
  Widget _stage(PracticeRun run) {
    return Stack(
      children: [
        DragTarget<LaneDrag>(
          onAcceptWithDetails: (details) {
            if (_chords) _acceptLane(details.data, _lane.length);
          },
          builder: (context, candidate, _) => StageView(
            key: const Key('staff'),
            run: run,
            neck: _store.neck,
            dropHighlighted: _chords && candidate.isNotEmpty,
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 28,
          child: Center(child: RunSummaryCard(run: run)),
        ),
      ],
    );
  }
}

/// The wordmark, the instrument, and the buttons that change what is
/// on the stage.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.instrument,
    required this.onInstrument,
    required this.opening,
    required this.onOpen,
    required this.chords,
    required this.onChords,
  });

  final Instrument instrument;
  final ValueChanged<Instrument> onInstrument;
  final bool opening;
  final VoidCallback onOpen;
  final bool chords;
  final ValueChanged<bool> onChords;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Riffster', style: RiffText.wordmark),
        const SizedBox(width: 22),
        InstrumentSwitch(selected: instrument, onSelected: onInstrument),
        const Spacer(),
        OutlinedButton(
          onPressed: opening ? null : onOpen,
          child: Text(opening ? 'Opening…' : 'Open'),
        ),
        // The chord book is guitar shapes. A bass gets its own way to
        // build a line in a later stage.
        if (instrument == Instrument.guitar) ...[
          const SizedBox(width: 8),
          chords
              ? FilledButton(
                  onPressed: () => onChords(true),
                  child: const Text('Chords'),
                )
              : OutlinedButton(
                  onPressed: opening ? null : () => onChords(true),
                  child: const Text('Chords'),
                ),
        ],
        if (chords) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => onChords(false),
            child: const Text('Song'),
          ),
        ],
      ],
    );
  }
}

class _SongHeading extends StatelessWidget {
  const _SongHeading({required this.song});

  final TabSong song;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: RiffText.title,
        ),
        const SizedBox(height: 4),
        Text(
          '${song.tempoBpm} bpm · ${song.instrument.label}',
          style: RiffText.label,
        ),
      ],
    );
  }
}

/// The three woods. Each chip shows a dot of its own board.
class _NeckPicker extends StatelessWidget {
  const _NeckPicker({required this.selected, required this.onSelected});

  final NeckTheme selected;
  final ValueChanged<NeckTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final neck in neckThemes)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: TextButton.icon(
              onPressed: () => onSelected(neck),
              style: TextButton.styleFrom(
                foregroundColor: neck == selected
                    ? RiffColors.cream
                    : RiffColors.quiet,
                backgroundColor: neck == selected ? RiffColors.panelLit : null,
                side: BorderSide(
                  color: neck == selected
                      ? RiffColors.gold
                      : const Color(0x00000000),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: DecoratedBox(
                decoration: BoxDecoration(
                  color: neck.wood,
                  shape: BoxShape.circle,
                  border: Border.all(color: RiffColors.lineStrong),
                ),
                child: const SizedBox.square(dimension: 14),
              ),
              label: Text(neck.name),
            ),
          ),
      ],
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: fingerColor[finger],
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: 12),
          ),
          const SizedBox(width: 6),
          Text(fingerLabel[finger]!, style: RiffText.label),
          const SizedBox(width: 16),
        ],
      ],
    );
  }
}
