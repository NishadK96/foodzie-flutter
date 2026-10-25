import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodzy_pos/app/foodzy_app.dart';
import 'package:foodzy_pos/core/network/api_client.dart';
import 'package:foodzy_pos/features/auth/presentation/auth_controller.dart';

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<SessionTokens?> read() async => null;

  @override
  Future<void> write(SessionTokens tokens) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [390.0, 1024.0, 1280.0, 1366.0, 1440.0, 1536.0]) {
    testWidgets('POS renders at ${width.toInt()}px without layout overflow', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 960);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              FoodzyApiClient(sessionStore: _EmptySessionStore()),
            ),
          ],
          child: const FoodzyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final demoButton = find.text('Continue with demo data');
      if (demoButton.evaluate().isNotEmpty) {
        await tester.tap(demoButton);
        await tester.pumpAndSettle();
      }

      expect(find.text('Foodzy'), findsOneWidget);
      if (width >= 1100) {
        expect(find.text('Table 08'), findsOneWidget);
        expect(find.text('Charge'), findsOneWidget);
      } else {
        expect(find.text('Order (5)'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
