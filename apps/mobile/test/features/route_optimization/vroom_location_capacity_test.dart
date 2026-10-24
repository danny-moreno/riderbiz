import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';

RouteOptimizationRequest capacityRequest({
  required int packageCount,
  required int stopCount,
  int completedStops = 0,
}) {
  final idsByStop = List.generate(stopCount, (_) => <String>[]);
  final tasks = <RouteTask>[];

  for (var index = 0; index < packageCount; index++) {
    final stopIndex = index % stopCount;
    final id = 'PACKAGE-$index';
    idsByStop[stopIndex].add(id);
    tasks.add(
      RouteTask(
        id: id,
        stopId: 'STOP-$stopIndex',
        type: RouteTaskType.delivery,
        status: stopIndex < completedStops
            ? RouteTaskStatus.completed
            : RouteTaskStatus.pending,
        priority: RoutePriority.normal,
        serviceDuration: const Duration(seconds: 60),
      ),
    );
  }

  return RouteOptimizationRequest(
    plan: RoutePlan(
      id: 'CAPACITY-$packageCount-$stopCount',
      currentOrder: [
        for (var index = 0; index < stopCount; index++) 'STOP-$index',
      ],
      stops: [
        for (var index = 0; index < stopCount; index++)
          OperationalStop(
            id: 'STOP-$index',
            coordinate: RouteCoordinate(
              latitude: 42.81 + index * 0.00001,
              longitude: -1.64,
            ),
            taskIds: idsByStop[index],
          ),
      ],
      tasks: tasks,
    ),
    currentLocation: const RouteCoordinate(latitude: 42.80, longitude: -1.65),
    departureAt: DateTime.utc(2026, 10, 24, 8),
    timeout: const Duration(seconds: 40),
    reoptimizePendingOnly: completedStops > 0,
  );
}

void main() {
  const mapper = VroomRequestMapper();
  const destination = RouteCoordinate(latitude: 42.82, longitude: -1.63);

  for (final stopCount in [248, 249, 250]) {
    for (final withEnd in [false, true]) {
      test('500 packages at $stopCount stops, explicit end $withEnd', () {
        final request = capacityRequest(
          packageCount: 500,
          stopCount: stopCount,
        );
        final originalOrder = List<String>.of(request.plan.currentOrder);
        final exceedsLimit = stopCount + 1 + (withEnd ? 1 : 0) > 250;

        if (exceedsLimit) {
          expect(
            () =>
                mapper.map(request, endLocation: withEnd ? destination : null),
            throwsA(
              isA<RouteOptimizationFailure>().having(
                (error) => error.type,
                'type',
                RouteOptimizationFailureType.invalidRequest,
              ),
            ),
          );
        } else {
          final mapped = mapper.map(
            request,
            endLocation: withEnd ? destination : null,
          );
          final jobs = (mapped.payload['jobs'] as List)
              .cast<Map<String, Object?>>();

          expect(jobs, hasLength(stopCount));
          expect(mapped.stopIdsByJobId.values.toSet(), {
            for (var index = 0; index < stopCount; index++) 'STOP-$index',
          });
          expect(
            jobs.fold<int>(0, (sum, job) => sum + (job['service'] as int)),
            500 * 60,
          );
          for (final job in jobs) {
            final id = mapped.stopIdsByJobId[job['id']]!;
            final packagesAtStop = request.plan.pendingTasks
                .where((task) => task.stopId == id)
                .length;
            expect(job['service'], packagesAtStop * 60);
          }
        }

        expect(request.plan.tasks, hasLength(500));
        expect(request.plan.pendingTasks, hasLength(500));
        expect(request.plan.currentOrder, originalOrder);
      });
    }
  }

  for (final withEnd in [false, true]) {
    test('completed stops free capacity, explicit end $withEnd', () {
      final completed = withEnd ? 2 : 1;
      final request = capacityRequest(
        packageCount: 500,
        stopCount: 250,
        completedStops: completed,
      );
      final mapped = mapper.map(
        request,
        endLocation: withEnd ? destination : null,
      );
      final jobs = (mapped.payload['jobs'] as List)
          .cast<Map<String, Object?>>();

      expect(jobs, hasLength(250 - completed));
      expect(mapped.stopIdsByJobId.values.toSet(), {
        for (var index = completed; index < 250; index++) 'STOP-$index',
      });
      expect(
        jobs.fold<int>(0, (sum, job) => sum + (job['service'] as int)),
        (500 - completed * 2) * 60,
      );
      expect(request.plan.tasks, hasLength(500));
      expect(
        request.plan.tasks.where(
          (task) => task.status == RouteTaskStatus.completed,
        ),
        hasLength(completed * 2),
      );
    });
  }
}
