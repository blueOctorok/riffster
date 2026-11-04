import 'package:flutter/material.dart';
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

  testWidgets('the slider jumps to a later part of the song', (tester) async {
    await tester.pumpWidget(const RiffsterApp());

    expect(find.text('0:00 / 0:04'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pump();

    expect(find.text('0:00 / 0:04'), findsNothing);
    expect(find.textContaining('/ 0:04'), findsOneWidget);
  });
}
