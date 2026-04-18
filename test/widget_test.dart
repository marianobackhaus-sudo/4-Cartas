import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:juego_cartas_4/app.dart';

void main() {
  testWidgets('App renders bootstrap hero without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('4 CARTAS'), findsOneWidget);
    expect(find.text('B L I T Z'), findsOneWidget);
  });
}
