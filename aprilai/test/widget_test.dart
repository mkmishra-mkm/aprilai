import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aprilai/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AprilAIApp()),
    );
    // Verify it renders without crashing
    expect(find.byType(ProviderScope), findsOneWidget);
    // Drain all pending timers (splash delay + animation zero-duration timers)
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
