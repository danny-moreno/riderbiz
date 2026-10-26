import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/daily_session/daily_session_screen.dart';
import 'package:riderbiz_mobile/features/daily_session/synthetic_daily_session_service.dart';
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';

class UnavailableUsualOrderAdapter implements RouteOptimizationPort {
  int calls = 0;

  @override
  String get providerId => 'unavailable-usual-order-test';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    calls++;
    throw const RouteOptimizationFailure(
      type: RouteOptimizationFailureType.unavailable,
      message: 'Optimizer unavailable in this test.',
    );
  }
}

void main() {
  testWidgets('uses usual order and confirms delivery without optimization', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final db = RiderBizDatabase.forTesting(NativeDatabase.memory());
    final adapter = UnavailableUsualOrderAdapter();

    Future<void> open() async {
      await tester.pumpWidget(
        MaterialApp(
          home: DailySessionScreen(database: db, adapter: adapter),
        ),
      );
      await tester.pumpAndSettle();
    }

    try {
      await open();
      final confirm = find.byKey(const ValueKey('confirm-PACKAGE-DAILY-001'));

      await tester.tap(find.text('STOP-DAILY-001'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(confirm).onPressed, isNull);

      final usual = find.widgetWithText(OutlinedButton, 'Usar orden habitual');
      await tester.ensureVisible(usual);
      await tester.tap(usual);
      await tester.pumpAndSettle();

      expect(adapter.calls, 0);
      expect(
        find.text('Orden habitual guardado: 60 paradas · sin estimaciones'),
        findsOneWidget,
      );
      expect(find.textContaining('Ruta aceptada:'), findsNothing);
      expect(find.text('Aceptar propuesta'), findsNothing);

      final saved = await tester.runAsync(
        () =>
            AcceptedRouteStore(db)
                .loadSelection(SyntheticDailySessionService.routeId),
      );
      final plan = await tester.runAsync(
        () => SyntheticDailySessionService(db).loadPlan(),
      );

      expect(saved!.mode, RouteSelectionMode.usual);
      expect(saved.metrics, isNull);
      expect(saved.stopOrder, plan!.currentOrder);

      await tester.ensureVisible(confirm);
      expect(tester.widget<IconButton>(confirm).onPressed, isNotNull);
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
      expect(adapter.calls, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await open();

      expect(adapter.calls, 0);
      expect(
        find.text('Entregados: 1 / 150 · Pendientes: 149'),
        findsOneWidget,
      );
      expect(
        find.text('Orden habitual guardado: 60 paradas · sin estimaciones'),
        findsOneWidget,
      );

      final restored = await tester.runAsync(
        () =>
            AcceptedRouteStore(db)
                .loadSelection(SyntheticDailySessionService.routeId),
      );
      expect(restored!.stopOrder, saved.stopOrder);
      expect(restored.acceptedAt, saved.acceptedAt);
      expect(restored.metrics, isNull);

      final events = await tester.runAsync(
        () => db.select(db.deliveryEvents).get(),
      );
      expect(events, hasLength(1));
      expect(events!.single.packageId, 'PACKAGE-DAILY-001');

      await tester.tap(find.text('STOP-DAILY-001'));
      await tester.pumpAndSettle();
      expect(confirm, findsNothing);

      await tester.ensureVisible(find.text('Calcular pendientes'));
      await tester.tap(find.text('Calcular pendientes'));
      await tester.pumpAndSettle();

      expect(adapter.calls, 1);
      expect(
        find.text('No se pudo conectar con el servicio local.'),
        findsOneWidget,
      );
      expect(
        find.text('Orden habitual guardado: 60 paradas · sin estimaciones'),
        findsOneWidget,
      );
      final afterFailure = await tester.runAsync(
        () =>
            AcceptedRouteStore(db)
                .loadSelection(SyntheticDailySessionService.routeId),
      );
      expect(afterFailure!.stopOrder, saved.stopOrder);
      expect(afterFailure.acceptedAt, saved.acceptedAt);
      expect(afterFailure.metrics, isNull);

      final remainingConfirm = find.byKey(
        const ValueKey('confirm-PACKAGE-DAILY-061'),
      );
      await tester.ensureVisible(remainingConfirm);
      expect(tester.widget<IconButton>(remainingConfirm).onPressed, isNotNull);
      await tester.tap(remainingConfirm);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Calcular pendientes'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Entregados: 2 / 150 · Pendientes: 148'),
        findsOneWidget,
      );
      expect(adapter.calls, 1);
      expect(
        await tester.runAsync(() => db.select(db.deliveryEvents).get()),
        hasLength(2),
      );

      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => db.close());
    }
  });
}
