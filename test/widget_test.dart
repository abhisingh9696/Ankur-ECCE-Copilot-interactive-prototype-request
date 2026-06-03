import 'package:flutter_test/flutter_test.dart';
import 'package:ankur_voice_copilot/main.dart';

void main() {
  testWidgets('Ankur app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AnkurApp());
    expect(find.text('Ankur AI'), findsOneWidget);
  });
}
