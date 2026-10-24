import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/daily_session/daily_session_screen.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/theme/riderbiz_theme.dart';

class DailyScreenAdapter implements RouteOptimizationPort {
  final requests = <RouteOptimizationRequest>[];

  @override
  String get providerId => 'daily-screen-test';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.throwIfCancelled();
    requests.add(request);
    return RouteCandidate(
      stopOrder: request.plan.pendingTasks
          .map((task) => task.stopId)
          .toSet()
          .toList(),
      vehicleLegs: const [],
      metrics: RouteMetrics(
        distanceMeters: 7000,
        travelDuration: const Duration(minutes: 20),
        serviceDuration: request.plan.pendingTasks.fold<Duration>(
          Duration.zero,
          (total, task) => total + task.serviceDuration,
        ),
        calculationDuration: Duration.zero,
      ),
      explanation: const OptimizationExplanation(
        summary: 'Synthetic widget test.',
      ),
    );
  }
}

void main() {
  testWidgets('accepts a route and restores individual package progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final db = RiderBizDatabase.forTesting(NativeDatabase.memory());
    final adapter = DailyScreenAdapter();

    Future<void> open() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: riderBizTheme(),
          home: DailySessionScreen(database: db, adapter: adapter),
        ),
      );
      await tester.pumpAndSettle();
    }

    try {
      await open();
      expect(
        find.text('Entregados: 0 / 150 · Pendientes: 150'),
        findsOneWidget,
      );

      await tester.tap(find.text('STOP-DAILY-001'));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const ValueKey('confirm-PACKAGE-DAILY-001'));
      expect(tester.widget<IconButton>(confirm).onPressed, isNull);

      await tester.ensureVisible(find.text('Calcular pendientes'));
      await tester.tap(find.text('Calcular pendientes'));
      await tester.pumpAndSettle();

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.plan.pendingTasks, hasLength(150));
      expect(tester.widget<IconButton>(confirm).onPressed, isNull);

      await tester.ensureVisible(find.text('Aceptar propuesta'));
      await tester.tap(find.text('Aceptar propuesta'));
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(confirm).onPressed, isNotNull);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Calcular pendientes'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Entregados: 1 / 150 · Pendientes: 149'),
        findsOneWidget,
      );
      expect(confirm, findsNothing);
      final events = await tester.runAsync(
        () => db.select(db.deliveryEvents).get(),
      );
      expect(events, hasLength(1));
      expect(events!.single.packageId, 'PACKAGE-DAILY-001');

      await tester.ensureVisible(find.text('Calcular pendientes'));
      await tester.tap(find.text('Calcular pendientes'));
      await tester.pumpAndSettle();

      expect(adapter.requests, hasLength(2));
      final request = adapter.requests.last;
      expect(request.plan.pendingTasks, hasLength(149));
      expect(
        request.plan.pendingTasks.any((task) => task.id == 'PACKAGE-DAILY-001'),
        isFalse,
      );
      expect(
        request.plan.pendingTasks.any(
          (task) => task.stopId == 'STOP-DAILY-001',
        ),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await open();

      expect(
        find.text('Entregados: 1 / 150 · Pendientes: 149'),
        findsOneWidget,
      );
      expect(find.text('Ruta aceptada: 60 paradas · 7000 m'), findsOneWidget);
      expect(find.text('Aceptar propuesta'), findsNothing);
      expect(adapter.requests, hasLength(2));
      expect(
        await tester.runAsync(() => db.select(db.deliveryEvents).get()),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => db.close());
    }
  });
}
