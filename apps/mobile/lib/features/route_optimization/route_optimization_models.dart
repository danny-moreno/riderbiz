enum RouteTaskType { delivery, pickup }

enum RouteTaskStatus { pending, completed, cancelled }

enum RoutePriority { low, normal, high, urgent }

class RouteCoordinate {
  const RouteCoordinate({required this.latitude, required this.longitude})
    : assert(latitude >= -90 && latitude <= 90),
      assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;
}

class RouteTimeWindow {
  RouteTimeWindow({required this.startsAt, required this.endsAt})
    : assert(endsAt.isAfter(startsAt));

  final DateTime startsAt;
  final DateTime endsAt;
}

class RouteTask {
  RouteTask({
    required this.id,
    required this.stopId,
    required this.type,
    required this.status,
    required this.priority,
    required this.serviceDuration,
    this.timeWindow,
  }) : assert(id != ''),
       assert(stopId != ''),
       assert(!serviceDuration.isNegative);

  final String id;
  final String stopId;
  final RouteTaskType type;
  final RouteTaskStatus status;
  final RoutePriority priority;
  final Duration serviceDuration;
  final RouteTimeWindow? timeWindow;

  bool get isPending => status == RouteTaskStatus.pending;
}

class OperationalStop {
  const OperationalStop({
    required this.id,
    required this.coordinate,
    required this.taskIds,
    this.isLocked = false,
    this.walkingClusterId,
  }) : assert(id != ''),
       assert(taskIds.length > 0);

  final String id;
  final RouteCoordinate coordinate;
  final List<String> taskIds;
  final bool isLocked;
  final String? walkingClusterId;
}

class WalkingCluster {
  const WalkingCluster({
    required this.id,
    required this.stopIds,
    required this.anchor,
  }) : assert(id != ''),
       assert(stopIds.length > 0);

  final String id;
  final List<String> stopIds;
  final RouteCoordinate anchor;
}

class VehicleLeg {
  VehicleLeg({
    required this.fromStopId,
    required this.toStopId,
    required this.distanceMeters,
    required this.duration,
  }) : assert(fromStopId != ''),
       assert(toStopId != ''),
       assert(distanceMeters >= 0),
       assert(!duration.isNegative);

  final String fromStopId;
  final String toStopId;
  final int distanceMeters;
  final Duration duration;
}

class RoutePlan {
  const RoutePlan({
    required this.id,
    required this.currentOrder,
    required this.stops,
    required this.tasks,
    this.walkingClusters = const [],
  }) : assert(id != '');

  final String id;
  final List<String> currentOrder;
  final List<OperationalStop> stops;
  final List<RouteTask> tasks;
  final List<WalkingCluster> walkingClusters;

  List<RouteTask> get pendingTasks =>
      tasks.where((task) => task.isPending).toList(growable: false);

  List<OperationalStop> get lockedStops =>
      stops.where((stop) => stop.isLocked).toList(growable: false);
}

class RouteMetrics {
  RouteMetrics({
    required this.distanceMeters,
    required this.travelDuration,
    required this.serviceDuration,
    required this.calculationDuration,
    this.waitingDuration = Duration.zero,
    this.departureDelay = Duration.zero,
  }) : assert(distanceMeters >= 0),
       assert(!travelDuration.isNegative),
       assert(!serviceDuration.isNegative),
       assert(!calculationDuration.isNegative),
       assert(!waitingDuration.isNegative),
       assert(!departureDelay.isNegative);

  final int distanceMeters;
  final Duration travelDuration;
  final Duration serviceDuration;
  final Duration calculationDuration;
  final Duration waitingDuration;
  final Duration departureDelay;

  Duration get totalDuration =>
      departureDelay + travelDuration + serviceDuration + waitingDuration;
}

class OptimizationExplanation {
  const OptimizationExplanation({
    required this.summary,
    this.warnings = const [],
  }) : assert(summary != '');

  final String summary;
  final List<String> warnings;
}

class RouteCandidate {
  const RouteCandidate({
    required this.stopOrder,
    required this.vehicleLegs,
    required this.metrics,
    required this.explanation,
  });

  final List<String> stopOrder;
  final List<VehicleLeg> vehicleLegs;
  final RouteMetrics metrics;
  final OptimizationExplanation explanation;
}

class RouteOptimizationRequest {
  RouteOptimizationRequest({
    required this.plan,
    required this.currentLocation,
    required this.departureAt,
    required this.timeout,
    this.reoptimizePendingOnly = false,
  }) : assert(!timeout.isNegative),
       assert(timeout > Duration.zero);

  final RoutePlan plan;
  final RouteCoordinate currentLocation;
  final DateTime departureAt;
  final Duration timeout;
  final bool reoptimizePendingOnly;
}
