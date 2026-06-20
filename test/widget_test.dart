// Basic smoke test for the Wiggy Wash app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wiggywash/theme.dart';

void main() {
  testWidgets('Section pill renders its label in caps', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(body: SectionPill('Membership Tally')),
      ),
    );
    expect(find.text('MEMBERSHIP TALLY'), findsOneWidget);
  });
}
