import 'dart:async';

import 'route_optimization_models.dart';
import 'route_optimization_port.dart';

class FakeRouteOptimizationAdapter implements RouteOptimizationPort {
  const FakeRouteOptimizationAdapter({
    this.simulatedLatency = Duration.zero,
    this.simulatedFailure,
    this.distancePerLegMeters = 1000,
    this.durationPerLeg = const Duration(minutes: 5),
  }) : assert(distancePerLegMeters >= 0);

  final Duration simulatedLatency;
  final RouteOptimizationFailureType? simulatedFailure;
  final int distancePerLegMeters;
  final Duration durationPerLeg;

  @override
  String get providerId => 'fake-deterministic';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.throwIfCancelled();
    _validateRequest(request);

    if (simulatedFailure != null) {
      throw RouteOptimizationFailure(
        type: simulatedFailure!,
        message: 'Simulated route optimization failure.',
      );
    }

    try {
      await Future<void>.delayed(simulatedLatency).timeout(request.timeout);
    } on TimeoutException catch (error) {
      throw RouteOptimizationFailure(
        type: RouteOptimizationFailureType.timeout,
        message: 'Route optimization exceeded its timeout.',
        cause: error,
      );
    }

    cancellationSignal?.throwIfCancelled();

    final candidateOrder = _buildCandidateOrder(request);
    final vehicleLegs = _buildVehicleLegs(candidateOrder);
    final eligibleTasks = _eligibleTasks(request);
    final serviceDuration = eligibleTasks.fold(
      Duration.zero,
      (total, task) => total + task.serviceDuration,
    );

    return RouteCandidate(
      stopOrder: candidateOrder,
      vehicleLegs: vehicleLegs,
      metrics: RouteMetrics(
        distanceMeters: vehicleLegs.length * distancePerLegMeters,
        travelDuration: Duration(
          microseconds: vehicleLegs.length * durationPerLeg.inMicroseconds,
        ),
        serviceDuration: serviceDuration,
        calculationDuration: simulatedLatency,
      ),
      explanation: OptimizationExplanation(
        summary: request.reoptimizePendingOnly
            ? 'Pending tasks reordered while locked stops were preserved.'
            : 'Active tasks ordered by priority and time window.',
        warnings: const ['Synthetic deterministic distances were used.'],
      ),
    );
  }

  void _validateRequest(RouteOptimizationRequest request) {
    final stopIds = <String>{};

    for (final stop in request.plan.stops) {
      if (!stopIds.add(stop.id)) {
        throw const RouteOptimizationFailure(
          type: RouteOptimizationFailureType.invalidRequest,
          message: 'The route contains duplicated stop identifiers.',
        );
      }
    }

    final taskIds = <String>{};

    for (final task in request.plan.tasks) {
      if (!taskIds.add(task.id)) {
        throw const RouteOptimizationFailure(
          type: RouteOptimizationFailureType.invalidRequest,
          message: 'The route contains duplicated task identifiers.',
        );
      }

      if (!stopIds.contains(task.stopId)) {
        throw const RouteOptimizationFailure(
          type: RouteOptimizationFailureType.invalidRequest,
          message: 'A route task references an unknown stop.',
        );
      }
    }

    for (final stopId in request.plan.currentOrder) {
      if (!stopIds.contains(stopId)) {
        throw const RouteOptimizationFailure(
          type: RouteOptimizationFailureType.invalidRequest,
          message: 'The current route order references an unknown stop.',
        );
      }
    }
  }

  List<RouteTask> _eligibleTasks(RouteOptimizationRequest request) {
    return request.plan.tasks
        .where((task) => task.status == RouteTaskStatus.pending)
        .toList(growable: false);
  }

  List<String> _buildCandidateOrder(RouteOptimizationRequest request) {
    final eligibleTasks = _eligibleTasks(request);
    final eligibleStopIds = eligibleTasks.map((task) => task.stopId).toSet();

    if (eligibleStopIds.isEmpty) {
      return const [];
    }

    final stopById = {for (final stop in request.plan.stops) stop.id: stop};

    final tasksByStop = <String, List<RouteTask>>{};

    for (final task in eligibleTasks) {
      tasksByStop.putIfAbsent(task.stopId, () => []).add(task);
    }

    final baseOrder = <String>[
      ...request.plan.currentOrder.where(eligibleStopIds.contains),
      ...eligibleStopIds.where(
        (stopId) => !request.plan.currentOrder.contains(stopId),
      ),
    ];

    final unlockedStopIds = baseOrder
        .where((stopId) => !(stopById[stopId]?.isLocked ?? false))
        .toList();

    unlockedStopIds.sort(
      (first, second) =>
          _compareStops(first, second, tasksByStop, request.plan.currentOrder),
    );

    final unlockedIterator = unlockedStopIds.iterator;
    final candidateOrder = <String>[];

    for (final stopId in baseOrder) {
      final stop = stopById[stopId]!;

      if (stop.isLocked) {
        candidateOrder.add(stopId);
      } else {
        unlockedIterator.moveNext();
        candidateOrder.add(unlockedIterator.current);
      }
    }

    return candidateOrder;
  }

  int _compareStops(
    String firstStopId,
    String secondStopId,
    Map<String, List<RouteTask>> tasksByStop,
    List<String> currentOrder,
  ) {
    final firstTasks = tasksByStop[firstStopId] ?? const [];
    final secondTasks = tasksByStop[secondStopId] ?? const [];

    final priorityComparison = _highestPriority(secondTasks)
        .compareTo(_highestPriority(firstTasks));

    if (priorityComparison != 0) {
      return priorityComparison;
    }

    final firstWindow = _earliestWindow(firstTasks);
    final secondWindow = _earliestWindow(secondTasks);

    if (firstWindow != null && secondWindow != null) {
      final windowComparison = firstWindow.compareTo(secondWindow);

      if (windowComparison != 0) {
        return windowComparison;
      }
    } else if (firstWindow != null) {
      return -1;
    } else if (secondWindow != null) {
      return 1;
    }

    final firstPosition = currentOrder.indexOf(firstStopId);
    final secondPosition = currentOrder.indexOf(secondStopId);

    if (firstPosition >= 0 && secondPosition >= 0) {
      final positionComparison = firstPosition.compareTo(secondPosition);

      if (positionComparison != 0) {
        return positionComparison;
      }
    }

    return firstStopId.compareTo(secondStopId);
  }

  int _highestPriority(List<RouteTask> tasks) {
    var highest = RoutePriority.low.index;

    for (final task in tasks) {
      if (task.priority.index > highest) {
        highest = task.priority.index;
      }
    }

    return highest;
  }

  DateTime? _earliestWindow(List<RouteTask> tasks) {
    DateTime? earliest;

    for (final task in tasks) {
      final startsAt = task.timeWindow?.startsAt;

      if (startsAt != null &&
          (earliest == null || startsAt.isBefore(earliest))) {
        earliest = startsAt;
      }
    }

    return earliest;
  }

  List<VehicleLeg> _buildVehicleLegs(List<String> stopOrder) {
    if (stopOrder.isEmpty) {
      return const [];
    }

    final legs = <VehicleLeg>[];
    var previousStopId = 'CURRENT_LOCATION';

    for (final stopId in stopOrder) {
      legs.add(
        VehicleLeg(
          fromStopId: previousStopId,
          toStopId: stopId,
          distanceMeters: distancePerLegMeters,
          duration: durationPerLeg,
        ),
      );
      previousStopId = stopId;
    }

    return legs;
  }
}
