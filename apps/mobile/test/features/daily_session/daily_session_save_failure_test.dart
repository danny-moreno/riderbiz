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
  late RoutePlan plan;
  final acceptedAt = DateTime.utc(2026, 10, 26, 8);

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
        summary: 'Synthetic SQLite failure test.',
      ),
    );
  }

  Future<void> reopen() async {
    await db.close();
    db = RiderBizDatabase.forTesting(NativeDatabase(file));
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rb_daily_failure_');
    file = File('${directory.path}/daily.sqlite');
    db = RiderBizDatabase.forTesting(NativeDatabase(file));
    final service = SyntheticDailySessionService(db);
    await service.prepare();
    plan = await service.loadPlan();

    await AcceptedRouteStore(db).save(
      routeId: plan.id,
      candidate: candidate(plan.currentOrder, 7000),
      acceptedAt: acceptedAt,
    );
    await service.confirmPackage(plan.tasks.first.id);
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'rolls back delivery when event insertion fails and allows retry',
    () async {
      final packageId = plan.tasks[1].id;
      final packagesBefore = await db.select(db.syntheticPackages).get();
      final eventsBefore = await db.select(db.deliveryEvents).get();
      final routesBefore = await db.select(db.acceptedRouteSnapshots).get();

      expect(eventsBefore, hasLength(1));

      await db.customStatement('''
      CREATE TRIGGER reject_daily_event
      BEFORE INSERT ON delivery_events
      BEGIN
        SELECT RAISE(ABORT, 'synthetic_event_write_failure');
      END
    ''');

      await expectLater(
        SyntheticDailySessionService(db).confirmPackage(packageId),
        throwsA(
          predicate<Object>(
            (error) =>
                error.toString().contains('synthetic_event_write_failure'),
          ),
        ),
      );

      await reopen();

      expect(await db.select(db.syntheticPackages).get(), packagesBefore);
      expect(await db.select(db.deliveryEvents).get(), eventsBefore);
      expect(await db.select(db.acceptedRouteSnapshots).get(), routesBefore);
      expect(
        (await SyntheticDailySessionService(db).loadPlan()).pendingTasks,
        hasLength(149),
      );

      await db.customStatement('DROP TRIGGER reject_daily_event');
      await SyntheticDailySessionService(db).confirmPackage(packageId);
      await reopen();

      final packages = await db.select(db.syntheticPackages).get();
      final delivered = packages.where(
        (package) => package.status == 'delivered',
      );
      expect(packages, hasLength(150));
      expect(delivered, hasLength(2));
      expect(
        delivered.fold<int>(
          0,
          (total, package) => total + package.unitPriceMinorSnapshot!,
        ),
        240,
      );
      final target = packages.singleWhere((package) => package.id == packageId);
      expect(target.unitPriceMinorSnapshot, 120);
      expect(target.currencySnapshot, 'EUR');

      final events = await db.select(db.deliveryEvents).get();
      expect(events, hasLength(2));
      expect(
        events.where((event) => event.packageId == packageId),
        hasLength(1),
      );
      expect(await db.select(db.acceptedRouteSnapshots).get(), routesBefore);
    },
  );

  test(
    'preserves accepted route when replacement fails and allows retry',
    () async {
      final routesBefore = await db.select(db.acceptedRouteSnapshots).get();
      final packagesBefore = await db.select(db.syntheticPackages).get();
      final eventsBefore = await db.select(db.deliveryEvents).get();
      final replacement = candidate(plan.currentOrder.reversed.toList(), 6500);
      final replacementAt = acceptedAt.add(const Duration(hours: 2));

      await db.customStatement('''
      CREATE TRIGGER reject_daily_route_update
      BEFORE UPDATE ON accepted_route_snapshots
      BEGIN
        SELECT RAISE(ABORT, 'synthetic_route_write_failure');
      END
    ''');

      await expectLater(
        AcceptedRouteStore(db).save(
          routeId: plan.id,
          candidate: replacement,
          acceptedAt: replacementAt,
        ),
        throwsA(
          predicate<Object>(
            (error) =>
                error.toString().contains('synthetic_route_write_failure'),
          ),
        ),
      );

      await reopen();

      expect(await db.select(db.acceptedRouteSnapshots).get(), routesBefore);
      expect(await db.select(db.syntheticPackages).get(), packagesBefore);
      expect(await db.select(db.deliveryEvents).get(), eventsBefore);

      await db.customStatement('DROP TRIGGER reject_daily_route_update');
      await AcceptedRouteStore(db).save(
        routeId: plan.id,
        candidate: replacement,
        acceptedAt: replacementAt,
      );
      await reopen();

      final restored = await AcceptedRouteStore(db).load(plan.id);
      expect(restored, isNotNull);
      expect(restored!.stopOrder, replacement.stopOrder);
      expect(restored.acceptedAt, replacementAt);
      expect(restored.metrics.distanceMeters, 6500);
      expect(restored.metrics.totalDuration, replacement.metrics.totalDuration);
      expect(await db.select(db.syntheticPackages).get(), packagesBefore);
      expect(await db.select(db.deliveryEvents).get(), eventsBefore);
    },
  );
}
