import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/delivery_accounting/delivery_accounting_service.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_plan_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_validation_screen.dart';
import 'package:riderbiz_mobile/features/route_optimization/synthetic_route_delivery_service.dart';

import 'route_validation_screen_test.dart' show ScreenTestAdapter;

void main() {
  testWidgets(
    'uses stored coordinates and service without resetting delivery',
    (tester) async {
      final db = RiderBizDatabase.forTesting(NativeDatabase.memory());
      final adapter = ScreenTestAdapter();
      final timestamp = DateTime.utc(2026, 10, 24, 10);
      const changedCoordinate = RouteCoordinate(
        latitude: 42.8201,
        longitude: -1.6302,
      );

      try {
        await tester.runAsync(() async {
          final deliveries = SyntheticRouteDeliveryService(db);
          await deliveries.prepare();
          await deliveries.ensureRoutePlan();
          final original = await RoutePlanStore(db)
              .load(SyntheticRouteDeliveryService.routeId);

          await RoutePlanStore(db).save(
            deliveryRunId: 'RUN-SYN-ROUTE-TABLET',
            plan: RoutePlan(
              id: original!.id,
              currentOrder: ['STOP-B', 'STOP-A'],
              stops: [
                for (final stop in original.stops)
                  OperationalStop(
                    id: stop.id,
                    coordinate: stop.id == 'STOP-B'
                        ? changedCoordinate
                        : stop.coordinate,
                    taskIds: stop.taskIds,
                  ),
              ],
              tasks: [
                for (final task in original.tasks)
                  RouteTask(
                    id: task.id,
                    stopId: task.stopId,
                    type: task.type,
                    status: task.status,
                    priority: task.stopId == 'STOP-B'
                        ? RoutePriority.high
                        : task.priority,
                    serviceDuration: task.stopId == 'STOP-B'
                        ? const Duration(seconds: 175)
                        : task.serviceDuration,
                  ),
              ],
            ),
            updatedAt: timestamp,
          );

          await DeliveryAccountingService(db).confirmDelivery(
            packageId: 'RB-SYN-ROUTE-A',
            eventId: 'EVENT-PERSISTED-SCREEN-A',
            deliveredAt: timestamp,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: RouteValidationScreen(database: db, adapter: adapter),
          ),
        );
        await tester.pumpAndSettle();

        final calculate = find.widgetWithText(
          FilledButton,
          'Calcular propuesta',
        );
        await tester.ensureVisible(calculate);
        await tester.tap(calculate);
        await tester.pumpAndSettle();

        expect(adapter.calls, 1);
        final request = adapter.requests.single;
        expect(request.plan.currentOrder, ['STOP-B', 'STOP-A']);
        expect(request.plan.pendingTasks.map((task) => task.id), [
          'RB-SYN-ROUTE-B',
        ]);
        final pending = request.plan.pendingTasks.single;
        expect(pending.serviceDuration, const Duration(seconds: 175));
        expect(pending.priority, RoutePriority.high);

        final stop = request.plan.stops.singleWhere(
          (stop) => stop.id == 'STOP-B',
        );
        expect(stop.coordinate.latitude, changedCoordinate.latitude);
        expect(stop.coordinate.longitude, changedCoordinate.longitude);
        expect(
          request.plan.tasks
              .singleWhere((task) => task.id == 'RB-SYN-ROUTE-A')
              .status,
          RouteTaskStatus.completed,
        );
        expect(find.text('Orden: STOP-B'), findsOneWidget);

        final definition = await tester.runAsync(
          () => db.select(db.routePlanDefinitions).getSingle(),
        );
        expect(definition!.updatedAt.toUtc(), timestamp);

        final events = await tester.runAsync(
          () => db.select(db.deliveryEvents).get(),
        );
        expect(events, hasLength(1));
        expect(events!.single.id, 'EVENT-PERSISTED-SCREEN-A');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(() => db.close());
      }
    },
  );
}
