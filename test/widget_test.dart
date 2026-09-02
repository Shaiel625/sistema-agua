import 'package:flutter_test/flutter_test.dart';
import 'package:sistema/main.dart';

void main() {
  testWidgets('Counter value increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SistemaApp());
  });
}