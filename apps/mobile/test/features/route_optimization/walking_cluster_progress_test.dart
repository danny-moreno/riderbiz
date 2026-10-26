import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/walking_cluster_progress.dart';

import '../../support/route_optimization/synthetic_route_scenario_factory.dart';

void main() {
  RouteOptimizationRequest request({bool clusterCompleted = false}) {
    RouteTask task(
      String id,
      String stopId, {
      RouteTaskType type = RouteTaskType.delivery,
      RouteTaskStatus status = RouteTaskStatus.pending,
    }) {
      return RouteTask(
        id: id,
        stopId: stopId,
        type: type,
        status: clusterCompleted && stopId != 'ROAD'
            ? RouteTaskStatus.completed
            : status,
        priority: RoutePriority.normal,
        serviceDuration: const Duration(minutes: 1),
      );
    }

    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-WALK-SYN',
        currentOrder: ['PORTAL-A', 'PORTAL-B', 'PORTAL-C', 'ROAD'],
        stops: [
          OperationalStop(
            id: 'PORTAL-A',
            coordinate: const RouteCoordinate(
              latitude: 42.8101,
              longitude: -1.6401,
            ),
            taskIds: ['A1', 'A2', 'A3'],
            walkingClusterId: 'WALK-A',
          ),
          OperationalStop(
            id: 'PORTAL-B',
            coordinate: const RouteCoordinate(
              latitude: 42.8102,
              longitude: -1.6402,
            ),
            taskIds: ['B1', 'B2'],
            walkingClusterId: 'WALK-A',
          ),
          OperationalStop(
            id: 'PORTAL-C',
            coordinate: const RouteCoordinate(
              latitude: 42.8103,
              longitude: -1.6403,
            ),
            taskIds: ['C1', 'C2'],
            walkingClusterId: 'WALK-A',
          ),
          OperationalStop(
            id: 'ROAD',
            coordinate: const RouteCoordinate(
              latitude: 42.8110,
              longitude: -1.6410,
            ),
            taskIds: ['R1'],
          ),
        ],
        tasks: [
          task('A1', 'PORTAL-A'),
          task('A2', 'PORTAL-A'),
          task('A3', 'PORTAL-A', status: RouteTaskStatus.completed),
          task('B1', 'PORTAL-B', status: RouteTaskStatus.completed),
          task('B2', 'PORTAL-B', status: RouteTaskStatus.completed),
          task('C1', 'PORTAL-C', type: RouteTaskType.pickup),
          task('C2', 'PORTAL-C', status: RouteTaskStatus.cancelled),
          task('R1', 'ROAD'),
        ],
        walkingClusters: [
          WalkingCluster(
            id: 'WALK-A',
            stopIds: ['PORTAL-A', 'PORTAL-B', 'PORTAL-C'],
            anchor: const RouteCoordinate(
              latitude: 42.8100,
              longitude: -1.6400,
            ),
          ),
        ],
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.utc(2026, 10, 26, 8),
      timeout: const Duration(seconds: 40),
    );
  }

  test('separates parking anchor, pending portals and package tasks', () {
    final input = request();
    final progress = WalkingClusterProgress.fromRequest(
      input,
      clusterId: 'WALK-A',
    );

    expect(progress.parkingLocation.latitude, 42.8100);
    expect(progress.parkingLocation.longitude, -1.6400);
    expect(progress.portals.map((portal) => portal.stopId), [
      'PORTAL-A',
      'PORTAL-C',
    ]);
    expect(progress.portals.first.coordinate.latitude, 42.8101);
    expect(progress.portals.first.pendingTasks.map((task) => task.id), [
      'A1',
      'A2',
    ]);
    expect(progress.pendingTaskCount, 3);
    expect(progress.pendingDeliveryCount, 2);
    expect(progress.pendingPickupCount, 1);
    expect(
      progress.portals
          .expand((portal) => portal.pendingTasks)
          .map((task) => task.id)
          .toSet(),
      {'A1', 'A2', 'C1'},
    );

    // Projection preserves the original completed and cancelled tasks.
    expect(input.plan.tasks, hasLength(8));
    expect(input.plan.tasks[2].status, RouteTaskStatus.completed);
    expect(input.plan.tasks[6].status, RouteTaskStatus.cancelled);
    expect(input.plan.currentOrder.first, 'PORTAL-A');
  });

  test(
    'allows manual portal order without changing the plan or membership',
    () {
      final input = request();
      final progress = WalkingClusterProgress.fromRequest(
        input,
        clusterId: 'WALK-A',
      );
      final reordered = progress.inManualOrder(['PORTAL-C', 'PORTAL-A']);

      expect(reordered.portals.map((portal) => portal.stopId), [
        'PORTAL-C',
        'PORTAL-A',
      ]);
      expect(progress.portals.map((portal) => portal.stopId), [
        'PORTAL-A',
        'PORTAL-C',
      ]);
      expect(reordered.pendingTaskCount, progress.pendingTaskCount);
      expect(reordered.parkingLocation, same(progress.parkingLocation));
      expect(input.plan.currentOrder.first, 'PORTAL-A');

      for (final invalid in <List<String>>[
        ['PORTAL-A'],
        ['PORTAL-A', 'PORTAL-A'],
        ['PORTAL-A', 'ROAD'],
        ['PORTAL-A', 'PORTAL-B', 'PORTAL-C'],
      ]) {
        expect(() => progress.inManualOrder(invalid), throwsArgumentError);
      }

      expect(() => progress.portals.clear(), throwsUnsupportedError);
      expect(
        () => progress.portals.first.pendingTasks.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test('completed cluster has no pending portals while road work remains', () {
    final input = request(clusterCompleted: true);
    final progress = WalkingClusterProgress.fromRequest(
      input,
      clusterId: 'WALK-A',
    );

    expect(progress.portals, isEmpty);
    expect(progress.pendingTaskCount, 0);
    expect(progress.pendingDeliveryCount, 0);
    expect(progress.pendingPickupCount, 0);
    expect(progress.inManualOrder([]).portals, isEmpty);
    expect(input.plan.pendingTasks.single.id, 'R1');
  });

  for (final count in [60, 80, 120]) {
    test(
      'accounts for clustered pending tasks within $count task scenario',
      () {
        final input = const SyntheticRouteScenarioFactory()
            .create(
              taskCount: count,
              completedTaskCount: count ~/ 2,
              reoptimizePendingOnly: true,
            )
            .request;
        final collected = <String>[];

        for (final cluster in input.plan.walkingClusters) {
          final progress = WalkingClusterProgress.fromRequest(
            input,
            clusterId: cluster.id,
          );
          final expected = input.plan.pendingTasks
              .where((task) => cluster.stopIds.contains(task.stopId))
              .map((task) => task.id)
              .toSet();
          final actual = progress.portals
              .expand((portal) => portal.pendingTasks)
              .map((task) => task.id)
              .toList();

          expect(actual.toSet(), expected);
          expect(actual.length, expected.length);
          expect(progress.parkingLocation, same(cluster.anchor));
          collected.addAll(actual);
        }

        final clusteredStopIds = input.plan.walkingClusters
            .expand((cluster) => cluster.stopIds)
            .toSet();
        final expectedAll = input.plan.pendingTasks
            .where((task) => clusteredStopIds.contains(task.stopId))
            .map((task) => task.id)
            .toSet();

        expect(collected.toSet(), expectedAll);
        expect(collected.length, expectedAll.length);
        expect(input.plan.tasks, hasLength(count));
      },
    );
  }
}
