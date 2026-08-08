import 'package:flutter_test/flutter_test.dart';
import 'package:limesugar/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LimeSugarApp());
    expect(find.text('Home'), findsOneWidget);
  });
}
