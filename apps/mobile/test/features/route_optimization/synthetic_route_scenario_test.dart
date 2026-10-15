import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/fake_route_optimization_adapter.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

import '../../support/route_optimization/synthetic_route_scenario_factory.dart';

void main() {
  const factory = SyntheticRouteScenarioFactory();
  const adapter = FakeRouteOptimizationAdapter();

  group('SyntheticRouteScenarioFactory', () {
    for (final taskCount in [60, 80, 120]) {
      test('creates a complete scenario with $taskCount tasks', () {
        final scenario = factory.create(taskCount: taskCount);
        final plan = scenario.request.plan;

        expect(plan.tasks, hasLength(taskCount));
        expect(plan.stops, hasLength(taskCount));
        expect(plan.currentOrder, hasLength(taskCount));
        expect(scenario.deliveryCount + scenario.pickupCount, taskCount);
        expect(
          plan.tasks.where((task) => task.type == RouteTaskType.pickup),
          hasLength(scenario.pickupCount),
        );
        expect(
          plan.tasks.where((task) => task.type == RouteTaskType.delivery),
          hasLength(scenario.deliveryCount),
        );
        expect(plan.tasks.where((task) => task.timeWindow != null), isNotEmpty);
        expect(plan.walkingClusters, isNotEmpty);
        expect(scenario.lockedStopCount, greaterThan(0));
      });

      test('optimizes all $taskCount synthetic tasks', () async {
        final scenario = factory.create(taskCount: taskCount);
        final result = await adapter.optimize(scenario.request);

        expect(result.stopOrder, hasLength(taskCount));
        expect(result.stopOrder.toSet(), hasLength(taskCount));
        expect(result.vehicleLegs, hasLength(taskCount));
        expect(result.metrics.distanceMeters, taskCount * 1000);
        expect(result.explanation.summary, isNotEmpty);
      });
    }

    test('creates the expected delivery and pickup distribution', () {
      final scenario60 = factory.create(taskCount: 60);
      final scenario80 = factory.create(taskCount: 80);
      final scenario120 = factory.create(taskCount: 120);

      expect(scenario60.pickupCount, 12);
      expect(scenario60.deliveryCount, 48);

      expect(scenario80.pickupCount, 16);
      expect(scenario80.deliveryCount, 64);

      expect(scenario120.pickupCount, 24);
      expect(scenario120.deliveryCount, 96);
    });

    test('creates deterministic walking clusters', () {
      final first = factory.create(taskCount: 80);
      final second = factory.create(taskCount: 80);

      expect(first.walkingClusterCount, 7);
      expect(second.walkingClusterCount, 7);
      expect(
        first.request.plan.walkingClusters.first.id,
        second.request.plan.walkingClusters.first.id,
      );
      expect(
        first.request.plan.walkingClusters.first.stopIds,
        second.request.plan.walkingClusters.first.stopIds,
      );
      expect(first.request.plan.walkingClusters.first.stopIds, [
        'STOP-SYN-001',
        'STOP-SYN-002',
        'STOP-SYN-003',
      ]);
    });

    test('reoptimizes only the pending part of an active route', () async {
      final scenario = factory.create(
        taskCount: 80,
        completedTaskCount: 20,
        reoptimizePendingOnly: true,
      );

      final result = await adapter.optimize(scenario.request);

      expect(scenario.request.plan.pendingTasks, hasLength(60));
      expect(result.stopOrder, hasLength(60));
      expect(result.stopOrder, isNot(contains('STOP-SYN-001')));
      expect(result.stopOrder, isNot(contains('STOP-SYN-020')));
      expect(result.stopOrder, contains('STOP-SYN-021'));
    });

    test('keeps every generated identifier technical and synthetic', () {
      final scenario = factory.create(taskCount: 60);

      for (final task in scenario.request.plan.tasks) {
        expect(task.id, startsWith('TASK-SYN-'));
        expect(task.stopId, startsWith('STOP-SYN-'));
      }

      for (final stop in scenario.request.plan.stops) {
        expect(stop.id, startsWith('STOP-SYN-'));
      }

      for (final cluster in scenario.request.plan.walkingClusters) {
        expect(cluster.id, startsWith('WALK-SYN-'));
      }
    });

    test('rejects an invalid task count', () {
      expect(() => factory.create(taskCount: 0), throwsArgumentError);
    });

    test('rejects an invalid completed task count', () {
      expect(
        () => factory.create(taskCount: 60, completedTaskCount: 61),
        throwsArgumentError,
      );
    });
  });
}
