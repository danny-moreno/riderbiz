import 'route_optimization_models.dart';
import 'route_optimization_port.dart';
import 'route_optimization_request_validator.dart';

class VroomMappedRequest {
  VroomMappedRequest({
    required this.payload,
    required Map<int, String> stopIdsByJobId,
  }) : stopIdsByJobId = Map.unmodifiable(stopIdsByJobId);

  final Map<String, Object?> payload;
  final Map<int, String> stopIdsByJobId;
}

class VroomRequestMapper {
  const VroomRequestMapper();

  VroomMappedRequest map(RouteOptimizationRequest request) {
    const RouteOptimizationRequestValidator().validate(request);

    final pendingTasks = request.plan.pendingTasks;
    final pendingStopIds = pendingTasks.map((task) => task.stopId).toSet();

    final activeStops = request.plan.stops
        .where((stop) => pendingStopIds.contains(stop.id))
        .toList(growable: false);

    if (activeStops.any((stop) => stop.isLocked)) {
      _reject('Locked stops are not supported by this mapper yet.');
    }

    if (activeStops.any((stop) => stop.walkingClusterId != null)) {
      _reject('Walking clusters require a separate routing strategy.');
    }

    if (activeStops.length > 249) {
      _reject('The local routing limit allows 249 stops plus the start.');
    }

    final tasksByStop = <String, List<RouteTask>>{};

    for (final task in pendingTasks) {
      tasksByStop.putIfAbsent(task.stopId, () => []).add(task);
    }

    final jobs = <Map<String, Object?>>[];
    final stopIdsByJobId = <int, String>{};

    for (var index = 0; index < activeStops.length; index++) {
      final stop = activeStops[index];
      final tasks = tasksByStop[stop.id]!;
      final jobId = index + 1;

      var serviceMicroseconds = 0;
      var priority = RoutePriority.low.index;
      DateTime? windowStart;
      DateTime? windowEnd;

      for (final task in tasks) {
        serviceMicroseconds += task.serviceDuration.inMicroseconds;

        if (task.priority.index > priority) {
          priority = task.priority.index;
        }

        final window = task.timeWindow;

        if (window != null) {
          if (windowStart == null || window.startsAt.isAfter(windowStart)) {
            windowStart = window.startsAt;
          }

          if (windowEnd == null || window.endsAt.isBefore(windowEnd)) {
            windowEnd = window.endsAt;
          }
        }
      }

      final job = <String, Object?>{
        'id': jobId,
        'location': [stop.coordinate.longitude, stop.coordinate.latitude],
        'service': _ceilSeconds(serviceMicroseconds),
        'priority': const [0, 30, 60, 100][priority],
      };

      if (windowStart != null && windowEnd != null) {
        var startSeconds = _ceilSeconds(
          windowStart.difference(request.departureAt).inMicroseconds,
        );
        final endSeconds =
            windowEnd.difference(request.departureAt).inMicroseconds ~/
            Duration.microsecondsPerSecond;

        if (startSeconds < 0) {
          startSeconds = 0;
        }

        if (endSeconds < startSeconds) {
          _reject('A stop has expired or incompatible time windows.');
        }

        job['time_windows'] = [
          [startSeconds, endSeconds],
        ];
      }

      jobs.add(job);
      stopIdsByJobId[jobId] = stop.id;
    }

    return VroomMappedRequest(
      payload: {
        'vehicles': [
          {
            'id': 1,
            'profile': 'car',
            'start': [
              request.currentLocation.longitude,
              request.currentLocation.latitude,
            ],
          },
        ],
        'jobs': jobs,
      },
      stopIdsByJobId: stopIdsByJobId,
    );
  }

  int _ceilSeconds(int microseconds) {
    return (microseconds / Duration.microsecondsPerSecond).ceil();
  }

  Never _reject(String message) {
    throw RouteOptimizationFailure(
      type: RouteOptimizationFailureType.invalidRequest,
      message: message,
    );
  }
}
