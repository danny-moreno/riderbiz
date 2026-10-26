import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

void main() {
  late Directory directory;
  late File file;
  late RiderBizDatabase db;
  final acceptedAt = DateTime.utc(2026, 10, 26, 8);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rb_usual_order_');
    file = File('${directory.path}/route.sqlite');
    db = RiderBizDatabase.forTesting(NativeDatabase(file));
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<void> saveUsual() => AcceptedRouteStore(db).saveUsualOrder(
    routeId: 'ROUTE-USUAL',
    stopOrder: ['STOP-B', 'STOP-A'],
    acceptedAt: acceptedAt,
  );

  test(
    'restores usual order without invented metrics after reopening',
    () async {
      await saveUsual();
      await db.close();
      db = RiderBizDatabase.forTesting(NativeDatabase(file));

      final selection = await AcceptedRouteStore(db)
          .loadSelection('ROUTE-USUAL');
      expect(selection, isNotNull);
      expect(selection!.mode, RouteSelectionMode.usual);
      expect(selection.stopOrder, ['STOP-B', 'STOP-A']);
      expect(selection.acceptedAt, acceptedAt);
      expect(selection.metrics, isNull);
      expect(() => selection.stopOrder.add('STOP-C'), throwsUnsupportedError);

      final row = await db.select(db.acceptedRouteSnapshots).getSingle();
      final payload = jsonDecode(row.snapshotJson) as Map<String, dynamic>;
      expect(payload.keys.toSet(), {'version', 'mode', 'stopOrder'});
    },
  );

  test('reads legacy calculated routes through both interfaces', () async {
    final candidate = RouteCandidate(
      stopOrder: ['STOP-A', 'STOP-B'],
      vehicleLegs: const [],
      metrics: RouteMetrics(
        distanceMeters: 7000,
        travelDuration: const Duration(minutes: 20),
        serviceDuration: const Duration(minutes: 10),
        calculationDuration: Duration.zero,
      ),
      explanation: const OptimizationExplanation(summary: 'Synthetic test.'),
    );

    await AcceptedRouteStore(db).save(
      routeId: 'ROUTE-USUAL',
      candidate: candidate,
      acceptedAt: acceptedAt,
    );

    final legacy = await AcceptedRouteStore(db).load('ROUTE-USUAL');
    final selection = await AcceptedRouteStore(db).loadSelection('ROUTE-USUAL');

    expect(legacy!.metrics.distanceMeters, 7000);
    expect(selection!.mode, RouteSelectionMode.optimized);
    expect(selection.metrics!.distanceMeters, 7000);
    expect(selection.metrics!.totalDuration, const Duration(minutes: 30));
    expect(selection.stopOrder, candidate.stopOrder);
    expect(selection.acceptedAt, acceptedAt);

    await saveUsual();
    expect(
      (await AcceptedRouteStore(db).loadSelection('ROUTE-USUAL'))!.metrics,
      isNull,
    );

    await AcceptedRouteStore(db).save(
      routeId: 'ROUTE-USUAL',
      candidate: candidate,
      acceptedAt: acceptedAt,
    );
    expect(
      (await AcceptedRouteStore(db).loadSelection('ROUTE-USUAL'))!.mode,
      RouteSelectionMode.optimized,
    );
  });

  test(
    'rejects invalid usual orders without replacing saved selection',
    () async {
      await saveUsual();
      final before = await db.select(db.acceptedRouteSnapshots).getSingle();

      for (final order in <List<String>>[
        [],
        ['STOP-A', 'STOP-A'],
        ['STOP-A', ' '],
      ]) {
        await expectLater(
          AcceptedRouteStore(db).saveUsualOrder(
            routeId: 'ROUTE-USUAL',
            stopOrder: order,
            acceptedAt: acceptedAt.add(const Duration(hours: 1)),
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        AcceptedRouteStore(db).saveUsualOrder(
          routeId: ' ',
          stopOrder: ['STOP-A'],
          acceptedAt: acceptedAt,
        ),
        throwsArgumentError,
      );

      expect(await db.select(db.acceptedRouteSnapshots).getSingle(), before);
      expect(await AcceptedRouteStore(db).loadSelection('UNKNOWN'), isNull);
    },
  );
}
