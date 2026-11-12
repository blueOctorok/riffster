import 'package:flutter/material.dart';

import '../theme/riffster_theme.dart';

/// The dog and the name, wherever the app signs itself.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image(
          image: AssetImage('assets/brand/riffster-mark.png'),
          height: 34,
          // The file is far bigger than it is shown. Medium quality averages
          // it down, where the default would skip pixels and break the lines.
          filterQuality: FilterQuality.medium,
          // The name beside it already says what this is.
          excludeFromSemantics: true,
        ),
        SizedBox(width: 10),
        Text('Riffster', style: RiffText.wordmark),
      ],
    );
  }
}
