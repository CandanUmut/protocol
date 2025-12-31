import 'package:close_the_ramp_protocol/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('language toggle updates locale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CloseTheRampApp()));
    await tester.pumpAndSettle();

    expect(find.text('Rampı Kapat — Protokol'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    // language toggling flips to EN
    expect(find.text('Close the Ramp — Protocol'), findsWidgets);
  });
}
