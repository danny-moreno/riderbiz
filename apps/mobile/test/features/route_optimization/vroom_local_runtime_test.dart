import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');

  test(
    'optimizes two synthetic stops through local VROOM and OSRM',
    () async {
      final adapter = VroomRouteOptimizationAdapter(
        endpoint: Uri.parse('http://127.0.0.1:3000/'),
      );

      final request = RouteOptimizationRequest(
        plan: RoutePlan(
          id: 'ROUTE-SYN-LOCAL',
          currentOrder: ['STOP-A', 'STOP-B'],
          stops: [
            OperationalStop(
              id: 'STOP-A',
              coordinate: const RouteCoordinate(
                latitude: 42.8100,
                longitude: -1.6400,
              ),
              taskIds: ['TASK-A'],
            ),
            OperationalStop(
              id: 'STOP-B',
              coordinate: const RouteCoordinate(
                latitude: 42.8150,
                longitude: -1.6350,
              ),
              taskIds: ['TASK-B'],
            ),
          ],
          tasks: [
            RouteTask(
              id: 'TASK-A',
              stopId: 'STOP-A',
              type: RouteTaskType.delivery,
              status: RouteTaskStatus.pending,
              priority: RoutePriority.normal,
              serviceDuration: const Duration(seconds: 120),
            ),
            RouteTask(
              id: 'TASK-B',
              stopId: 'STOP-B',
              type: RouteTaskType.pickup,
              status: RouteTaskStatus.pending,
              priority: RoutePriority.normal,
              serviceDuration: const Duration(seconds: 120),
            ),
          ],
        ),
        currentLocation: const RouteCoordinate(
          latitude: 42.8125,
          longitude: -1.6458,
        ),
        departureAt: DateTime.utc(2026, 10, 18, 8),
        timeout: const Duration(seconds: 40),
      );

      final candidate = await adapter.optimize(request);

      expect(candidate.stopOrder, hasLength(2));
      expect(candidate.stopOrder.toSet(), {'STOP-A', 'STOP-B'});
      expect(candidate.vehicleLegs, hasLength(2));
      expect(candidate.metrics.distanceMeters, greaterThan(0));
      expect(candidate.metrics.travelDuration, greaterThan(Duration.zero));
      expect(candidate.metrics.serviceDuration, const Duration(seconds: 240));
      expect(candidate.metrics.waitingDuration, Duration.zero);

      final legDistance = candidate.vehicleLegs.fold<int>(
        0,
        (total, leg) => total + leg.distanceMeters,
      );
      final legDuration = candidate.vehicleLegs.fold<Duration>(
        Duration.zero,
        (total, leg) => total + leg.duration,
      );

      expect(legDistance, candidate.metrics.distanceMeters);
      expect(legDuration, candidate.metrics.travelDuration);
      expect(
        candidate.metrics.totalDuration,
        candidate.metrics.travelDuration +
            candidate.metrics.serviceDuration +
            candidate.metrics.waitingDuration,
      );
      expect(candidate.explanation.summary, isNotEmpty);
    },
    skip: enabled ? false : 'Requires RUN_LOCAL_VROOM=true and local services.',
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
