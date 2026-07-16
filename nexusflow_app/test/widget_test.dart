import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexusflow_app/main.dart';

void main() {
  testWidgets('App renderiza a tela de login quando não autenticado', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NexusFlowApp()));
    await tester.pumpAndSettle();

    expect(find.text('NEXUS flow'), findsWidgets);
  });
}
