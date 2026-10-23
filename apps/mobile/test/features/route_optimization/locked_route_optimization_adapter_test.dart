import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/locked_route_optimization_adapter.dart';
import 'package:riderbiz_mobile/features/route_optimization/osrm_direct_leg_client.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

class TestVroomAdapter extends VroomRouteOptimizationAdapter {
  TestVroomAdapter() : super(endpoint: Uri.parse('http://127.0.0.1:3000/'));

  final requests = <RouteOptimizationRequest>[];
  final destinations = <RouteCoordinate?>[];
  RouteOptimizationCancellationSignal? cancelAfterCall;
  RouteOptimizationFailure? failureToThrow;

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
    RouteCoordinate? endLocation,
  }) async {
    cancellationSignal?.throwIfCancelled();
    requests.add(request);
    destinations.add(endLocation);
    final configuredFailure = failureToThrow;
    if (configuredFailure != null) {
      throw configuredFailure;
    }

    final order = request.plan.currentOrder.reversed.toList();
    final legs = <VehicleLeg>[];
    var previous = 'CURRENT_LOCATION';

    for (final id in order) {
      legs.add(
        VehicleLeg(
          fromStopId: previous,
          toStopId: id,
          distanceMeters: 100,
          duration: const Duration(seconds: 10),
        ),
      );
      previous = id;
    }

    if (endLocation != null) {
      legs.add(
        VehicleLeg(
          fromStopId: previous,
          toStopId: 'END_LOCATION',
          distanceMeters: 100,
          duration: const Duration(seconds: 10),
        ),
      );
    }

    cancelAfterCall?.cancel();

    return RouteCandidate(
      stopOrder: order,
      vehicleLegs: legs,
      metrics: RouteMetrics(
        distanceMeters: legs.length * 100,
        travelDuration: Duration(seconds: legs.length * 10),
        serviceDuration: request.plan.pendingTasks.fold<Duration>(
          Duration.zero,
          (total, task) => total + task.serviceDuration,
        ),
        calculationDuration: Duration.zero,
      ),
      explanation: const OptimizationExplanation(summary: 'Synthetic segment.'),
    );
  }
}

class TestDirectLegClient extends OsrmDirectLegClient {
  TestDirectLegClient() : super(endpoint: Uri.parse('http://127.0.0.1:5000/'));

  final connections = <String>[];
  RouteOptimizationFailure? failureToThrow;

