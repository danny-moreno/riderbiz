import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/delivery_accounting/delivery_accounting_service.dart';
import 'package:riderbiz_mobile/features/operator_settings/operator_tariff_service.dart';
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

import '../../support/route_optimization/daily_delivery_scenario_factory.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');

  test(
    'reoptimizes persisted partial deliveries across 150 packages and 60 stops',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'rb_daily_route_',
      );
      final file = File('${directory.path}/daily.sqlite');
      RiderBizDatabase? connection;
      final initial = const DailyDeliveryScenarioFactory().create(
        packageCount: 150,
        stopCount: 60,
      );
      final adapter = VroomRouteOptimizationAdapter(
        endpoint: Uri.parse('http://127.0.0.1:3000/'),
      );
      final acceptedAt = DateTime.utc(2026, 10, 24, 8);
      final deliveredAt = DateTime.utc(2026, 10, 24, 9);
      final replacementAt = DateTime.utc(2026, 10, 24, 10);

      try {
        var db = RiderBizDatabase.forTesting(NativeDatabase(file));
        connection = db;

        await OperatorTariffService(db).createInitialConfiguration(
          operatorId: 'OP-INTEGRATED',
          operatorName: 'Operador sintético integrado',
          tariffId: 'TAR-INTEGRATED',
          unitPriceMinor: 120,
          currency: 'EUR',
          validFrom: acceptedAt,
          createdAt: acceptedAt,
        );
        await db
            .into(db.deliveryRuns)
            .insert(
              DeliveryRunsCompanion.insert(
                id: 'RUN-INTEGRATED',
                operatorId: 'OP-INTEGRATED',
                startedAt: acceptedAt,
              ),
            );
        await db.batch((batch) {
          batch.insertAll(db.syntheticPackages, [
            for (final task in initial.plan.tasks)
              SyntheticPackagesCompanion.insert(
                id: task.id,
                deliveryRunId: 'RUN-INTEGRATED',
                identifiedOperatorId: const Value('OP-INTEGRATED'),
                identificationStatus: const Value('identified'),
                createdAt: acceptedAt,
                updatedAt: acceptedAt,
              ),
          ]);
        });

        final original = await adapter.optimize(initial);
        expect(original.stopOrder, hasLength(60));
        expect(
          original.stopOrder.toSet(),
          initial.plan.stops.map((stop) => stop.id).toSet(),
        );
        await AcceptedRouteStore(db).save(
          routeId: initial.plan.id,
          candidate: original,
          acceptedAt: acceptedAt,
        );

        final completedStop = original.stopOrder.first;
        final partialStop = original.stopOrder[1];
        final completedIds = initial.plan.tasks
            .where((task) => task.stopId == completedStop)
            .map((task) => task.id)
            .toSet();
        final partialTasks = initial.plan.tasks
            .where((task) => task.stopId == partialStop)
            .toList();
        expect(partialTasks.length, greaterThan(1));
        final deliveredIds = {...completedIds, partialTasks.first.id};

        for (final id in deliveredIds) {
          await DeliveryAccountingService(db).confirmDelivery(
            packageId: id,
            eventId: 'DELIVERED-$id',
            deliveredAt: deliveredAt,
          );
        }

        await db.close();
        connection = null;
        db = RiderBizDatabase.forTesting(NativeDatabase(file));
        connection = db;

        final packages = await db.select(db.syntheticPackages).get();
        final byId = {for (final package in packages) package.id: package};
        expect(packages, hasLength(150));
        expect(
          byId.keys.toSet(),
          initial.plan.tasks.map((task) => task.id).toSet(),
        );

        for (final task in initial.plan.tasks) {
          expect(
            byId[task.id]!.status,
            deliveredIds.contains(task.id) ? 'delivered' : 'pending',
          );
        }

        final stored = await AcceptedRouteStore(db).load(initial.plan.id);
        expect(stored!.stopOrder, original.stopOrder);
        expect(stored.acceptedAt, acceptedAt);
        expect(stored.metrics.distanceMeters, original.metrics.distanceMeters);

        final request = RouteOptimizationRequest(
          plan: RoutePlan(
            id: initial.plan.id,
            currentOrder: stored.stopOrder,
            stops: initial.plan.stops,
            tasks: [
              for (final task in initial.plan.tasks)
                RouteTask(
                  id: task.id,
                  stopId: task.stopId,
                  type: task.type,
                  status: byId[task.id]!.status == 'delivered'
                      ? RouteTaskStatus.completed
                      : RouteTaskStatus.pending,
                  priority: task.priority,
                  serviceDuration: task.serviceDuration,
                ),
            ],
          ),
          currentLocation: initial.currentLocation,
          departureAt: replacementAt,
          timeout: initial.timeout,
          reoptimizePendingOnly: true,
        );

        final candidate = await adapter.optimize(request);
        final pendingStops = request.plan.pendingTasks
            .map((task) => task.stopId)
            .toSet();
        expect(candidate.stopOrder, hasLength(59));
        expect(candidate.stopOrder.toSet(), pendingStops);
        expect(candidate.stopOrder, isNot(contains(completedStop)));
        expect(candidate.stopOrder, contains(partialStop));
        expect(
          candidate.metrics.serviceDuration,
          Duration(seconds: (150 - deliveredIds.length) * 60),
        );

        final beforeAcceptance = await AcceptedRouteStore(db)
            .load(initial.plan.id);
        expect(beforeAcceptance!.stopOrder, original.stopOrder);
        expect(beforeAcceptance.acceptedAt, acceptedAt);

        final events = await db.select(db.deliveryEvents).get();
        expect(events, hasLength(deliveredIds.length));
        expect(events.map((event) => event.packageId).toSet(), deliveredIds);
        final delivered = packages.where(
          (package) => package.status == 'delivered',
        );
        expect(
          delivered.fold<int>(
            0,
            (sum, package) => sum + package.unitPriceMinorSnapshot!,
          ),
          deliveredIds.length * 120,
        );

        await AcceptedRouteStore(db).save(
          routeId: initial.plan.id,
          candidate: candidate,
          acceptedAt: replacementAt,
        );
        await db.close();
        connection = null;
        db = RiderBizDatabase.forTesting(NativeDatabase(file));
        connection = db;

        final restored = await AcceptedRouteStore(db).load(initial.plan.id);
        expect(restored!.stopOrder, candidate.stopOrder);
        expect(restored.acceptedAt, replacementAt);
        expect(
          restored.metrics.distanceMeters,
          candidate.metrics.distanceMeters,
        );
        expect(restored.metrics.totalDuration, candidate.metrics.totalDuration);
        expect(await db.select(db.syntheticPackages).get(), hasLength(150));
        final restoredEvents = await db.select(db.deliveryEvents).get();
        expect(restoredEvents, hasLength(deliveredIds.length));
        expect(
          restoredEvents.map((event) => event.packageId).toSet(),
          deliveredIds,
        );
      } finally {
        await connection?.close();
        await directory.delete(recursive: true);
      }
    },
    skip: enabled ? false : 'Requires RUN_LOCAL_VROOM=true and local services.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
