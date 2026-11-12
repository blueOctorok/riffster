import 'package:flutter/material.dart';

import '../audio/guitar_ear.dart';
import '../theme/riffster_theme.dart';

const _gold = RiffColors.gold;
const _ink = RiffColors.cardInk;
const _quiet = RiffColors.quiet;

/// Cable, iRig, and the room mic. One is on at a time. A source that is
/// not plugged in cannot be turned on.
class InputSources extends StatelessWidget {
  const InputSources({
    super.key,
    required this.active,
    required this.cablePresent,
    required this.irigPresent,
    required this.micPresent,
    required this.enabled,
    required this.onToggle,
  });

  final EarSource? active;
  final bool cablePresent;
  final bool irigPresent;
  final bool micPresent;
  final bool enabled;
  final ValueChanged<EarSource> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SourceButton(
          name: 'Cable',
          source: EarSource.cable,
          on: active == EarSource.cable,
          present: cablePresent,
          enabled: enabled,
          onToggle: onToggle,
        ),
        _SourceButton(
          name: 'iRig',
          source: EarSource.irig,
          on: active == EarSource.irig,
          present: irigPresent,
          enabled: enabled,
          onToggle: onToggle,
        ),
        _SourceButton(
          name: 'Mic',
          source: EarSource.mic,
          on: active == EarSource.mic,
          present: micPresent,
          enabled: enabled,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.name,
    required this.source,
    required this.on,
    required this.present,
    required this.enabled,
    required this.onToggle,
  });

  final String name;
  final EarSource source;
  final bool on;
  final bool present;
  final bool enabled;
  final ValueChanged<EarSource> onToggle;

  @override
  Widget build(BuildContext context) {
    final ready = present && enabled;
    return FilledButton(
      key: Key('input-${source.name}'),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStatePropertyAll(
          on ? _ink : (ready ? _quiet : RiffColors.faint),
        ),
        backgroundColor: WidgetStatePropertyAll(
          on ? _gold : const Color(0x00000000),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: on ? _gold : RiffColors.lineStrong),
        ),
      ),
      onPressed: ready ? () => onToggle(source) : null,
      child: Text(name),
    );
  }
}
