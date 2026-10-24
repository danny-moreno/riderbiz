import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_request_validator.dart';

import '../../support/route_optimization/synthetic_route_scenario_factory.dart';

void main() {
  const validator = RouteOptimizationRequestValidator();
  const factory = SyntheticRouteScenarioFactory();
  const coordinate = RouteCoordinate(latitude: 42.81, longitude: -1.64);

  RouteTask task(String id, String stopId) {
    return RouteTask(
      id: id,
      stopId: stopId,
      type: RouteTaskType.delivery,
      status: RouteTaskStatus.pending,
      priority: RoutePriority.normal,
      serviceDuration: const Duration(minutes: 2),
    );
  }

  OperationalStop stop({
    String id = 'STOP-A',
    List<String> taskIds = const ['TASK-A'],
    bool isLocked = false,
    String? clusterId,
  }) {
    return OperationalStop(
      id: id,
      coordinate: coordinate,
      taskIds: taskIds,
      isLocked: isLocked,
      walkingClusterId: clusterId,
    );
  }

  WalkingCluster cluster({
    String id = 'WALK-A',
    List<String> stopIds = const ['STOP-A'],
  }) {
    return WalkingCluster(id: id, stopIds: stopIds, anchor: coordinate);
  }

  RouteOptimizationRequest request({
    required List<OperationalStop> stops,
    required List<RouteTask> tasks,
    List<String> order = const ['STOP-A'],
    List<WalkingCluster> clusters = const [],
  }) {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-VALIDATION',
        currentOrder: order,
        stops: stops,
        tasks: tasks,
        walkingClusters: clusters,
      ),
      currentLocation: coordinate,
      departureAt: DateTime.utc(2026, 10, 15, 8),
      timeout: const Duration(seconds: 10),
    );
  }

  void expectInvalid(RouteOptimizationRequest input) {
    expect(
      () => validator.validate(input),
      throwsA(
        isA<RouteOptimizationFailure>().having(
          (failure) => failure.type,
          'type',
          RouteOptimizationFailureType.invalidRequest,
        ),
      ),
    );
  }

  group('RouteOptimizationRequestValidator', () {
    for (final count in [60, 80, 120]) {
      test('accepts the valid $count task scenario', () {
        final scenario = factory.create(taskCount: count);

        expect(() => validator.validate(scenario.request), returnsNormally);
      });
    }

    test('rejects duplicate stop identifiers', () {
      expectInvalid(
        request(stops: [stop(), stop()], tasks: [task('TASK-A', 'STOP-A')]),
      );
    });

    test('rejects duplicate task identifiers', () {
      expectInvalid(
        request(
          stops: [stop()],
          tasks: [task('TASK-A', 'STOP-A'), task('TASK-A', 'STOP-A')],
        ),
      );
    });

    test('rejects duplicate stops in the current order', () {
      expectInvalid(
        request(
          stops: [stop()],
          tasks: [task('TASK-A', 'STOP-A')],
          order: ['STOP-A', 'STOP-A'],
        ),
      );
    });

    test('rejects an unknown stop in the current order', () {
      expectInvalid(
        request(
          stops: [stop()],
          tasks: [task('TASK-A', 'STOP-A')],
          order: ['UNKNOWN'],
        ),
      );
    });

    test('rejects a task referencing an unknown stop', () {
      expectInvalid(
        request(stops: [stop()], tasks: [task('TASK-A', 'UNKNOWN')]),
      );
    });

    test('rejects a stop referencing an unknown task', () {
      expectInvalid(
        request(
          stops: [
            stop(taskIds: ['UNKNOWN']),
          ],
          tasks: [task('TASK-A', 'STOP-A')],
        ),
      );
    });

    test('rejects inconsistent task and stop references', () {
      expectInvalid(
        request(
          stops: [
            stop(taskIds: ['TASK-B']),
            stop(id: 'STOP-B', taskIds: ['TASK-A']),
          ],
          tasks: [task('TASK-A', 'STOP-A'), task('TASK-B', 'STOP-B')],
          order: ['STOP-A', 'STOP-B'],
        ),
      );
    });

    test('rejects a task omitted from its stop', () {
      expectInvalid(
        request(
          stops: [stop()],
          tasks: [task('TASK-A', 'STOP-A'), task('TASK-B', 'STOP-A')],
        ),
      );
    });

    test('rejects a task listed twice by its stop', () {
      expectInvalid(
        request(
          stops: [
            stop(taskIds: ['TASK-A', 'TASK-A']),
          ],
          tasks: [task('TASK-A', 'STOP-A')],
        ),
      );
    });

    test('rejects a locked stop missing from the current order', () {
      expectInvalid(
        request(
          stops: [stop(isLocked: true)],
          tasks: [task('TASK-A', 'STOP-A')],
          order: [],
        ),
      );
    });

    test('allows an unlocked stop missing from the current order', () {
      final input = request(
        stops: [stop()],
        tasks: [task('TASK-A', 'STOP-A')],
        order: [],
      );

      expect(() => validator.validate(input), returnsNormally);
    });

    test('rejects duplicate walking cluster identifiers', () {
      expectInvalid(
        request(
          stops: [stop(clusterId: 'WALK-A')],
          tasks: [task('TASK-A', 'STOP-A')],
          clusters: [cluster(), cluster()],
        ),
      );
    });

    test('rejects an unknown stop in a walking cluster', () {
      expectInvalid(
        request(
          stops: [stop()],
          tasks: [task('TASK-A', 'STOP-A')],
          clusters: [
            cluster(stopIds: ['UNKNOWN']),
          ],
        ),
      );
    });

    test('rejects a duplicated stop inside a walking cluster', () {
      expectInvalid(
        request(
          stops: [stop(clusterId: 'WALK-A')],
          tasks: [task('TASK-A', 'STOP-A')],
          clusters: [
            cluster(stopIds: ['STOP-A', 'STOP-A']),
          ],
        ),
      );
    });

    test('rejects a stop referencing an unknown walking cluster', () {
      expectInvalid(
        request(
          stops: [stop(clusterId: 'UNKNOWN')],
          tasks: [task('TASK-A', 'STOP-A')],
        ),
      );
    });

    test('rejects a cluster without a matching stop reference', () {
      expectInvalid(
        request(
          stops: [stop()],
          tasks: [task('TASK-A', 'STOP-A')],
          clusters: [cluster()],
        ),
      );
    });

    test('rejects a stop omitted from its declared cluster', () {
      expectInvalid(
        request(
          stops: [
            stop(clusterId: 'WALK-A'),
            stop(id: 'STOP-B', taskIds: ['TASK-B'], clusterId: 'WALK-A'),
          ],
          tasks: [task('TASK-A', 'STOP-A'), task('TASK-B', 'STOP-B')],
          order: ['STOP-A', 'STOP-B'],
          clusters: [cluster()],
        ),
      );
    });

    test('accepts several tasks assigned to the same stop', () {
      final input = request(
        stops: [
          stop(taskIds: ['TASK-A', 'TASK-B']),
        ],
        tasks: [task('TASK-A', 'STOP-A'), task('TASK-B', 'STOP-A')],
      );

      expect(() => validator.validate(input), returnsNormally);
    });
  });
}
