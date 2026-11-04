import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/demo_song.dart';
import '../import/guitar_pro_reader.dart';
import '../import/open_guitar_pro.dart';
import '../models/fretting_finger.dart';
import '../models/tab_song.dart';
import '../music/chord_course.dart';
import '../theme/neck_theme.dart';
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

  /// Null while a song is on screen. A number is the chord-course step.
  int? _courseIndex;

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

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _reader.dispose();
    super.dispose();
  }

  /// The song, or the current chord-course step.
  TabSong get _active =>
      _courseIndex == null ? _song : chordCourse[_courseIndex!];

  void _onTick(Duration elapsed) {
    final position = _resumeFrom + elapsed;
    final end = Duration(milliseconds: _active.lengthMs + 800);
    if (position >= end) {
      _ticker.stop();
      setState(() {
        _position = end;
        _playing = false;
      });
      return;
    }
    setState(() => _position = position);
  }

  void _scrubStarted() {
    _resumeAfterScrub = _playing;
    if (_playing) _ticker.stop();
  }

  void _scrubTo(double milliseconds) {
    final length = _active.lengthMs;
    final next = milliseconds.round().clamp(0, length).toInt();
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
    }
    _resumeFrom = _position;
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
        _courseIndex = null;
        _position = Duration.zero;
        _songPosition = Duration.zero;
        _resumeFrom = Duration.zero;
        _playing = false;
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

  void _enterCourse() {
    _ticker.stop();
    setState(() {
      _songPosition = _position;
      _courseIndex = 0;
      _position = Duration.zero;
      _resumeFrom = Duration.zero;
      _playing = false;
    });
  }

  void _leaveCourse() {
    _ticker.stop();
    setState(() {
      _courseIndex = null;
      _position = _songPosition;
      _resumeFrom = _songPosition;
      _playing = false;
    });
  }

  void _step(int delta) {
    final next = (_courseIndex! + delta).clamp(0, chordCourse.length - 1);
    _ticker.stop();
    setState(() {
      _courseIndex = next;
      _position = Duration.zero;
      _resumeFrom = Duration.zero;
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final clock = _clockLabel(_position);
    final songClock = _clockLabel(Duration(milliseconds: active.lengthMs));
    final onCourse = _courseIndex != null;

    return Scaffold(
      body: Padding(
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
                if (onCourse) ...[
                  const SizedBox(width: 16),
                  Text(
                    '${_courseIndex! + 1} / ${chordCourse.length}',
                    style: const TextStyle(color: Color(0xFF8A8175)),
                  ),
                ],
                const Spacer(),
                Text(
                  '$clock / $songClock',
                  style: const TextStyle(color: Color(0xFF8A8175)),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _opening ? null : _open,
                  child: Text(_opening ? 'Opening…' : 'Open'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _opening
                      ? null
                      : (onCourse ? _leaveCourse : _enterCourse),
                  child: Text(onCourse ? 'Song' : 'Chords'),
                ),
                if (onCourse) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _courseIndex == 0 ? null : () => _step(-1),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _courseIndex == chordCourse.length - 1
                        ? null
                        : () => _step(1),
                    child: const Text('Next'),
                  ),
                ],
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _opening ? null : _toggle,
                  child: Text(_playing ? 'Pause' : 'Play'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FingerLegend(),
            const SizedBox(height: 12),
            _NeckPicker(
              selected: _neck,
              onSelected: (neck) => setState(() => _neck = neck),
            ),
            const SizedBox(height: 16),
            // The staff has a fixed height. Stretching it made the strings
            // far apart, which is the opposite of a tab you can read.
            SizedBox(
              height: SidewaysTab.height,
              child: DecoratedBox(
                key: const Key('staff'),
                decoration: BoxDecoration(
                  color: _neck.wood,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: SidewaysTab(
                  song: active,
                  position: _position,
                  neck: _neck,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _position.inMilliseconds
                  .clamp(0, active.lengthMs)
                  .toDouble(),
              max: active.lengthMs <= 0 ? 1 : active.lengthMs.toDouble(),
              activeColor: const Color(0xFFE4B15A),
              inactiveColor: const Color(0xFF3A342C),
              onChangeStart: (_) => _scrubStarted(),
              onChanged: _opening ? null : _scrubTo,
              onChangeEnd: _scrubEnded,
            ),
          ],
        ),
      ),
    );
  }
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
