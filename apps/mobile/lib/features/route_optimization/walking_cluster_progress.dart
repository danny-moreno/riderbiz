import 'route_optimization_models.dart';
import 'route_optimization_request_validator.dart';

class WalkingPortalProgress {
  WalkingPortalProgress({
    required this.stopId,
    required this.coordinate,
    required List<RouteTask> pendingTasks,
  }) : pendingTasks = List.unmodifiable(pendingTasks);

  final String stopId;
  final RouteCoordinate coordinate;
  final List<RouteTask> pendingTasks;
}

/// Operational grouping only. Does not calculate a walking route or schedule.
class WalkingClusterProgress {
  WalkingClusterProgress._({
    required this.clusterId,
    required this.parkingLocation,
    required List<WalkingPortalProgress> portals,
  }) : portals = List.unmodifiable(portals);

  final String clusterId;

  /// Declared anchor, not a verified legal or accessible parking place.
  final RouteCoordinate parkingLocation;

  /// Pending portals in the declared or explicitly selected manual order.
  final List<WalkingPortalProgress> portals;

  int get pendingTaskCount =>
      portals.fold(0, (total, portal) => total + portal.pendingTasks.length);

  int get pendingDeliveryCount => portals.fold(
    0,
    (total, portal) =>
        total +
        portal.pendingTasks
            .where((task) => task.type == RouteTaskType.delivery)
            .length,
  );

  int get pendingPickupCount => pendingTaskCount - pendingDeliveryCount;

  factory WalkingClusterProgress.fromRequest(
    RouteOptimizationRequest request, {
    required String clusterId,
  }) {
    const RouteOptimizationRequestValidator().validate(request);

    final matching = request.plan.walkingClusters.where(
      (cluster) => cluster.id == clusterId,
    );
    if (matching.isEmpty) {
      throw ArgumentError.value(clusterId, 'clusterId', 'Unknown cluster.');
    }

    final cluster = matching.single;
    final stopsById = {for (final stop in request.plan.stops) stop.id: stop};
    final pendingById = {
      for (final task in request.plan.pendingTasks) task.id: task,
    };
    final portals = <WalkingPortalProgress>[];

    for (final stopId in cluster.stopIds) {
      final stop = stopsById[stopId]!;
      final pending = [
        for (final taskId in stop.taskIds)
          if (pendingById.containsKey(taskId)) pendingById[taskId]!,
      ];
      if (pending.isEmpty) continue;
      portals.add(
        WalkingPortalProgress(
          stopId: stop.id,
          coordinate: stop.coordinate,
          pendingTasks: pending,
        ),
      );
    }

    return WalkingClusterProgress._(
      clusterId: cluster.id,
      parkingLocation: cluster.anchor,
      portals: portals,
    );
  }

  WalkingClusterProgress inManualOrder(List<String> stopIds) {
    final byId = {for (final portal in portals) portal.stopId: portal};
    if (stopIds.length != portals.length ||
        stopIds.toSet().length != stopIds.length ||
        !stopIds.every(byId.containsKey)) {
      throw ArgumentError(
        'Manual order must contain each pending portal exactly once.',
      );
    }

    return WalkingClusterProgress._(
      clusterId: clusterId,
      parkingLocation: parkingLocation,
      portals: [for (final id in stopIds) byId[id]!],
    );
  }
}
