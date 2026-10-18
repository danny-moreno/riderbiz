import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';

void main() {
  const mapper = VroomRequestMapper();
  final departure = DateTime.utc(2026, 10, 15, 8);

  RouteTask task({
    String id = 'TASK-A',
    String stopId = 'STOP-A',
    RouteTaskType type = RouteTaskType.delivery,
    RouteTaskStatus status = RouteTaskStatus.pending,
    RoutePriority priority = RoutePriority.normal,
    Duration service = const Duration(minutes: 2),
    RouteTimeWindow? window,
  }) {
    return RouteTask(
      id: id,
      stopId: stopId,
      type: type,
      status: status,
      priority: priority,
      serviceDuration: service,
      timeWindow: window,
    );
  }

  RouteOptimizationRequest request({
    required List<RouteTask> tasks,
    bool locked = false,
    bool walking = false,
  }) {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-MAPPER',
        currentOrder: ['STOP-A'],
        stops: [
          OperationalStop(
            id: 'STOP-A',
            coordinate: const RouteCoordinate(
              latitude: 42.81,
              longitude: -1.64,
            ),
            taskIds: tasks.map((task) => task.id).toList(),
            isLocked: locked,
            walkingClusterId: walking ? 'WALK-A' : null,
          ),
        ],
        tasks: tasks,
        walkingClusters: walking
            ? [
                WalkingCluster(
                  id: 'WALK-A',
                  stopIds: ['STOP-A'],
                  anchor: const RouteCoordinate(
                    latitude: 42.81,
                    longitude: -1.64,
                  ),
                ),
              ]
            : [],
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: departure,
      timeout: const Duration(seconds: 10),
    );
  }

  List<Map<String, Object?>> jobs(VroomMappedRequest mapped) {
    return (mapped.payload['jobs'] as List).cast<Map<String, Object?>>();
  }

  Matcher invalidRequest() {
    return throwsA(
      isA<RouteOptimizationFailure>().having(
        (failure) => failure.type,
        'type',
        RouteOptimizationFailureType.invalidRequest,
      ),
    );
  }

  group('VroomRequestMapper', () {
    test('maps coordinates as longitude then latitude', () {
      final mapped = mapper.map(request(tasks: [task()]));
      final vehicles = mapped.payload['vehicles'] as List;
      final vehicle = vehicles.single as Map<String, Object?>;

      expect(vehicle['start'], [-1.6458, 42.8125]);
      expect(vehicle['profile'], 'car');
      expect(jobs(mapped).single['location'], [-1.64, 42.81]);
      expect(mapped.stopIdsByJobId, {1: 'STOP-A'});
    });

    test('combines tasks at one stop and uses the highest priority', () {
      final mapped = mapper.map(
        request(
          tasks: [
            task(),
            task(
              id: 'TASK-B',
              type: RouteTaskType.pickup,
              priority: RoutePriority.urgent,
              service: const Duration(minutes: 4),
            ),
          ],
        ),
      );

      expect(jobs(mapped), hasLength(1));
      expect(jobs(mapped).single['service'], 360);
      expect(jobs(mapped).single['priority'], 100);
    });

    test('excludes completed tasks from service and priority', () {
      final mapped = mapper.map(
        request(
          tasks: [
            task(),
            task(
              id: 'TASK-B',
              status: RouteTaskStatus.completed,
              priority: RoutePriority.urgent,
              service: const Duration(minutes: 10),
            ),
          ],
        ),
      );

      expect(jobs(mapped).single['service'], 120);
      expect(jobs(mapped).single['priority'], 30);
    });

    test('returns no jobs when every task is completed', () {
      final mapped = mapper.map(
        request(tasks: [task(status: RouteTaskStatus.completed)]),
      );

      expect(jobs(mapped), isEmpty);
      expect(mapped.stopIdsByJobId, isEmpty);
    });

    test('maps time windows relative to departure', () {
      final mapped = mapper.map(
        request(
          tasks: [
            task(
              window: RouteTimeWindow(
                startsAt: departure.add(const Duration(hours: 1)),
                endsAt: departure.add(const Duration(hours: 2)),
              ),
            ),
          ],
        ),
      );

      expect(jobs(mapped).single['time_windows'], [
        [3600, 7200],
      ]);
    });

    test('intersects time windows for tasks at the same stop', () {
      final mapped = mapper.map(
        request(
          tasks: [
            task(
              window: RouteTimeWindow(
                startsAt: departure.add(const Duration(hours: 1)),
                endsAt: departure.add(const Duration(hours: 3)),
              ),
            ),
            task(
              id: 'TASK-B',
              window: RouteTimeWindow(
                startsAt: departure.add(const Duration(hours: 2)),
                endsAt: departure.add(const Duration(hours: 4)),
              ),
            ),
          ],
        ),
      );

      expect(jobs(mapped).single['time_windows'], [
        [7200, 10800],
      ]);
    });

    test('clamps a window that already started to departure', () {
      final mapped = mapper.map(
        request(
          tasks: [
            task(
              window: RouteTimeWindow(
                startsAt: departure.subtract(const Duration(hours: 1)),
                endsAt: departure.add(const Duration(hours: 1)),
              ),
            ),
          ],
        ),
      );

      expect(jobs(mapped).single['time_windows'], [
        [0, 3600],
      ]);
    });

    test('rejects an expired time window', () {
      expect(
        () => mapper.map(
          request(
            tasks: [
              task(
                window: RouteTimeWindow(
                  startsAt: departure.subtract(const Duration(hours: 2)),
                  endsAt: departure.subtract(const Duration(hours: 1)),
                ),
              ),
            ],
          ),
        ),
        invalidRequest(),
      );
    });

    test('rejects incompatible time windows at the same stop', () {
      expect(
        () => mapper.map(
          request(
            tasks: [
              task(
                window: RouteTimeWindow(
                  startsAt: departure.add(const Duration(hours: 1)),
                  endsAt: departure.add(const Duration(hours: 2)),
                ),
              ),
              task(
                id: 'TASK-B',
                window: RouteTimeWindow(
                  startsAt: departure.add(const Duration(hours: 3)),
                  endsAt: departure.add(const Duration(hours: 4)),
                ),
              ),
            ],
          ),
        ),
        invalidRequest(),
      );
    });

    test('rounds fractional service seconds upwards', () {
      final mapped = mapper.map(
        request(tasks: [task(service: const Duration(milliseconds: 1500))]),
      );

      expect(jobs(mapped).single['service'], 2);
    });

    test('rejects active locked stops explicitly', () {
      expect(
        () => mapper.map(request(tasks: [task()], locked: true)),
        invalidRequest(),
      );
    });

    test('rejects active walking clusters explicitly', () {
      expect(
        () => mapper.map(request(tasks: [task()], walking: true)),
        invalidRequest(),
      );
    });
  });
}
