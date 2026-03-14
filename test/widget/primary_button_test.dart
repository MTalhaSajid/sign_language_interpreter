import 'package:boilerplate_flutter/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('PrimaryButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrap(
        PrimaryButton(text: 'Login', onPressed: () {}),
      ));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(wrap(
        PrimaryButton(text: 'Login', isLoading: true, onPressed: () {}),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    });

    testWidgets('button is disabled when isLoading is true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        PrimaryButton(
          text: 'Login',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    testWidgets('onPressed fires when not loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        PrimaryButton(text: 'Login', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });
  });
}
