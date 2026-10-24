import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/delivery_accounting/delivery_accounting_service.dart';
import 'package:riderbiz_mobile/features/operator_settings/operator_tariff_service.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_plan_store.dart';

import '../../support/route_optimization/daily_delivery_scenario_factory.dart';

void main() {
  late Directory directory;
  late File file;
  late RiderBizDatabase db;
  late RoutePlan plan;
  final timestamp = DateTime.utc(2026, 10, 24, 8);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rb_plan_store_');
    file = File('${directory.path}/plan.sqlite');
    db = RiderBizDatabase.forTesting(NativeDatabase(file));
    plan = const DailyDeliveryScenarioFactory()
        .create(packageCount: 150, stopCount: 60)
        .plan;

    await OperatorTariffService(db).createInitialConfiguration(
      operatorId: 'OP-PLAN',
      operatorName: 'Operador sintético',
      tariffId: 'TAR-PLAN',
      unitPriceMinor: 120,
      currency: 'EUR',
      validFrom: timestamp,
      createdAt: timestamp,
    );
    await db
        .into(db.deliveryRuns)
        .insert(
          DeliveryRunsCompanion.insert(
            id: 'RUN-PLAN',
            operatorId: 'OP-PLAN',
            startedAt: timestamp,
          ),
        );
    await db.batch((batch) {
      batch.insertAll(db.syntheticPackages, [
        for (final task in plan.tasks)
          SyntheticPackagesCompanion.insert(
            id: task.id,
            deliveryRunId: 'RUN-PLAN',
            identifiedOperatorId: const Value('OP-PLAN'),
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
      ]);
    });
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<void> save() =>
      RoutePlanStore(db)
          .save(deliveryRunId: 'RUN-PLAN', plan: plan, updatedAt: timestamp);

  test(
    'restores 150 packages and 60 stops with current delivery states',
    () async {
      await save();

      final deliveredIds = {
        ...plan.stops.first.taskIds,
        plan.stops[1].taskIds.first,
      };
      for (final id in deliveredIds) {
        await DeliveryAccountingService(db).confirmDelivery(
          packageId: id,
          eventId: 'EVENT-$id',
          deliveredAt: timestamp.add(const Duration(hours: 1)),
        );
      }

      await db.close();
      db = RiderBizDatabase.forTesting(NativeDatabase(file));

      final restored = await RoutePlanStore(db).load(plan.id);
      expect(restored, isNotNull);
      expect(restored!.id, plan.id);
      expect(restored.currentOrder, plan.currentOrder);
      expect(restored.stops, hasLength(60));
      expect(restored.tasks, hasLength(150));

      for (var index = 0; index < plan.stops.length; index++) {
        final actual = restored.stops[index];
        final expected = plan.stops[index];
        expect(actual.id, expected.id);
        expect(actual.coordinate.latitude, expected.coordinate.latitude);
        expect(actual.coordinate.longitude, expected.coordinate.longitude);
        expect(actual.taskIds, expected.taskIds);
        expect(actual.isLocked, expected.isLocked);
        expect(actual.walkingClusterId, expected.walkingClusterId);
      }
      for (var index = 0; index < plan.tasks.length; index++) {
        final actual = restored.tasks[index];
        final expected = plan.tasks[index];
        expect(actual.id, expected.id);
        expect(actual.stopId, expected.stopId);
        expect(actual.type, expected.type);
        expect(actual.priority, expected.priority);
        expect(actual.serviceDuration, expected.serviceDuration);
        expect(
          actual.status,
          deliveredIds.contains(actual.id)
              ? RouteTaskStatus.completed
              : RouteTaskStatus.pending,
        );
      }
      final pendingStops = restored.pendingTasks
          .map((task) => task.stopId)
          .toSet();
      expect(pendingStops, hasLength(59));
      expect(pendingStops, isNot(contains(plan.stops.first.id)));
      expect(pendingStops, contains(plan.stops[1].id));
      expect(
        await db.select(db.deliveryEvents).get(),
        hasLength(deliveredIds.length),
      );
    },
  );

  test(
    'rejects packages from another run without replacing the plan',
    () async {
      await save();
      final before = await db.select(db.routePlanDefinitions).getSingle();

      await db
          .into(db.deliveryRuns)
          .insert(
            DeliveryRunsCompanion.insert(
              id: 'RUN-OTHER',
              operatorId: 'OP-PLAN',
              startedAt: timestamp,
            ),
          );
      await expectLater(
        RoutePlanStore(db).save(
          deliveryRunId: 'RUN-OTHER',
          plan: plan,
          updatedAt: timestamp.add(const Duration(hours: 1)),
        ),
        throwsStateError,
      );

      final after = await db.select(db.routePlanDefinitions).getSingle();
      expect(after.deliveryRunId, before.deliveryRunId);
      expect(after.definitionJson, before.definitionJson);
      expect(after.updatedAt, before.updatedAt);
    },
  );

  test('rejects a missing run and returns null for an unknown route', () async {
    expect(await RoutePlanStore(db).load('UNKNOWN'), isNull);
    await expectLater(
      RoutePlanStore(db)
          .save(deliveryRunId: 'MISSING', plan: plan, updatedAt: timestamp),
      throwsStateError,
    );
    expect(await db.select(db.routePlanDefinitions).get(), isEmpty);
  });

  test('rejects a failed package instead of treating it as pending', () async {
    await save();
    await (db.update(db.syntheticPackages)
          ..where((row) => row.id.equals(plan.tasks.first.id)))
        .write(const SyntheticPackagesCompanion(status: Value('failed')));

    await expectLater(RoutePlanStore(db).load(plan.id), throwsStateError);
    expect(await db.select(db.routePlanDefinitions).get(), hasLength(1));
    expect(await db.select(db.syntheticPackages).get(), hasLength(150));
  });

  test('preserves route constraints across SQLite reopen', () async {
    final firstStop = plan.stops.first;
    final secondStop = plan.stops[1];
    final firstTaskId = firstStop.taskIds.first;
    final windowStart = timestamp.add(const Duration(hours: 1));
    final windowEnd = timestamp.add(const Duration(hours: 3));
    const anchor = RouteCoordinate(latitude: 42.813, longitude: -1.641);

    plan = RoutePlan(
      id: plan.id,
      currentOrder: plan.currentOrder.reversed.toList(),
      stops: [
        for (final stop in plan.stops)
          OperationalStop(
            id: stop.id,
            coordinate: stop.coordinate,
            taskIds: stop.taskIds,
            isLocked: stop.id == firstStop.id,
            walkingClusterId:
                stop.id == firstStop.id || stop.id == secondStop.id
                ? 'WALK-PERSISTED'
                : null,
          ),
      ],
      tasks: [
        for (final task in plan.tasks)
          RouteTask(
            id: task.id,
            stopId: task.stopId,
            type: task.type,
            status: task.status,
            priority: task.id == firstTaskId
                ? RoutePriority.urgent
                : RoutePriority.low,
            serviceDuration: task.id == firstTaskId
                ? const Duration(microseconds: 1500001)
                : task.serviceDuration,
            timeWindow: task.id == firstTaskId
                ? RouteTimeWindow(startsAt: windowStart, endsAt: windowEnd)
                : null,
          ),
      ],
      walkingClusters: [
        WalkingCluster(
          id: 'WALK-PERSISTED',
          stopIds: [firstStop.id, secondStop.id],
          anchor: anchor,
        ),
      ],
    );

    await save();
    await db.close();
    db = RiderBizDatabase.forTesting(NativeDatabase(file));

    final restored = await RoutePlanStore(db).load(plan.id);
    expect(restored, isNotNull);
    expect(restored!.currentOrder, plan.currentOrder);
    expect(restored.stops, hasLength(60));
    expect(restored.tasks, hasLength(150));
    expect(restored.lockedStops.map((stop) => stop.id), [firstStop.id]);

    for (final stop in restored.stops) {
      expect(
        stop.walkingClusterId,
        stop.id == firstStop.id || stop.id == secondStop.id
            ? 'WALK-PERSISTED'
            : null,
      );
    }

    final task = restored.tasks.singleWhere((task) => task.id == firstTaskId);
    expect(task.priority, RoutePriority.urgent);
    expect(task.serviceDuration.inMicroseconds, 1500001);
    expect(task.timeWindow!.startsAt.toUtc(), windowStart);
    expect(task.timeWindow!.endsAt.toUtc(), windowEnd);
    expect(
      restored.tasks
          .where((task) => task.id != firstTaskId)
          .every(
            (task) =>
                task.priority == RoutePriority.low && task.timeWindow == null,
          ),
      isTrue,
    );

    final cluster = restored.walkingClusters.single;
    expect(cluster.id, 'WALK-PERSISTED');
    expect(cluster.stopIds, [firstStop.id, secondStop.id]);
    expect(cluster.anchor.latitude, anchor.latitude);
    expect(cluster.anchor.longitude, anchor.longitude);
  });
}