  @override
  Future<VehicleLeg> calculate({
    required String fromStopId,
    required String toStopId,
    required RouteCoordinate from,
    required RouteCoordinate to,
    required Duration timeout,
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.throwIfCancelled();
    connections.add('$fromStopId->$toStopId');
    final configuredFailure = failureToThrow;
    if (configuredFailure != null) {
      throw configuredFailure;
    }

    return VehicleLeg(
      fromStopId: fromStopId,
      toStopId: toStopId,
      distanceMeters: 100,
      duration: const Duration(seconds: 10),
    );
  }
}

void main() {
  late TestVroomAdapter vroom;
  late TestDirectLegClient osrm;
  late LockedRouteOptimizationAdapter adapter;

  setUp(() {
    vroom = TestVroomAdapter();
    osrm = TestDirectLegClient();
    adapter = LockedRouteOptimizationAdapter(vroom: vroom, osrm: osrm);
  });

  RouteOptimizationRequest request({
    Set<String> locked = const {},
    Set<String> completed = const {},
    bool withWindow = false,
  }) {
    final departure = DateTime.utc(2026, 10, 23, 8);
    const ids = ['A', 'B', 'C', 'D', 'E'];

    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-COORDINATOR',
        currentOrder: ids,
        stops: [
          for (var index = 0; index < ids.length; index++)
            OperationalStop(
              id: ids[index],
              coordinate: RouteCoordinate(
                latitude: 42.81 + index * 0.001,
                longitude: -1.64,
              ),
              taskIds: ['TASK-${ids[index]}'],
              isLocked: locked.contains(ids[index]),
            ),
        ],
        tasks: [
          for (final id in ids)
            RouteTask(
              id: 'TASK-$id',
              stopId: id,
              type: RouteTaskType.delivery,
              status: completed.contains(id)
                  ? RouteTaskStatus.completed
                  : RouteTaskStatus.pending,
              priority: RoutePriority.normal,
              serviceDuration: const Duration(seconds: 120),
              timeWindow: withWindow
                  ? RouteTimeWindow(
                      startsAt: departure,
                      endsAt: departure.add(const Duration(hours: 8)),
                    )
                  : null,
            ),
        ],
      ),
      currentLocation: const RouteCoordinate(latitude: 42.80, longitude: -1.64),
      departureAt: departure,
      timeout: const Duration(seconds: 5),
      reoptimizePendingOnly: true,
    );
  }

  void expectContinuous(RouteCandidate candidate) {
    expect(candidate.vehicleLegs, hasLength(candidate.stopOrder.length));

    for (var index = 0; index < candidate.stopOrder.length; index++) {
      final leg = candidate.vehicleLegs[index];
      expect(
        leg.fromStopId,
        index == 0 ? 'CURRENT_LOCATION' : candidate.stopOrder[index - 1],
      );
      expect(leg.toStopId, candidate.stopOrder[index]);
    }
  }

  Matcher failure(RouteOptimizationFailureType type) {
    return throwsA(
      isA<RouteOptimizationFailure>().having(
        (error) => error.type,
        'type',
        type,
      ),
    );
  }

  group('LockedRouteOptimizationAdapter', () {
    test('optimizes an unlocked route as one open segment', () async {
      final result = await adapter.optimize(request());

      expect(result.stopOrder, ['E', 'D', 'C', 'B', 'A']);
      expect(vroom.requests, hasLength(1));
      expect(vroom.destinations.single, isNull);
      expect(osrm.connections, isEmpty);
      expectContinuous(result);
    });

    test('preserves a middle lock and counts service once', () async {
      final input = request(locked: {'C'});
      final result = await adapter.optimize(input);

      expect(result.stopOrder, ['B', 'A', 'C', 'E', 'D']);
      expect(vroom.requests, hasLength(2));
      expect(vroom.destinations.first, input.plan.stops[2].coordinate);
      expect(vroom.destinations.last, isNull);
      expect(result.metrics.distanceMeters, 500);
      expect(result.metrics.travelDuration, const Duration(seconds: 50));
      expect(result.metrics.serviceDuration, const Duration(seconds: 600));
      expect(result.metrics.totalDuration, const Duration(seconds: 650));
      expect(
        vroom.requests.last.departureAt,
        input.departureAt.add(const Duration(seconds: 390)),
      );
      expectContinuous(result);
    });

    test('uses a direct leg for a locked first stop', () async {
      final result = await adapter.optimize(request(locked: {'A'}));

      expect(result.stopOrder, ['A', 'E', 'D', 'C', 'B']);
      expect(osrm.connections, ['CURRENT_LOCATION->A']);
      expectContinuous(result);
    });

    test('uses a direct leg between consecutive locks', () async {
      final result = await adapter.optimize(request(locked: {'B', 'C'}));

      expect(result.stopOrder, ['A', 'B', 'C', 'E', 'D']);
      expect(osrm.connections, ['B->C']);
      expect(result.metrics.serviceDuration, const Duration(seconds: 600));
      expectContinuous(result);
    });

    test('handles every stop locked without calling VROOM', () async {
      final result = await adapter.optimize(
        request(locked: {'A', 'B', 'C', 'D', 'E'}),
      );

      expect(result.stopOrder, ['A', 'B', 'C', 'D', 'E']);
      expect(vroom.requests, isEmpty);
      expect(osrm.connections, hasLength(5));
      expect(result.metrics.totalDuration, const Duration(seconds: 650));
      expectContinuous(result);
    });

    test('excludes completed tasks before locating locks', () async {
      final result = await adapter.optimize(
        request(locked: {'C'}, completed: {'A'}),
      );

      expect(result.stopOrder, ['B', 'C', 'E', 'D']);
      expect(result.metrics.serviceDuration, const Duration(seconds: 480));
      expectContinuous(result);
    });

    test(
      'returns an empty route without network calls when completed',
      () async {
        final result = await adapter.optimize(
          request(completed: {'A', 'B', 'C', 'D', 'E'}),
        );

        expect(result.stopOrder, isEmpty);
        expect(result.vehicleLegs, isEmpty);
        expect(result.metrics.totalDuration, Duration.zero);
        expect(vroom.requests, isEmpty);
        expect(osrm.connections, isEmpty);
      },
    );

    test('rejects time windows before calling either client', () async {
      await expectLater(
        adapter.optimize(request(locked: {'C'}, withWindow: true)),
        failure(RouteOptimizationFailureType.invalidRequest),
      );

      expect(vroom.requests, isEmpty);
      expect(osrm.connections, isEmpty);
    });

    test('stops when VROOM fails before completing a segment', () async {
      const configuredFailure = RouteOptimizationFailure(
        type: RouteOptimizationFailureType.unavailable,
        message: 'Synthetic VROOM failure.',
      );
      vroom.failureToThrow = configuredFailure;

      await expectLater(
        adapter.optimize(request(locked: {'C'})),
        throwsA(same(configuredFailure)),
      );

      expect(vroom.requests, hasLength(1));
      expect(osrm.connections, isEmpty);
    });

    test('stops when a direct leg fails after a completed segment', () async {
      const configuredFailure = RouteOptimizationFailure(
        type: RouteOptimizationFailureType.unavailable,
        message: 'Synthetic OSRM failure.',
      );
      osrm.failureToThrow = configuredFailure;

      await expectLater(
        adapter.optimize(request(locked: {'B', 'C'})),
        throwsA(same(configuredFailure)),
      );

      expect(vroom.requests, hasLength(1));
      expect(vroom.requests.single.plan.currentOrder, ['A']);
      expect(osrm.connections, ['B->C']);
    });

    test('stops between segments when cancellation is requested', () async {
      final signal = RouteOptimizationCancellationSignal();
      vroom.cancelAfterCall = signal;

      await expectLater(
        adapter.optimize(request(locked: {'C'}), cancellationSignal: signal),
        failure(RouteOptimizationFailureType.cancelled),
      );

      expect(vroom.requests, hasLength(1));
      expect(osrm.connections, isEmpty);
    });
  });
}
