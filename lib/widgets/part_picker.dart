import 'package:flutter/material.dart';

import '../import/imported_score.dart';
import '../import/part_choices.dart';
import '../models/instrument.dart';
import '../music/melody_on_bass.dart';
import '../theme/riffster_theme.dart';
import 'room.dart';
import 'segment_switch.dart';

/// The part the player chose. [melody] is where on the neck its melody
/// should sit, and is null for a part played as it is written.
typedef PickedPart = ({ImportedTrack track, Register? melody});

/// Asks which part of a file to play. Null when the dialog is closed
/// without choosing.
Future<PickedPart?> showPartPicker(
  BuildContext context, {
  required Instrument playing,
  required List<PartChoice> choices,
}) {
  return showDialog<PickedPart>(
    context: context,
    builder: (context) => _PartPicker(playing: playing, choices: choices),
  );
}

class _PartPicker extends StatefulWidget {
  const _PartPicker({required this.playing, required this.choices});

  final Instrument playing;
  final List<PartChoice> choices;

  @override
  State<_PartPicker> createState() => _PartPickerState();
}

class _PartPickerState extends State<_PartPicker> {
  final _scroll = ScrollController();
  var _register = Register.low;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _pick(PartChoice choice) {
    final melody = choice.use == PartUse.melody ? _register : null;
    Navigator.pop(context, (track: choice.track, melody: melody));
  }

  /// The rows for every part that can be used as [use].
  List<Widget> _rows(PartUse use) {
    return [
      for (final choice in widget.choices)
        if (choice.use == use)
          _PartRow(
            choice: choice,
            onTap: use == PartUse.unavailable ? null : () => _pick(choice),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(24, 22, 12, 16),
        child: SizedBox(
          width: 452,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Which part is yours?', style: RiffText.title),
              const SizedBox(height: 6),
              // The list scrolls, so a file with twenty parts still
              // leaves the title and Cancel on screen. The bar shows
              // whenever there is more below.
              Flexible(
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    // Room for the bar, so it does not sit on the rows.
                    padding: const EdgeInsets.only(right: 12),
                    child: _parts(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The parts in three groups. A group with nothing in it is left out.
  Widget _parts() {
    final written = _rows(PartUse.written);
    final melodies = _rows(PartUse.melody);
    final unavailable = _rows(PartUse.unavailable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (written.isNotEmpty) ...[
          _Heading('Written for ${widget.playing.label}'),
          ...written,
        ],
        if (melodies.isNotEmpty) ...[
          _Heading(
            'Play its melody on bass',
            trailing: SizedBox(
              width: 132,
              child: SegmentSwitch<Register>(
                choices: Register.values,
                label: (register) => register.label,
                choiceKey: (register) => Key('register-${register.name}'),
                selected: _register,
                onSelected: (register) => setState(() => _register = register),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Moved by whole octaves to fit the bass, so the key stays '
              'the same. A chord becomes its top note. High is an octave '
              'up.',
              style: RiffText.label,
            ),
          ),
          ...melodies,
        ],
        if (unavailable.isNotEmpty) ...[
          const _Heading('Cannot be played here'),
          ...unavailable,
        ],
      ],
    );
  }
}

/// The small capitals over a group of parts.
class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: RiffText.caption)),
          ?trailing,
        ],
      ),
    );
  }
}

/// One part. With no [onTap] it is dim and cannot be pressed.
class _PartRow extends StatelessWidget {
  const _PartRow({required this.choice, required this.onTap});

  final PartChoice choice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ready = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: RiffColors.roomDeep.withValues(alpha: ready ? 0.55 : 0.25),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: RiffColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('part-${choice.track.name}'),
          onTap: onTap,
          hoverColor: RiffColors.gold.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RiffText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ready ? RiffColors.cream : RiffColors.quiet,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(choice.detail, style: RiffText.label),
                    ],
                  ),
                ),
                if (ready)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: RiffColors.gold,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
