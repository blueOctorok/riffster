import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/demo_song.dart';
import '../models/fretting_finger.dart';
import '../widgets/finger_colors.dart';
import '../widgets/sideways_tab.dart';

/// The practice screen. It only scrolls a song. Import and scoring come later.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _position = Duration.zero;

  /// Where the song was when Play was pressed. The ticker itself restarts at zero.
  Duration _resumeFrom = Duration.zero;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final position = _resumeFrom + elapsed;
    final end = Duration(milliseconds: demoSong.lengthMs + 800);
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
    final end = Duration(milliseconds: demoSong.lengthMs);
    if (_position >= end) {
      _position = Duration.zero;
    }
    _resumeFrom = _position;
    _ticker.start();
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final clock = _clockLabel(_position);
    final songClock = _clockLabel(Duration(milliseconds: demoSong.lengthMs));

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
                Text(
                  demoSong.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${demoSong.tempoBpm} bpm',
                  style: const TextStyle(color: Color(0xFF8A8175)),
                ),
                const Spacer(),
                Text(
                  '$clock / $songClock',
                  style: const TextStyle(color: Color(0xFF8A8175)),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _toggle,
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
                  song: demoSong,
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
