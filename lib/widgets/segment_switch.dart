import 'package:flutter/material.dart';

import '../theme/riffster_theme.dart';

/// A few choices side by side. The one in use is gold.
///
/// The choices share whatever width the switch is given, so it needs a
/// parent that gives it one.
class SegmentSwitch<T> extends StatelessWidget {
  const SegmentSwitch({
    super.key,
    required this.choices,
    required this.label,
    required this.choiceKey,
    required this.selected,
    required this.onSelected,
  });

  final List<T> choices;
  final String Function(T choice) label;

  /// A key for each choice, so a test can press one.
  final Key Function(T choice) choiceKey;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: RiffColors.roomDeep,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(BorderSide(color: RiffColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final choice in choices)
              Expanded(
                child: TextButton(
                  key: choiceKey(choice),
                  // Pressing the one that is already on does nothing.
                  onPressed: choice == selected
                      ? null
                      : () => onSelected(choice),
                  style: TextButton.styleFrom(
                    backgroundColor: choice == selected
                        ? RiffColors.gold
                        : null,
                    foregroundColor: RiffColors.quiet,
                    disabledForegroundColor: RiffColors.onGold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(label(choice)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
