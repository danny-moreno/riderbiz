import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';

import '../../support/route_optimization/vroom_vehicle_scenario_factory.dart';

void main() {
  const factory = VroomVehicleScenarioFactory();
  const mapper = VroomRequestMapper();

  group('VroomVehicleScenarioFactory', () {
    for (final count in [60, 80, 120]) {
      test('creates $count tasks compatible with the vehicle mapper', () {
        final request = factory.create(taskCount: count);
        final mapped = mapper.map(request);
        final plan = request.plan;

        expect(plan.tasks, hasLength(count));
        expect(plan.stops, hasLength(count));
        expect(plan.currentOrder.toSet(), hasLength(count));
        expect(plan.pendingTasks, hasLength(count));
        expect(plan.lockedStops, isEmpty);
        expect(plan.walkingClusters, isEmpty);
        expect(plan.tasks.where((task) => task.timeWindow != null), isEmpty);

        expect(mapped.payload['jobs'], hasLength(count));
        expect(mapped.stopIdsByJobId, hasLength(count));
        expect(mapped.stopIdsByJobId.values.toSet(), plan.currentOrder.toSet());

        expect(
          plan.tasks.where((task) => task.type == RouteTaskType.pickup),
          hasLength(count ~/ 5),
        );
        expect(
          plan.tasks.where((task) => task.type == RouteTaskType.delivery),
          hasLength(count - count ~/ 5),
        );
      });
    }

    test('creates repeatable coordinates and identifiers', () {
      final first = factory.create(taskCount: 80);
      final second = factory.create(taskCount: 80);

      expect(first.plan.currentOrder, second.plan.currentOrder);
      expect(first.departureAt, second.departureAt);

      for (var index = 0; index < first.plan.stops.length; index++) {
        final firstStop = first.plan.stops[index];
        final secondStop = second.plan.stops[index];

        expect(firstStop.id, secondStop.id);
        expect(firstStop.coordinate.latitude, secondStop.coordinate.latitude);
        expect(firstStop.coordinate.longitude, secondStop.coordinate.longitude);
      }
    });

    test('maps only 60 pending tasks after completing 20 of 80', () {
      final request = factory.create(taskCount: 80, completedTaskCount: 20);
      final mapped = mapper.map(request);

      expect(request.reoptimizePendingOnly, isTrue);
      expect(request.plan.tasks, hasLength(80));
      expect(request.plan.pendingTasks, hasLength(60));
      expect(mapped.payload['jobs'], hasLength(60));
      expect(mapped.stopIdsByJobId, hasLength(60));

      final completedStopIds = request.plan.tasks
          .where((task) => task.status == RouteTaskStatus.completed)
          .map((task) => task.stopId)
          .toSet();

      expect(
        mapped.stopIdsByJobId.values.any(completedStopIds.contains),
        isFalse,
      );
    });

    test('produces no jobs when all tasks are completed', () {
      final request = factory.create(taskCount: 60, completedTaskCount: 60);
      final mapped = mapper.map(request);

      expect(request.plan.pendingTasks, isEmpty);
      expect(mapped.payload['jobs'], isEmpty);
      expect(mapped.stopIdsByJobId, isEmpty);
    });

    test('rejects unsupported scenario sizes', () {
      expect(() => factory.create(taskCount: 100), throwsArgumentError);
    });

    test('rejects a negative completed task count', () {
      expect(
        () => factory.create(taskCount: 60, completedTaskCount: -1),
        throwsArgumentError,
      );
    });

    test('rejects completed task counts greater than total tasks', () {
      expect(
        () => factory.create(taskCount: 60, completedTaskCount: 61),
        throwsArgumentError,
      );
    });
  });
}
