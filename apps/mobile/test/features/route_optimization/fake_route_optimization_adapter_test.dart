import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/fake_route_optimization_adapter.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';

void main() {
  const adapter = FakeRouteOptimizationAdapter();

  RouteTask task({
    required String id,
    required String stopId,
    RouteTaskType type = RouteTaskType.delivery,
    RouteTaskStatus status = RouteTaskStatus.pending,
    RoutePriority priority = RoutePriority.normal,
    Duration serviceDuration = const Duration(minutes: 2),
    RouteTimeWindow? timeWindow,
  }) {
    return RouteTask(
      id: id,
      stopId: stopId,
      type: type,
      status: status,
      priority: priority,
      serviceDuration: serviceDuration,
      timeWindow: timeWindow,
    );
  }

  OperationalStop stop({
    required String id,
    required List<String> taskIds,
    bool isLocked = false,
  }) {
    return OperationalStop(
      id: id,
      coordinate: const RouteCoordinate(latitude: 42.8125, longitude: -1.6458),
      taskIds: taskIds,
      isLocked: isLocked,
    );
  }

  RouteOptimizationRequest request({
    required List<RouteTask> tasks,
    required List<OperationalStop> stops,
    required List<String> currentOrder,
    bool reoptimizePendingOnly = false,
    Duration timeout = const Duration(seconds: 1),
  }) {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYNTHETIC',
        currentOrder: currentOrder,
        stops: stops,
        tasks: tasks,
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.utc(2026, 10, 15, 8),
      timeout: timeout,
      reoptimizePendingOnly: reoptimizePendingOnly,
    );
  }

  group('FakeRouteOptimizationAdapter', () {
    test('orders pending stops by priority', () async {
      final result = await adapter.optimize(
        request(
          tasks: [
            task(id: 'TASK-A', stopId: 'STOP-A'),
            task(
              id: 'TASK-B',
              stopId: 'STOP-B',
              priority: RoutePriority.urgent,
            ),
            task(id: 'TASK-C', stopId: 'STOP-C', priority: RoutePriority.high),
          ],
          stops: [
            stop(id: 'STOP-A', taskIds: ['TASK-A']),
            stop(id: 'STOP-B', taskIds: ['TASK-B']),
            stop(id: 'STOP-C', taskIds: ['TASK-C']),
          ],
          currentOrder: ['STOP-A', 'STOP-B', 'STOP-C'],
        ),
      );

      expect(result.stopOrder, ['STOP-B', 'STOP-C', 'STOP-A']);
    });

    test('uses the earliest time window when priorities are equal', () async {
      final result = await adapter.optimize(
        request(
          tasks: [
            task(id: 'TASK-A', stopId: 'STOP-A'),
            task(
              id: 'TASK-B',
              stopId: 'STOP-B',
              timeWindow: RouteTimeWindow(
                startsAt: DateTime.utc(2026, 10, 15, 12),
                endsAt: DateTime.utc(2026, 10, 15, 13),
              ),
            ),
            task(
              id: 'TASK-C',
              stopId: 'STOP-C',
              timeWindow: RouteTimeWindow(
                startsAt: DateTime.utc(2026, 10, 15, 10),
                endsAt: DateTime.utc(2026, 10, 15, 11),
              ),
            ),
          ],
          stops: [
            stop(id: 'STOP-A', taskIds: ['TASK-A']),
            stop(id: 'STOP-B', taskIds: ['TASK-B']),
            stop(id: 'STOP-C', taskIds: ['TASK-C']),
          ],
          currentOrder: ['STOP-A', 'STOP-B', 'STOP-C'],
        ),
      );

      expect(result.stopOrder, ['STOP-C', 'STOP-B', 'STOP-A']);
    });

    test('preserves the position of a manually locked stop', () async {
      final result = await adapter.optimize(
        request(
          tasks: [
            task(id: 'TASK-A', stopId: 'STOP-A'),
            task(id: 'TASK-B', stopId: 'STOP-B'),
            task(
              id: 'TASK-C',
              stopId: 'STOP-C',
              priority: RoutePriority.urgent,
            ),
          ],
          stops: [
            stop(id: 'STOP-A', taskIds: ['TASK-A']),
            stop(id: 'STOP-B', taskIds: ['TASK-B'], isLocked: true),
            stop(id: 'STOP-C', taskIds: ['TASK-C']),
          ],
          currentOrder: ['STOP-A', 'STOP-B', 'STOP-C'],
          reoptimizePendingOnly: true,
        ),
      );

      expect(result.stopOrder, ['STOP-C', 'STOP-B', 'STOP-A']);
      expect(result.stopOrder.indexOf('STOP-B'), 1);
    });

    test(
      'excludes completed and cancelled tasks from reoptimization',
      () async {
        final result = await adapter.optimize(
          request(
            tasks: [
              task(
                id: 'TASK-A',
                stopId: 'STOP-A',
                status: RouteTaskStatus.completed,
              ),
              task(id: 'TASK-B', stopId: 'STOP-B'),
              task(
                id: 'TASK-C',
                stopId: 'STOP-C',
                status: RouteTaskStatus.cancelled,
              ),
            ],
            stops: [
              stop(id: 'STOP-A', taskIds: ['TASK-A']),
              stop(id: 'STOP-B', taskIds: ['TASK-B']),
              stop(id: 'STOP-C', taskIds: ['TASK-C']),
            ],
            currentOrder: ['STOP-A', 'STOP-B', 'STOP-C'],
            reoptimizePendingOnly: true,
          ),
        );

        expect(result.stopOrder, ['STOP-B']);
      },
    );

    test('represents deliveries and pickups in the same route', () async {
      final result = await adapter.optimize(
        request(
          tasks: [
            task(
              id: 'DELIVERY-A',
              stopId: 'STOP-A',
              type: RouteTaskType.delivery,
            ),
            task(
              id: 'PICKUP-B',
              stopId: 'STOP-B',
              type: RouteTaskType.pickup,
              priority: RoutePriority.high,
            ),
          ],
          stops: [
            stop(id: 'STOP-A', taskIds: ['DELIVERY-A']),
            stop(id: 'STOP-B', taskIds: ['PICKUP-B']),
          ],
          currentOrder: ['STOP-A', 'STOP-B'],
        ),
      );

      expect(result.stopOrder, ['STOP-B', 'STOP-A']);
      expect(result.metrics.serviceDuration, const Duration(minutes: 4));
    });

    test('returns deterministic synthetic metrics and explanation', () async {
      final result = await adapter.optimize(
        request(
          tasks: [
            task(id: 'TASK-A', stopId: 'STOP-A'),
            task(id: 'TASK-B', stopId: 'STOP-B'),
            task(id: 'TASK-C', stopId: 'STOP-C'),
          ],
          stops: [
            stop(id: 'STOP-A', taskIds: ['TASK-A']),
            stop(id: 'STOP-B', taskIds: ['TASK-B']),
            stop(id: 'STOP-C', taskIds: ['TASK-C']),
          ],
          currentOrder: ['STOP-A', 'STOP-B', 'STOP-C'],
        ),
      );

      expect(result.metrics.distanceMeters, 3000);
      expect(result.metrics.travelDuration, const Duration(minutes: 15));
      expect(result.metrics.serviceDuration, const Duration(minutes: 6));
      expect(result.vehicleLegs, hasLength(3));
      expect(result.explanation.summary, isNotEmpty);
      expect(result.explanation.warnings, isNotEmpty);
    });

    test('throws a typed failure when cancellation was requested', () async {
      final cancellationSignal = RouteOptimizationCancellationSignal()
        ..cancel();

      await expectLater(
        adapter.optimize(
          request(
            tasks: [task(id: 'TASK-A', stopId: 'STOP-A')],
            stops: [
              stop(id: 'STOP-A', taskIds: ['TASK-A']),
            ],
            currentOrder: ['STOP-A'],
          ),
          cancellationSignal: cancellationSignal,
        ),
        throwsA(
          isA<RouteOptimizationFailure>().having(
            (failure) => failure.type,
            'type',
            RouteOptimizationFailureType.cancelled,
          ),
        ),
      );
    });

    test(
      'does not return a candidate when cancelled during execution',
      () async {
        const delayedAdapter = FakeRouteOptimizationAdapter(
          simulatedLatency: Duration(milliseconds: 50),
        );
        final cancellationSignal = RouteOptimizationCancellationSignal();

        final operation = delayedAdapter.optimize(
          request(
            tasks: [task(id: 'TASK-A', stopId: 'STOP-A')],
            stops: [
              stop(id: 'STOP-A', taskIds: ['TASK-A']),
            ],
            currentOrder: ['STOP-A'],
          ),
          cancellationSignal: cancellationSignal,
        );

        final expectation = expectLater(
          operation,
          throwsA(
            isA<RouteOptimizationFailure>().having(
              (failure) => failure.type,
              'type',
              RouteOptimizationFailureType.cancelled,
            ),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        cancellationSignal.cancel();

        await expectation;
      },
    );
    test('throws a typed failure when the timeout is exceeded', () async {
      const slowAdapter = FakeRouteOptimizationAdapter(
        simulatedLatency: Duration(milliseconds: 50),
      );

      await expectLater(
        slowAdapter.optimize(
          request(
            tasks: [task(id: 'TASK-A', stopId: 'STOP-A')],
            stops: [
              stop(id: 'STOP-A', taskIds: ['TASK-A']),
            ],
            currentOrder: ['STOP-A'],
            timeout: const Duration(milliseconds: 1),
          ),
        ),
        throwsA(
          isA<RouteOptimizationFailure>().having(
            (failure) => failure.type,
            'type',
            RouteOptimizationFailureType.timeout,
          ),
        ),
      );
    });

    test('rejects a task that references an unknown stop', () async {
      await expectLater(
        adapter.optimize(
          request(
            tasks: [task(id: 'TASK-A', stopId: 'UNKNOWN-STOP')],
            stops: [
              stop(id: 'STOP-A', taskIds: ['TASK-A']),
            ],
            currentOrder: ['STOP-A'],
          ),
        ),
        throwsA(
          isA<RouteOptimizationFailure>().having(
            (failure) => failure.type,
            'type',
            RouteOptimizationFailureType.invalidRequest,
          ),
        ),
      );
    });
  });
}
