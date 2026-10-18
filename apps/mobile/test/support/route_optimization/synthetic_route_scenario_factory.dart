import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

class SyntheticRouteScenario {
  const SyntheticRouteScenario({
    required this.request,
    required this.deliveryCount,
    required this.pickupCount,
    required this.lockedStopCount,
    required this.walkingClusterCount,
  });

  final RouteOptimizationRequest request;
  final int deliveryCount;
  final int pickupCount;
  final int lockedStopCount;
  final int walkingClusterCount;
}

class SyntheticRouteScenarioFactory {
  const SyntheticRouteScenarioFactory();

  SyntheticRouteScenario create({
    required int taskCount,
    int completedTaskCount = 0,
    bool reoptimizePendingOnly = false,
  }) {
    if (taskCount <= 0) {
      throw ArgumentError.value(
        taskCount,
        'taskCount',
        'Task count must be greater than zero.',
      );
    }

    if (completedTaskCount < 0 || completedTaskCount > taskCount) {
      throw ArgumentError.value(
        completedTaskCount,
        'completedTaskCount',
        'Completed task count must be between zero and task count.',
      );
    }

    final tasks = <RouteTask>[];
    final stops = <OperationalStop>[];
    final walkingClusterStopIds = <String, List<String>>{};
    var deliveryCount = 0;
    var pickupCount = 0;
    var lockedStopCount = 0;

    for (var index = 0; index < taskCount; index++) {
      final suffix = (index + 1).toString().padLeft(3, '0');
      final taskId = 'TASK-SYN-$suffix';
      final stopId = 'STOP-SYN-$suffix';
      final isPickup = index % 5 == 0;
      final isCompleted = index < completedTaskCount;
      final isLocked = !isCompleted && index % 15 == 0;
      final walkingClusterId = _walkingClusterId(index);

      if (isPickup) {
        pickupCount++;
      } else {
        deliveryCount++;
      }

      if (isLocked) {
        lockedStopCount++;
      }

      if (walkingClusterId != null) {
        walkingClusterStopIds
            .putIfAbsent(walkingClusterId, () => [])
            .add(stopId);
      }

      tasks.add(
        RouteTask(
          id: taskId,
          stopId: stopId,
          type: isPickup ? RouteTaskType.pickup : RouteTaskType.delivery,
          status: isCompleted
              ? RouteTaskStatus.completed
              : RouteTaskStatus.pending,
          priority: _priorityFor(index),
          serviceDuration: Duration(minutes: isPickup ? 4 : 2),
          timeWindow: _timeWindowFor(index),
        ),
      );

      stops.add(
        OperationalStop(
          id: stopId,
          coordinate: _coordinateFor(index),
          taskIds: [taskId],
          isLocked: isLocked,
          walkingClusterId: walkingClusterId,
        ),
      );
    }

    final walkingClusters = walkingClusterStopIds.entries
        .map(
          (entry) => WalkingCluster(
            id: entry.key,
            stopIds: List.unmodifiable(entry.value),
            anchor: _clusterAnchor(entry.key),
          ),
        )
        .toList(growable: false);

    final currentOrder = stops.map((stop) => stop.id).toList(growable: false);

    return SyntheticRouteScenario(
      request: RouteOptimizationRequest(
        plan: RoutePlan(
          id: 'ROUTE-SYN-$taskCount',
          currentOrder: currentOrder,
          stops: List.unmodifiable(stops),
          tasks: List.unmodifiable(tasks),
          walkingClusters: List.unmodifiable(walkingClusters),
        ),
        currentLocation: const RouteCoordinate(
          latitude: 42.8100,
          longitude: -1.6400,
        ),
        departureAt: DateTime.utc(2026, 10, 15, 8),
        timeout: const Duration(seconds: 10),
        reoptimizePendingOnly: reoptimizePendingOnly,
      ),
      deliveryCount: deliveryCount,
      pickupCount: pickupCount,
      lockedStopCount: lockedStopCount,
      walkingClusterCount: walkingClusters.length,
    );
  }

  RoutePriority _priorityFor(int index) {
    if (index % 17 == 0) {
      return RoutePriority.urgent;
    }

    if (index % 7 == 0) {
      return RoutePriority.high;
    }

    if (index % 3 == 0) {
      return RoutePriority.low;
    }

    return RoutePriority.normal;
  }

  RouteTimeWindow? _timeWindowFor(int index) {
    if (index % 10 != 0) {
      return null;
    }

    final startsAt = DateTime.utc(2026, 10, 15, 8 + ((index ~/ 10) % 8));

    return RouteTimeWindow(
      startsAt: startsAt,
      endsAt: startsAt.add(const Duration(hours: 1)),
    );
  }

  String? _walkingClusterId(int index) {
    final positionInsideBlock = index % 12;

    if (positionInsideBlock >= 3) {
      return null;
    }

    final clusterNumber = (index ~/ 12) + 1;
    return 'WALK-SYN-${clusterNumber.toString().padLeft(2, '0')}';
  }

  RouteCoordinate _coordinateFor(int index) {
    final row = index ~/ 10;
    final column = index % 10;

    return RouteCoordinate(
      latitude: 42.8100 + (row * 0.001),
      longitude: -1.6400 + (column * 0.001),
    );
  }

  RouteCoordinate _clusterAnchor(String clusterId) {
    final clusterNumber = int.parse(clusterId.split('-').last);
    final firstIndex = (clusterNumber - 1) * 12;

    return _coordinateFor(firstIndex);
  }
}
