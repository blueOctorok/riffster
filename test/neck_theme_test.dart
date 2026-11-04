import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/theme/neck_theme.dart';

void main() {
  test('each neck keeps its strings readable against the wood', () {
    for (final neck in neckThemes) {
      final inkIsLight = neck.ink.computeLuminance() > 0.5;
      final woodIsLight = neck.wood.computeLuminance() > 0.5;
      expect(inkIsLight, isNot(woodIsLight), reason: neck.name);
    }
  });
}
