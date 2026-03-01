import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aprilai/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AprilAIApp()),
    );
    await tester.pump();
    // Just verify it renders without crashing
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
