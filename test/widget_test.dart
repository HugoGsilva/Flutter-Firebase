import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/presentation/views/home_view.dart';

void main() {
  testWidgets('Smoke test inicial da HomeView', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeView(),
      ),
    );

    expect(find.text('Piramid Game'), findsOneWidget);
  });
}
