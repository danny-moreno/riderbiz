import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/daily_session/synthetic_daily_session_service.dart';
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

void main() {
  late Directory directory;
  late File file;
  late RiderBizDatabase db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rb_daily_service_');
    file = File('${directory.path}/daily.sqlite');
    db = RiderBizDatabase.forTesting(NativeDatabase(file));
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<void> acceptStops(List<String> stops) async {
    await AcceptedRouteStore(db).save(
      routeId: SyntheticDailySessionService.routeId,
      candidate: RouteCandidate(
        stopOrder: stops,
        vehicleLegs: const [],
        metrics: RouteMetrics(
          distanceMeters: 1000,
          travelDuration: const Duration(minutes: 10),
          serviceDuration: const Duration(minutes: 150),
          calculationDuration: Duration.zero,
        ),
        explanation: const OptimizationExplanation(
          summary: 'Synthetic service test; no routing engine.',
        ),
      ),
      acceptedAt: DateTime.now().toUtc(),
    );
  }

  test('prepares once and restores partial progress after reopening', () async {
    final service = SyntheticDailySessionService(db);
    await service.prepare();
    final plan = await service.loadPlan();
    expect(plan.tasks, hasLength(150));
    expect(plan.stops, hasLength(60));

    final firstStop = plan.stops.first;
    expect(firstStop.taskIds.length, greaterThan(1));
    final packageId = firstStop.taskIds.first;

    await acceptStops(plan.currentOrder);
    await service.confirmPackage(packageId);
    await service.prepare();

    await db.close();
    db = RiderBizDatabase.forTesting(NativeDatabase(file));

    final restoredService = SyntheticDailySessionService(db);
    await restoredService.prepare();
    final restored = await restoredService.loadPlan();

    expect(restored.tasks, hasLength(150));
    expect(restored.pendingTasks, hasLength(149));
    expect(
      restored.tasks.singleWhere((task) => task.id == packageId).status,
      RouteTaskStatus.completed,
    );
    expect(
      restored.pendingTasks.any((task) => task.stopId == firstStop.id),
      isTrue,
    );

    await expectLater(
      restoredService.confirmPackage(packageId),
      throwsStateError,
    );

    final events = await db.select(db.deliveryEvents).get();
    expect(events, hasLength(1));
    expect(events.single.packageId, packageId);
    expect(events.single.id, 'DAILY-DELIVERED-$packageId');

    final packages = await db.select(db.syntheticPackages).get();
    final delivered = packages.where(
      (package) => package.status == 'delivered',
    );
    expect(delivered, hasLength(1));
    expect(delivered.single.unitPriceMinorSnapshot, 120);
    expect(delivered.single.currencySnapshot, 'EUR');
    expect(await db.select(db.deliveryRuns).get(), hasLength(1));
    expect(await db.select(db.logisticsOperators).get(), hasLength(1));
    expect(await db.select(db.operatorTariffs).get(), hasLength(1));
    expect(await db.select(db.routePlanDefinitions).get(), hasLength(1));
  });

  test('rejects confirmation without an accepted route', () async {
    final service = SyntheticDailySessionService(db);
    await service.prepare();
    final plan = await service.loadPlan();

    await expectLater(
      service.confirmPackage(plan.tasks.first.id),
      throwsStateError,
    );
    expect((await service.loadPlan()).pendingTasks, hasLength(150));
    expect(await db.select(db.deliveryEvents).get(), isEmpty);
  });

  test(
    'rejects unknown packages and stops outside the accepted route',
    () async {
      final service = SyntheticDailySessionService(db);
      await service.prepare();
      final plan = await service.loadPlan();
      await acceptStops([plan.stops.first.id]);

      await expectLater(
        service.confirmPackage('UNKNOWN-PACKAGE'),
        throwsStateError,
      );
      await expectLater(
        service.confirmPackage(plan.stops[1].taskIds.first),
        throwsStateError,
      );
      expect((await service.loadPlan()).pendingTasks, hasLength(150));
      expect(await db.select(db.deliveryEvents).get(), isEmpty);
    },
  );

  test(
    'restores usual order and delivery progress from disk without optimization',
    () async {
      final service = SyntheticDailySessionService(db);
      await service.prepare();
      final initial = await service.loadPlan();

      expect(await AcceptedRouteStore(db).loadSelection(initial.id), isNull);

      await service.useUsualOrder();
      final selected = await AcceptedRouteStore(db).loadSelection(initial.id);
      expect(selected!.mode, RouteSelectionMode.usual);
      expect(selected.metrics, isNull);
      expect(selected.stopOrder, initial.currentOrder);

      final firstStop = initial.stops.first;
      expect(firstStop.taskIds.length, greaterThan(1));
      final firstPackage = firstStop.taskIds.first;
      final secondPackage = firstStop.taskIds[1];
      await service.confirmPackage(firstPackage);

      await db.close();
      db = RiderBizDatabase.forTesting(NativeDatabase(file));
      final restoredService = SyntheticDailySessionService(db);
      await restoredService.prepare();

      final restored = await restoredService.loadPlan();
      final selection = await AcceptedRouteStore(db).loadSelection(initial.id);
      expect(restored.pendingTasks, hasLength(149));
      expect(
        restored.tasks.singleWhere((task) => task.id == firstPackage).status,
        RouteTaskStatus.completed,
      );
      expect(selection!.mode, RouteSelectionMode.usual);
      expect(selection.stopOrder, selected.stopOrder);
      expect(selection.acceptedAt, selected.acceptedAt);
      expect(selection.metrics, isNull);

      await expectLater(
        restoredService.confirmPackage(firstPackage),
        throwsStateError,
      );
      await restoredService.confirmPackage(secondPackage);

      await db.close();
      db = RiderBizDatabase.forTesting(NativeDatabase(file));

      final finalPlan = await SyntheticDailySessionService(db).loadPlan();
      expect(finalPlan.pendingTasks, hasLength(148));
      final packages = await db.select(db.syntheticPackages).get();
      expect(packages, hasLength(150));
      final delivered = packages.where(
        (package) => package.status == 'delivered',
      );
      expect(delivered.map((package) => package.id).toSet(), {
        firstPackage,
        secondPackage,
      });
      expect(
        delivered.fold<int>(
          0,
          (total, package) => total + package.unitPriceMinorSnapshot!,
        ),
        240,
      );
      expect(
        delivered.every((package) => package.currencySnapshot == 'EUR'),
        isTrue,
      );
      final events = await db.select(db.deliveryEvents).get();
      expect(events, hasLength(2));
      expect(events.map((event) => event.packageId).toSet(), {
        firstPackage,
        secondPackage,
      });

      final finalSelection = await AcceptedRouteStore(db)
          .loadSelection(initial.id);
      expect(finalSelection!.stopOrder, selected.stopOrder);
      expect(finalSelection.acceptedAt, selected.acceptedAt);
      expect(finalSelection.metrics, isNull);
    },
  );
}
