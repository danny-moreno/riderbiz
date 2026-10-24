import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/synthetic_route_delivery_service.dart';

void main() {
  late RiderBizDatabase database;
  late SyntheticRouteDeliveryService service;

  final acceptedAt = DateTime.utc(2026, 10, 24, 8);
  final deliveredAt = DateTime.utc(2026, 10, 24, 9);

  setUp(() {
    database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    service = SyntheticRouteDeliveryService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> acceptRoute({List<String> order = const ['STOP-A', 'STOP-B']}) {
    return AcceptedRouteStore(database).save(
      routeId: SyntheticRouteDeliveryService.routeId,
      candidate: RouteCandidate(
        stopOrder: order,
        vehicleLegs: const [],
        metrics: RouteMetrics(
          distanceMeters: 2501,
          travelDuration: const Duration(seconds: 351),
          serviceDuration: const Duration(seconds: 240),
          calculationDuration: Duration.zero,
        ),
        explanation: const OptimizationExplanation(
          summary: 'Synthetic delivery test.',
        ),
      ),
      acceptedAt: acceptedAt,
    );
  }

  test('prepares two pending packages without duplicating records', () async {
    await service.prepare();
    await service.prepare();

    final progress = await service.loadProgress();

    expect(progress.keys, unorderedEquals(['STOP-A', 'STOP-B']));
    expect(progress['STOP-A']!.status, 'pending');
    expect(progress['STOP-B']!.status, 'pending');

    expect(
      await database.select(database.logisticsOperators).get(),
      hasLength(1),
    );
    expect(await database.select(database.operatorTariffs).get(), hasLength(1));
    expect(await database.select(database.deliveryRuns).get(), hasLength(1));
    expect(
      await database.select(database.syntheticPackages).get(),
      hasLength(2),
    );
    expect(await database.select(database.deliveryEvents).get(), isEmpty);
  });

  test('rejects confirmation before a route is accepted', () async {
    await service.prepare();

    await expectLater(
      service.confirmStop(stopId: 'STOP-A', deliveredAt: deliveredAt),
      throwsStateError,
    );

    final progress = await service.loadProgress();
    expect(progress['STOP-A']!.status, 'pending');
    expect(await database.select(database.deliveryEvents).get(), isEmpty);
  });

  test('confirms a stop and preserves it when preparing again', () async {
    await service.prepare();
    await acceptRoute();

    final delivered = await service.confirmStop(
      stopId: 'STOP-A',
      deliveredAt: deliveredAt,
    );

    expect(delivered.status, 'delivered');
    expect(delivered.unitPriceMinorSnapshot, 1);
    expect(delivered.currencySnapshot, 'EUR');
    expect(delivered.deliveredAt?.toUtc(), deliveredAt);

    await service.prepare();
    final progress = await service.loadProgress();

    expect(progress['STOP-A']!.status, 'delivered');
    expect(progress['STOP-B']!.status, 'pending');

    final events = await database.select(database.deliveryEvents).get();
    expect(events, hasLength(1));
    expect(events.single.packageId, 'RB-SYN-ROUTE-A');
    expect(events.single.eventType, 'delivered');

    final accepted = await AcceptedRouteStore(database)
        .load(SyntheticRouteDeliveryService.routeId);
    expect(accepted!.stopOrder, ['STOP-A', 'STOP-B']);
  });

  test('rejects a second confirmation without duplicating events', () async {
    await service.prepare();
    await acceptRoute();

    await service.confirmStop(stopId: 'STOP-A', deliveredAt: deliveredAt);

    await expectLater(
      service.confirmStop(
        stopId: 'STOP-A',
        deliveredAt: deliveredAt.add(const Duration(minutes: 1)),
      ),
      throwsStateError,
    );

    expect(await database.select(database.deliveryEvents).get(), hasLength(1));
    final progress = await service.loadProgress();
    expect(progress['STOP-A']!.deliveredAt?.toUtc(), deliveredAt);
  });

  test('rejects a known stop absent from the accepted route', () async {
    await service.prepare();
    await acceptRoute(order: ['STOP-A']);

    await expectLater(
      service.confirmStop(stopId: 'STOP-B', deliveredAt: deliveredAt),
      throwsStateError,
    );

    final progress = await service.loadProgress();
    expect(progress['STOP-B']!.status, 'pending');
    expect(await database.select(database.deliveryEvents).get(), isEmpty);
  });

  test('rejects an unknown stop', () async {
    await service.prepare();
    await acceptRoute();

    expect(
      () =>
          service.confirmStop(stopId: 'STOP-UNKNOWN', deliveredAt: deliveredAt),
      throwsArgumentError,
    );

    expect(await database.select(database.deliveryEvents).get(), isEmpty);
  });
}
