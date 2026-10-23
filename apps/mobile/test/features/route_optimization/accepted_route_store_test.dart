import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

void main() {
  late RiderBizDatabase database;
  late AcceptedRouteStore store;

  final acceptedAt = DateTime.utc(2026, 10, 24, 8);

  setUp(() {
    database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    store = AcceptedRouteStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  RouteCandidate candidate({
    List<String> order = const ['STOP-A', 'STOP-B'],
    int distance = 2501,
  }) {
    return RouteCandidate(
      stopOrder: order,
      vehicleLegs: const [],
      metrics: RouteMetrics(
        distanceMeters: distance,
        travelDuration: const Duration(seconds: 351),
        serviceDuration: const Duration(seconds: 240),
        waitingDuration: const Duration(seconds: 7),
        departureDelay: const Duration(seconds: 10),
        calculationDuration: const Duration(microseconds: 123456),
      ),
      explanation: const OptimizationExplanation(
        summary: 'Synthetic storage test.',
      ),
    );
  }

  test('returns null when no route has been accepted', () async {
    expect(await store.load('ROUTE-A'), isNull);
  });

  test('restores order, all metrics and acceptance time', () async {
    await store.save(
      routeId: 'ROUTE-A',
      candidate: candidate(),
      acceptedAt: acceptedAt,
    );

    final restored = await store.load('ROUTE-A');
    expect(restored, isNotNull);

    final snapshot = restored!;
    expect(snapshot.routeId, 'ROUTE-A');
    expect(snapshot.stopOrder, ['STOP-A', 'STOP-B']);
    expect(snapshot.acceptedAt, acceptedAt);
    expect(snapshot.metrics.distanceMeters, 2501);
    expect(snapshot.metrics.travelDuration, const Duration(seconds: 351));
    expect(snapshot.metrics.serviceDuration, const Duration(seconds: 240));
    expect(snapshot.metrics.waitingDuration, const Duration(seconds: 7));
    expect(snapshot.metrics.departureDelay, const Duration(seconds: 10));
    expect(
      snapshot.metrics.calculationDuration,
      const Duration(microseconds: 123456),
    );
    expect(snapshot.metrics.totalDuration, const Duration(seconds: 608));

    expect(() => snapshot.stopOrder.add('STOP-C'), throwsUnsupportedError);
  });

  test('replaces only the explicitly accepted route', () async {
    for (final id in ['ROUTE-A', 'ROUTE-B']) {
      await store.save(
        routeId: id,
        candidate: candidate(),
        acceptedAt: acceptedAt,
      );
    }

    final nextAcceptance = acceptedAt.add(const Duration(minutes: 5));

    await store.save(
      routeId: 'ROUTE-A',
      candidate: candidate(order: ['STOP-B', 'STOP-A'], distance: 2400),
      acceptedAt: nextAcceptance,
    );

    final replaced = (await store.load('ROUTE-A'))!;
    final untouched = (await store.load('ROUTE-B'))!;

    expect(replaced.stopOrder, ['STOP-B', 'STOP-A']);
    expect(replaced.metrics.distanceMeters, 2400);
    expect(replaced.acceptedAt, nextAcceptance);

    expect(untouched.stopOrder, ['STOP-A', 'STOP-B']);
    expect(untouched.metrics.distanceMeters, 2501);
    expect(untouched.acceptedAt, acceptedAt);

    expect(
      await database.select(database.acceptedRouteSnapshots).get(),
      hasLength(2),
    );
  });

  test('deletes only the requested route', () async {
    for (final id in ['ROUTE-A', 'ROUTE-B']) {
      await store.save(
        routeId: id,
        candidate: candidate(),
        acceptedAt: acceptedAt,
      );
    }

    await store.delete('ROUTE-A');
    await store.delete('ROUTE-A');

    expect(await store.load('ROUTE-A'), isNull);
    expect(await store.load('ROUTE-B'), isNotNull);
  });

  test(
    'rejects duplicate stops without replacing the accepted route',
    () async {
      await store.save(
        routeId: 'ROUTE-A',
        candidate: candidate(),
        acceptedAt: acceptedAt,
      );

      await expectLater(
        store.save(
          routeId: 'ROUTE-A',
          candidate: candidate(order: ['STOP-A', 'STOP-A']),
          acceptedAt: acceptedAt.add(const Duration(minutes: 5)),
        ),
        throwsArgumentError,
      );

      final restored = (await store.load('ROUTE-A'))!;
      expect(restored.stopOrder, ['STOP-A', 'STOP-B']);
      expect(restored.acceptedAt, acceptedAt);
    },
  );

  test('reports an unsupported stored snapshot without deleting it', () async {
    await database
        .into(database.acceptedRouteSnapshots)
        .insert(
          AcceptedRouteSnapshotsCompanion(
            routeId: const Value('ROUTE-A'),
            snapshotJson: const Value('{"version":999}'),
            acceptedAt: Value(acceptedAt),
          ),
        );

    await expectLater(store.load('ROUTE-A'), throwsFormatException);

    expect(
      await database.select(database.acceptedRouteSnapshots).get(),
      hasLength(1),
    );
  });
}
