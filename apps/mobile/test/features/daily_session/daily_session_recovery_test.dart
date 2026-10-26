import 'dart:async';

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

class ControlledDailyAdapter implements RouteOptimizationPort {
  final requests = <RouteOptimizationRequest>[];
  final signals = <RouteOptimizationCancellationSignal?>[];
  final responses = <Completer<RouteCandidate>>[];
  final started = StreamController<void>.broadcast();

  @override
  String get providerId => 'controlled-daily-test';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) {
    requests.add(request);
    signals.add(cancellationSignal);
    final response = Completer<RouteCandidate>();
    responses.add(response);
    started.add(null);
    return response.future;
  }
}

RouteCandidate candidate(List<String> order, int distance) {
  return RouteCandidate(
    stopOrder: order,
    vehicleLegs: const [],
    metrics: RouteMetrics(
      distanceMeters: distance,
      travelDuration: const Duration(minutes: 20),
      serviceDuration: const Duration(minutes: 150),
      calculationDuration: Duration.zero,
    ),
    explanation: const OptimizationExplanation(
      summary: 'Synthetic recovery test.',
    ),
  );
}

void main() {
  late RiderBizDatabase db;
  late ControlledDailyAdapter adapter;
  final acceptedAt = DateTime.utc(2026, 10, 24, 8);

  setUp(() async {
    db = RiderBizDatabase.forTesting(NativeDatabase.memory());
    adapter = ControlledDailyAdapter();
    final service = SyntheticDailySessionService(db);
    await service.prepare();
    final plan = await service.loadPlan();
    await AcceptedRouteStore(db).save(
      routeId: SyntheticDailySessionService.routeId,
      candidate: candidate(plan.currentOrder, 7000),
      acceptedAt: acceptedAt,
    );
    await service.confirmPackage('PACKAGE-DAILY-001');
  });

  tearDown(() async {
    await adapter.started.close();
    await db.close();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DailySessionScreen(database: db, adapter: adapter),
                  ),
                );
              },
              child: const Text('Abrir jornada de prueba'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir jornada de prueba'));
    await tester.pumpAndSettle();
  }

  Future<void> calculate(WidgetTester tester) async {
    final started = adapter.started.stream.first;
    await tester.tap(find.text('Calcular pendientes'));
    await tester.runAsync(() => started);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Calcular pendientes');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  }

  Future<void> expectPreserved(WidgetTester tester) async {
    final restored = await tester.runAsync(
      () => AcceptedRouteStore(db).load(SyntheticDailySessionService.routeId),
    );
    expect(restored, isNotNull);
    expect(restored!.acceptedAt, acceptedAt);
    expect(restored.metrics.distanceMeters, 7000);
    expect(restored.stopOrder, hasLength(60));

    final plan = await tester.runAsync(
      () => SyntheticDailySessionService(db).loadPlan(),
    );
    expect(plan!.pendingTasks, hasLength(149));
    expect(
      plan.tasks.singleWhere((task) => task.id == 'PACKAGE-DAILY-001').status,
      RouteTaskStatus.completed,
    );
    final events = await tester.runAsync(
      () => db.select(db.deliveryEvents).get(),
    );
    expect(events, hasLength(1));
    expect(events!.single.packageId, 'PACKAGE-DAILY-001');
  }

  testWidgets('recovers after timeout without replacing saved progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    try {
      await open(tester);
      await calculate(tester);

      expect(adapter.requests.single.timeout, const Duration(seconds: 40));
      expect(adapter.requests.single.plan.pendingTasks, hasLength(149));

      adapter.responses.single.completeError(
        const RouteOptimizationFailure(
          type: RouteOptimizationFailureType.timeout,
          message: 'Synthetic timeout.',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('El cálculo superó el tiempo disponible.'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Calcular pendientes'),
            )
            .onPressed,
        isNotNull,
      );
      await expectPreserved(tester);

      await calculate(tester);
      final request = adapter.requests.last;
      expect(request.plan.pendingTasks, hasLength(149));
      adapter.responses.last.complete(
        candidate(
          request.plan.pendingTasks.map((task) => task.stopId).toSet().toList(),
          6500,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aceptar propuesta'), findsOneWidget);
      expect(
        find.text('El cálculo superó el tiempo disponible.'),
        findsNothing,
      );
      expect(
        find.text('Entregados: 1 / 150 · Pendientes: 149'),
        findsOneWidget,
      );
      await expectPreserved(tester);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('leaving cancels and ignores a late daily proposal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    try {
      await open(tester);
      await calculate(tester);
      expect(adapter.signals.single, isNotNull);
      expect(adapter.signals.single!.isCancelled, isFalse);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(adapter.signals.single!.isCancelled, isTrue);

      adapter.responses.single.complete(
        candidate(
          adapter.requests.single.plan.currentOrder.reversed.toList(),
          1,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectPreserved(tester);

      await tester.tap(find.text('Abrir jornada de prueba'));
      await tester.pumpAndSettle();

      expect(adapter.requests, hasLength(1));
      expect(find.text('Aceptar propuesta'), findsNothing);
      expect(find.text('Ruta aceptada: 60 paradas · 7000 m'), findsOneWidget);
      expect(
        find.text('Entregados: 1 / 150 · Pendientes: 149'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Calcular pendientes'),
            )
            .onPressed,
        isNotNull,
      );
      await expectPreserved(tester);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
