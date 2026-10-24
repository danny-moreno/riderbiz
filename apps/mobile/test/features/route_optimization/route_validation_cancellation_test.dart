import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_validation_screen.dart';

import 'route_validation_screen_test.dart' show syntheticCandidate;

class PendingScreenAdapter implements RouteOptimizationPort {
  final result = Completer<RouteCandidate>();
  RouteOptimizationCancellationSignal? signal;
  int calls = 0;

  @override
  String get providerId => 'pending-screen-test';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) {
    calls++;
    signal = cancellationSignal;
    return result.future;
  }
}

void main() {
  testWidgets('leaving cancels calculation and ignores a late result', (
    tester,
  ) async {
    final database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    final store = AcceptedRouteStore(database);
    final adapter = PendingScreenAdapter();
    const routeId = 'ROUTE-TABLET-SYNTHETIC';
    final acceptedAt = DateTime.utc(2026, 10, 24, 8);

    try {
      await tester.runAsync(() async {
        await store.save(
          routeId: routeId,
          candidate: syntheticCandidate(
            order: ['STOP-A', 'STOP-B'],
            distance: 2501,
          ),
          acceptedAt: acceptedAt,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => RouteValidationScreen(
                          database: database,
                          adapter: adapter,
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir rutas'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir rutas'));
      await tester.pumpAndSettle();

      final calculate = find.widgetWithText(FilledButton, 'Calcular propuesta');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pump();

      expect(adapter.calls, 1);
      expect(adapter.signal, isNotNull);
      expect(adapter.signal!.isCancelled, isFalse);
      expect(find.text('Calculando…'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Abrir rutas'), findsOneWidget);
      expect(adapter.signal!.isCancelled, isTrue);

      adapter.result.complete(
        syntheticCandidate(order: ['STOP-B', 'STOP-A'], distance: 2400),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final saved = await tester.runAsync(() => store.load(routeId));
      expect(saved, isNotNull);
      expect(saved!.stopOrder, ['STOP-A', 'STOP-B']);
      expect(saved.metrics.distanceMeters, 2501);
      expect(saved.acceptedAt, acceptedAt);

      await tester.tap(find.text('Abrir rutas'));
      await tester.pumpAndSettle();

      expect(find.text('Orden aceptado: STOP-A → STOP-B'), findsOneWidget);
      expect(find.text('Propuesta calculada'), findsNothing);
      expect(tester.widget<FilledButton>(calculate).onPressed, isNotNull);
      expect(adapter.calls, 1);
    } finally {
      if (!adapter.result.isCompleted) {
        adapter.result.complete(
          syntheticCandidate(order: ['STOP-A', 'STOP-B'], distance: 2501),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => database.close());
    }
  });
}
