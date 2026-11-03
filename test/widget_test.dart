import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/app.dart';

void main() {
  testWidgets('practice screen shows the demo song', (tester) async {
    await tester.pumpWidget(const RiffsterApp());

    expect(find.text('Riffster'), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Pause'), findsOneWidget);
  });
}
