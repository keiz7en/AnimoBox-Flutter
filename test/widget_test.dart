import 'package:flutter_test/flutter_test.dart';
import 'package:animobox/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimoBoxApp());
    expect(find.text('Home'), findsOneWidget);
  });
}
