import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';

import '../../support/route_optimization/daily_delivery_scenario_factory.dart';

void main() {
  const factory = DailyDeliveryScenarioFactory();
  const mapper = VroomRequestMapper();

  for (final size in [
    (100, 100),
    (125, 125),
    (150, 150),
    (150, 110),
    (150, 60),
  ]) {
    for (final completed in [0, size.$1 ~/ 2, size.$1]) {
      test('${size.$1} packages, ${size.$2} stops, $completed completed', () {
        final request = factory.create(
          packageCount: size.$1,
          stopCount: size.$2,
          completedPackageCount: completed,
        );
        final plan = request.plan;
        final tasksById = {for (final task in plan.tasks) task.id: task};

        expect(plan.tasks, hasLength(size.$1));
        expect(tasksById, hasLength(size.$1));
        expect(plan.stops, hasLength(size.$2));
        expect(plan.currentOrder.toSet(), hasLength(size.$2));
        expect(
          plan.tasks.every((task) => task.type == RouteTaskType.delivery),
          isTrue,
        );
        expect(plan.pendingTasks, hasLength(size.$1 - completed));

        final assignedIds = <String>[];
        for (final stop in plan.stops) {
          assignedIds.addAll(stop.taskIds);
          for (final id in stop.taskIds) {
            expect(tasksById[id], isNotNull);
            expect(tasksById[id]!.stopId, stop.id);
          }
        }
        expect(assignedIds, hasLength(size.$1));
        expect(assignedIds.toSet(), tasksById.keys.toSet());

        final mapped = mapper.map(request);
        final jobs = (mapped.payload['jobs'] as List)
            .cast<Map<String, Object?>>();
        final pendingStops = plan.pendingTasks
            .map((task) => task.stopId)
            .toSet();

        expect(jobs, hasLength(pendingStops.length));
        expect(mapped.stopIdsByJobId.values.toSet(), pendingStops);
        expect(mapped.stopIdsByJobId, hasLength(jobs.length));

        var totalService = 0;
        for (final job in jobs) {
          final stopId = mapped.stopIdsByJobId[job['id']]!;
          final pendingAtStop = plan.pendingTasks
              .where((task) => task.stopId == stopId)
              .length;
          expect(job['service'], pendingAtStop * 60);
          totalService += job['service'] as int;
        }
        expect(totalService, (size.$1 - completed) * 60);
      });
    }
  }

  test('rejects invalid scenario dimensions', () {
    for (final count in [0, 99, 151]) {
      expect(
        () => factory.create(packageCount: count, stopCount: 1),
        throwsArgumentError,
      );
    }
    for (final stops in [0, 101]) {
      expect(
        () => factory.create(packageCount: 100, stopCount: stops),
        throwsArgumentError,
      );
    }
    for (final completed in [-1, 101]) {
      expect(
        () => factory.create(
          packageCount: 100,
          stopCount: 80,
          completedPackageCount: completed,
        ),
        throwsArgumentError,
      );
    }
  });
}
