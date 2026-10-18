import 'route_optimization_models.dart';
import 'route_optimization_port.dart';

class RouteOptimizationRequestValidator {
  const RouteOptimizationRequestValidator();

  void validate(RouteOptimizationRequest request) {
    final plan = request.plan;

    if (plan.id.trim().isEmpty) {
      _reject('The route identifier must not be empty.');
    }

    if (request.timeout <= Duration.zero) {
      _reject('The optimization timeout must be positive.');
    }

    _validateCoordinate(request.currentLocation);

    final stopsById = <String, OperationalStop>{};

    for (final stop in plan.stops) {
      if (stop.id.trim().isEmpty || stopsById.containsKey(stop.id)) {
        _reject('Stop identifiers must be nonempty and unique.');
      }

      _validateCoordinate(stop.coordinate);
      stopsById[stop.id] = stop;
    }

    final tasksById = <String, RouteTask>{};

    for (final task in plan.tasks) {
      if (task.id.trim().isEmpty || tasksById.containsKey(task.id)) {
        _reject('Task identifiers must be nonempty and unique.');
      }

      if (!stopsById.containsKey(task.stopId)) {
        _reject('A task references an unknown stop.');
      }

      if (task.serviceDuration.isNegative) {
        _reject('Task service duration must not be negative.');
      }

      final window = task.timeWindow;

      if (window != null && !window.endsAt.isAfter(window.startsAt)) {
        _reject('A time window must end after it starts.');
      }

      tasksById[task.id] = task;
    }

    final assignedTaskIds = <String>{};

    for (final stop in plan.stops) {
      if (stop.taskIds.isEmpty) {
        _reject('Each stop must reference at least one task.');
      }

      for (final taskId in stop.taskIds) {
        final task = tasksById[taskId];

        if (task == null) {
          _reject('A stop references an unknown task.');
        }

        if (task.stopId != stop.id) {
          _reject('A task and its stop have inconsistent references.');
        }

        if (!assignedTaskIds.add(taskId)) {
          _reject('A task must appear in exactly one stop.');
        }
      }
    }

    if (assignedTaskIds.length != tasksById.length) {
      _reject('Every task must be listed by its assigned stop.');
    }

    final orderedStopIds = <String>{};

    for (final stopId in plan.currentOrder) {
      if (!stopsById.containsKey(stopId)) {
        _reject('The current order references an unknown stop.');
      }

      if (!orderedStopIds.add(stopId)) {
        _reject('The current order contains a duplicated stop.');
      }
    }

    for (final stop in plan.stops) {
      if (stop.isLocked && !orderedStopIds.contains(stop.id)) {
        _reject('A locked stop must appear in the current order.');
      }
    }

    final clustersById = <String, WalkingCluster>{};
    final clusteredStopIds = <String>{};

    for (final cluster in plan.walkingClusters) {
      if (cluster.id.trim().isEmpty || clustersById.containsKey(cluster.id)) {
        _reject('Walking cluster identifiers must be nonempty and unique.');
      }

      if (cluster.stopIds.isEmpty) {
        _reject('A walking cluster must contain at least one stop.');
      }

      _validateCoordinate(cluster.anchor);
      clustersById[cluster.id] = cluster;

      for (final stopId in cluster.stopIds) {
        final stop = stopsById[stopId];

        if (stop == null) {
          _reject('A walking cluster references an unknown stop.');
        }

        if (!clusteredStopIds.add(stopId)) {
          _reject('A stop must not appear in multiple cluster entries.');
        }

        if (stop.walkingClusterId != cluster.id) {
          _reject(
            'A stop and its walking cluster have inconsistent references.',
          );
        }
      }
    }

    for (final stop in plan.stops) {
      final clusterId = stop.walkingClusterId;

      if (clusterId == null) {
        continue;
      }

      if (!clustersById.containsKey(clusterId) ||
          !clusteredStopIds.contains(stop.id)) {
        _reject('A stop references an unknown or incomplete walking cluster.');
      }
    }
  }

  void _validateCoordinate(RouteCoordinate coordinate) {
    if (!coordinate.latitude.isFinite ||
        !coordinate.longitude.isFinite ||
        coordinate.latitude < -90 ||
        coordinate.latitude > 90 ||
        coordinate.longitude < -180 ||
        coordinate.longitude > 180) {
      _reject('Coordinates must be finite and within geographic bounds.');
    }
  }

  Never _reject(String message) {
    throw RouteOptimizationFailure(
      type: RouteOptimizationFailureType.invalidRequest,
      message: message,
    );
  }
}
