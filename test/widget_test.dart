import 'package:arc_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ArcApp()));
    expect(find.text('TU TÉCNICA, EN TIEMPO REAL'), findsOneWidget);
  });
}
