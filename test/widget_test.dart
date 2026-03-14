// Smoke test: verifies the app boots without crashing.
// Full flow tests live in test/unit/ and test/widget/.
import 'package:boilerplate_flutter/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PrimaryButton smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(text: 'Go', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('Go'), findsOneWidget);
  });
}
