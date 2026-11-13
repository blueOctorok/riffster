import 'package:flutter/material.dart';

import '../theme/riffster_theme.dart';

/// A card you can press. Under the pointer it rises a little and its
/// edge turns gold. With no [onTap] it lies flat and does nothing.
class LiftCard extends StatefulWidget {
  const LiftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<LiftCard> createState() => _LiftCardState();
}

class _LiftCardState extends State<LiftCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final lifted = _hovered && onTap != null;
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: RiffMotion.settle,
          curve: RiffMotion.ease,
          padding: widget.padding,
          transform: Matrix4.translationValues(0, lifted ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: lifted ? RiffColors.panelLit : RiffColors.panel,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.all(
              color: lifted ? RiffColors.gold : RiffColors.line,
              width: 1.5,
            ),
            boxShadow: lifted
                ? [...RiffShadows.panel, ...RiffShadows.goldGlow]
                : RiffShadows.panel,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
