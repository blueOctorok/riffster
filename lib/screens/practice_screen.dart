import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/demo_song.dart';
import '../import/guitar_pro_reader.dart';
import '../import/open_guitar_pro.dart';
import '../models/fretting_finger.dart';
import '../models/tab_song.dart';
import '../widgets/finger_colors.dart';
import '../widgets/sideways_tab.dart';

/// The practice screen. It scrolls whatever song is loaded.
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

  /// Where the song was when Play was pressed. The ticker itself restarts at zero.
  Duration _resumeFrom = Duration.zero;
  bool _playing = false;
  bool _opening = false;

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

  void _onTick(Duration elapsed) {
    final position = _resumeFrom + elapsed;
    final end = Duration(milliseconds: _song.lengthMs + 800);
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

  void _toggle() {
    if (_playing) {
      _ticker.stop();
      setState(() => _playing = false);
      return;
    }
    final end = Duration(milliseconds: _song.lengthMs);
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
        _position = Duration.zero;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clock = _clockLabel(_position);
    final songClock = _clockLabel(Duration(milliseconds: _song.lengthMs));

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
                    _song.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_song.tempoBpm} bpm',
                  style: const TextStyle(color: Color(0xFF8A8175)),
                ),
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
                FilledButton(
                  onPressed: _opening ? null : _toggle,
                  child: Text(_playing ? 'Pause' : 'Play'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FingerLegend(),
            const SizedBox(height: 16),
            // The staff has a fixed height. Stretching it made the strings
            // far apart, which is the opposite of a tab you can read.
            SizedBox(
              height: SidewaysTab.height,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF241F1A),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: SidewaysTab(
                  song: _song,
                  position: _position,
                ),
              ),
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
