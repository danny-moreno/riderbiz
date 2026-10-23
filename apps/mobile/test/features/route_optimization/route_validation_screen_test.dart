import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_validation_screen.dart';

RouteCandidate syntheticCandidate({
  required List<String> order,
  required int distance,
}) {
  return RouteCandidate(
    stopOrder: order,
    vehicleLegs: const [],
    metrics: RouteMetrics(
      distanceMeters: distance,
      travelDuration: const Duration(seconds: 351),
      serviceDuration: const Duration(seconds: 240),
      calculationDuration: Duration.zero,
    ),
    explanation: const OptimizationExplanation(
      summary: 'Synthetic screen test.',
    ),
  );
}

class ScreenTestAdapter implements RouteOptimizationPort {
  int calls = 0;

  @override
  String get providerId => 'synthetic-screen-test';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.throwIfCancelled();
    calls++;

    return syntheticCandidate(order: ['STOP-B', 'STOP-A'], distance: 2400);
  }
}

void main() {
  testWidgets('replaces the saved route only after explicit acceptance', (
    tester,
  ) async {
    final database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    final store = AcceptedRouteStore(database);
    final adapter = ScreenTestAdapter();
    const routeId = 'ROUTE-TABLET-SYNTHETIC';
    final originalAcceptance = DateTime.utc(2026, 10, 24, 8);

    try {
      await tester.runAsync(() async {
        await store.save(
          routeId: routeId,
          candidate: syntheticCandidate(
            order: ['STOP-A', 'STOP-B'],
            distance: 2501,
          ),
          acceptedAt: originalAcceptance,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: RouteValidationScreen(database: database, adapter: adapter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ruta aceptada y guardada'), findsOneWidget);
      expect(find.text('Orden aceptado: STOP-A → STOP-B'), findsOneWidget);
      expect(adapter.calls, 0);

      final calculate = find.widgetWithText(FilledButton, 'Calcular propuesta');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      expect(adapter.calls, 1);
      expect(find.text('Orden: STOP-B → STOP-A'), findsOneWidget);
      expect(find.text('Orden aceptado: STOP-A → STOP-B'), findsOneWidget);

      final beforeAcceptance = await tester.runAsync(() => store.load(routeId));
      expect(beforeAcceptance!.stopOrder, ['STOP-A', 'STOP-B']);
      expect(beforeAcceptance.acceptedAt, originalAcceptance);

      final accept = find.widgetWithText(FilledButton, 'Aceptar propuesta');
      await tester.scrollUntilVisible(
        accept,
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(accept);
      await tester.pumpAndSettle();

      final afterAcceptance = await tester.runAsync(() => store.load(routeId));
      expect(afterAcceptance!.stopOrder, ['STOP-B', 'STOP-A']);
      expect(afterAcceptance.metrics.distanceMeters, 2400);
      expect(find.text('Propuesta calculada'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: RouteValidationScreen(database: database, adapter: adapter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Orden aceptado: STOP-B → STOP-A'), findsOneWidget);
      expect(adapter.calls, 1);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => database.close());
    }
  });
}
