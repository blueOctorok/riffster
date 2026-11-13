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
import '../widgets/practice/feedback_strip.dart';
import '../widgets/practice/run_summary_card.dart';
import '../widgets/practice/timing_check_dialog.dart';
import '../widgets/practice/transport_dock.dart';
import '../widgets/room.dart';
import '../widgets/shell/app_area.dart';
import '../widgets/shell/input_panel.dart';
import '../widgets/shell/input_status.dart';
import '../widgets/shell/side_rail.dart';
import '../widgets/stage/stage_view.dart';
import 'home_area.dart';

/// The frame around every area of the app: the rail down the left, the
/// area you are in beside it, and the input panel that slides over it.
///
/// The shell owns the things with a lifetime: the two runs, the frame
/// timer, and the audio input. They outlive any one area, so a song
/// keeps its place while you look at Home, and the input stays open
/// wherever you are. The shell hands them to widgets that listen for
/// themselves, so a frame of animation or a jump of the level meter
/// never rebuilds the whole window.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final SettingsStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
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

  var _area = AppArea.home;
  var _inputOpen = false;

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

  /// True while the open input is sending no sound at all.
  var _inputSilent = false;
  var _speakerOn = false;

  /// Full is the monitor level that sounded right. Lower turns only the
  /// speaker copy down. The pitch copy stays at the raw cable level.
  var _volume = 1.0;
  final _level = ValueNotifier(0.0);

  /// The pitch that is ringing, for the tuner. Null when nothing is.
  final _tone = ValueNotifier<double?>(null);

  /// Build is the chord book, and it plays the lane. Every other area
  /// plays the song.
  bool get _building => _area == AppArea.build;
  PracticeRun get _run => _building ? _laneRun : _songRun;
  SettingsStore get _store => widget.store;

  /// Home has no stage, so nothing there can be played or looped.
  bool get _onStage => _area != AppArea.home;

  bool get _canPlay {
    return _onStage && !_opening && _run.timeline.moments.isNotEmpty;
  }

  InputStatus get _inputStatus {
    return InputStatus(
      input: _input,
      failed: _earFailed,
      silent: _inputSilent,
      looking: _looking,
    );
  }

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
    _ear.onTone = (hertz) => _tone.value = hertz;
    _ear.onReady = _onReady;
    _ear.onSilent = (silent) {
      if (mounted) setState(() => _inputSilent = silent);
    };
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
    _tone.dispose();
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

  /// Moves to [area]. Whatever was playing is paused where it stands,
  /// and is still there when you come back.
  void _go(AppArea area) {
    if (area == _area) return;
    _run.pause();
    setState(() {
      _area = area;
      _inputOpen = false;
    });
    // [_run] is now the run of the new area.
    _syncTicker();
    _ear.instrument = _run.song.instrument;
  }

  /// Puts [song] on the stage. It does not change which area is open.
  void _loadSong(TabSong song) {
    _songRun.load(song);
    setState(() {
      _loopFromBar = 0;
      _loopToBar = null;
    });
    _syncTicker();
    _ear.instrument = _run.song.instrument;
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final song = await openGuitarPro(context, _reader);
      if (mounted && song != null) {
        _loadSong(song);
        _go(AppArea.songs);
      }
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

  void _chooseInstrument(Instrument instrument) {
    _store.instrument = instrument;
    _loadSong(warmUpFor(instrument));
    // The chord book is guitar shapes, so a switch to bass while it is
    // open has nowhere to stay.
    if (!_area.readyFor(instrument)) _go(AppArea.songs);
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
    final status = _inputStatus;
    return Scaffold(
      body: Room(
        child: CallbackShortcuts(
          // Home has no stage, so there is nothing for the keys to do.
          bindings: _onStage ? _keys : const {},
          child: Focus(
            autofocus: true,
            child: Row(
              children: [
                SideRail(
                  area: _area,
                  onArea: _go,
                  instrument: _songRun.song.instrument,
                  onInstrument: _chooseInstrument,
                  status: status,
                  level: _level,
                  inputOpen: _inputOpen,
                  onInput: () => setState(() => _inputOpen = !_inputOpen),
                  clipStarted: _clips?.started,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // The area leaving and the area arriving are both
                      // on screen for a moment, one fading out as the
                      // other fades in. The key is how the switcher
                      // knows a different area has been asked for.
                      AnimatedSwitcher(
                        duration: RiffMotion.settle,
                        transitionBuilder: (child, animation) {
                          return _slideIn(
                            child,
                            animation,
                            const Offset(0, 0.02),
                          );
                        },
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, ?current],
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_area),
                          child: _onStage ? _stagePage() : _home(),
                        ),
                      ),
                      if (_inputOpen)
                        // A click anywhere off the panel puts it away.
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _inputOpen = false),
                          ),
                        ),
                      Positioned(
                        left: 12,
                        top: 12,
                        bottom: 12,
                        width: InputPanel.width,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: AnimatedSwitcher(
                            duration: RiffMotion.slide,
                            transitionBuilder: (child, animation) {
                              return _slideIn(
                                child,
                                animation,
                                const Offset(-0.08, 0),
                              );
                            },
                            child: _inputOpen
                                ? _inputPanel(status)
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fades [child] in while it slides the last little way into place
  /// from [from], which is a fraction of the child's own size.
  static Widget _slideIn(
    Widget child,
    Animation<double> animation,
    Offset from,
  ) {
    final eased = CurvedAnimation(parent: animation, curve: RiffMotion.ease);
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(begin: from, end: Offset.zero).animate(eased),
        child: child,
      ),
    );
  }

  Widget _home() {
    return HomeArea(
      song: _songRun.song,
      onStage: () => _go(AppArea.songs),
      onOpenFile: _opening ? null : _open,
      onArea: _go,
    );
  }

  Widget _inputPanel(InputStatus status) {
    // The panel is taller than a small window, so it can scroll.
    return SingleChildScrollView(
      child: InputPanel(
        status: status,
        instrument: _run.song.instrument,
        level: _level,
        tone: _tone,
        volume: _volume,
        speakerOn: _speakerOn,
        onSource: (source) => _reopenInput(() => _ear.choose(source)),
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
        onClose: () => setState(() => _inputOpen = false),
        clipStarted: _clips?.started,
        onClip: _clips == null ? null : _toggleClip,
      ),
    );
  }

  /// The stage and everything around it. Songs and Build share it:
  /// Build adds the chord book above the stage and plays the lane.
  Widget _stagePage() {
    final run = _run;
    final song = run.song;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SongHeading(song: song)),
              if (!_building) ...[
                const SizedBox(width: 20),
                OutlinedButton(
                  onPressed: _opening ? null : _open,
                  child: Text(_opening ? 'Opening…' : 'Open'),
                ),
              ],
              const SizedBox(width: 20),
              FeedbackStrip(run: run),
            ],
          ),
          const SizedBox(height: 16),
          if (_building) ..._chordBook(),
          _stage(run),
          const SizedBox(height: 16),
          TransportDock(
            run: run,
            enabled: _canPlay,
            loopFromBar: _loopFromBar,
            loopToBar: _loopToBar ?? song.bars.length - 1,
            onLoop: _toggleLoop,
            onLoopBars: _setLoopBars,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const _FingerLegend(),
              const Spacer(),
              _NeckPicker(
                selected: _store.neck,
                onSelected: (neck) => setState(() => _store.neck = neck),
              ),
            ],
          ),
        ],
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
            if (_building) _acceptLane(details.data, _lane.length);
          },
          builder: (context, candidate, _) => StageView(
            key: const Key('staff'),
            run: run,
            neck: _store.neck,
            dropHighlighted: _building && candidate.isNotEmpty,
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
