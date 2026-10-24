import 'locked_route_segmenter.dart';
import 'osrm_direct_leg_client.dart';
import 'route_optimization_models.dart';
import 'route_optimization_port.dart';
import 'vroom_route_optimization_adapter.dart';

class LockedRouteOptimizationAdapter implements RouteOptimizationPort {
  LockedRouteOptimizationAdapter({required this.vroom, required this.osrm});

  final VroomRouteOptimizationAdapter vroom;
  final OsrmDirectLegClient osrm;

  @override
  String get providerId => 'vroom-osrm-locked-segments';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.throwIfCancelled();

    const segmenter = LockedRouteSegmenter();
    final segmentation = segmenter.split(request);
    final stopwatch = Stopwatch()..start();

    final stopsById = {for (final stop in request.plan.stops) stop.id: stop};
    final tasksByStop = <String, List<RouteTask>>{};

    for (final task in request.plan.pendingTasks) {
      tasksByStop.putIfAbsent(task.stopId, () => []).add(task);
    }

    final order = <String>[];
    final legs = <VehicleLeg>[];
    var currentLocation = request.currentLocation;
    var currentStopId = 'CURRENT_LOCATION';
    var elapsedRouteTime = Duration.zero;

    Duration remainingTime() {
      cancellationSignal?.throwIfCancelled();

      final remaining = request.timeout - stopwatch.elapsed;

      if (remaining <= Duration.zero) {
        throw const RouteOptimizationFailure(
          type: RouteOptimizationFailureType.timeout,
          message: 'Segmented route optimization exceeded its total timeout.',
        );
      }

      return remaining;
    }

    Duration serviceAt(String stopId) {
      final microseconds = tasksByStop[stopId]!.fold<int>(
        0,
        (total, task) => total + task.serviceDuration.inMicroseconds,
      );

      final seconds =
          (microseconds + Duration.microsecondsPerSecond - 1) ~/
          Duration.microsecondsPerSecond;

      return Duration(seconds: seconds);
    }

    try {
      for (var index = 0; index < segmentation.segments.length; index++) {
        remainingTime();

        final segment = segmentation.segments[index];
        final lockedId = segment.endingLockedStopId;

        if (segment.stopIds.isNotEmpty) {
          final segmentTasks = [
            for (final id in segment.stopIds) ...tasksByStop[id]!,
          ];

          final segmentStops = [
            for (final id in segment.stopIds)
              OperationalStop(
                id: id,
                coordinate: stopsById[id]!.coordinate,
                taskIds: tasksByStop[id]!
                    .map((task) => task.id)
                    .toList(growable: false),
              ),
          ];

          final segmentRequest = RouteOptimizationRequest(
            plan: RoutePlan(
              id: '${request.plan.id}-SEGMENT-$index',
              currentOrder: segment.stopIds,
              stops: segmentStops,
              tasks: segmentTasks,
            ),
            currentLocation: currentLocation,
            departureAt: request.departureAt.add(elapsedRouteTime),
            timeout: remainingTime(),
            reoptimizePendingOnly: true,
          );

          final candidate = await vroom.optimize(
            segmentRequest,
            endLocation: lockedId == null
                ? null
                : stopsById[lockedId]!.coordinate,
            cancellationSignal: cancellationSignal,
          );

          remainingTime();

          if (candidate.stopOrder.length != segment.stopIds.length ||
              candidate.stopOrder.toSet().length != segment.stopIds.length ||
              !candidate.stopOrder.toSet().containsAll(segment.stopIds)) {
            _reject('A segment returned an inconsistent stop order.');
          }

          if (candidate.metrics.waitingDuration != Duration.zero ||
              candidate.metrics.departureDelay != Duration.zero) {
            _reject('Unexpected waiting or departure delay in a segment.');
          }

          final expectedLegCount =
              candidate.stopOrder.length + (lockedId == null ? 0 : 1);

          if (candidate.vehicleLegs.length != expectedLegCount) {
            _reject('A segment returned an unexpected number of legs.');
          }

          final expectedService = segment.stopIds.fold<Duration>(
            Duration.zero,
            (total, stopId) => total + serviceAt(stopId),
          );

          if (candidate.metrics.serviceDuration != expectedService) {
            _reject('A segment returned inconsistent service duration.');
          }

          for (
            var legIndex = 0;
            legIndex < candidate.vehicleLegs.length;
            legIndex++
          ) {
            final leg = candidate.vehicleLegs[legIndex];
            final isFinalDestination =
                lockedId != null &&
                legIndex == candidate.vehicleLegs.length - 1;

            final expectedFrom = legIndex == 0
                ? 'CURRENT_LOCATION'
                : candidate.stopOrder[legIndex - 1];
            final expectedTo = isFinalDestination
                ? 'END_LOCATION'
                : candidate.stopOrder[legIndex];

            if (leg.fromStopId != expectedFrom || leg.toStopId != expectedTo) {
              _reject('A segment returned disconnected route legs.');
            }

            legs.add(
              VehicleLeg(
                fromStopId: legIndex == 0 ? currentStopId : leg.fromStopId,
                toStopId: isFinalDestination ? lockedId : leg.toStopId,
                distanceMeters: leg.distanceMeters,
                duration: leg.duration,
              ),
            );
          }

          order.addAll(candidate.stopOrder);
          elapsedRouteTime += candidate.metrics.totalDuration;

          if (lockedId == null) {
            currentStopId = candidate.stopOrder.last;
            currentLocation = stopsById[currentStopId]!.coordinate;
          }
        } else if (lockedId != null) {
          final leg = await osrm.calculate(
            fromStopId: currentStopId,
            toStopId: lockedId,
            from: currentLocation,
            to: stopsById[lockedId]!.coordinate,
            timeout: remainingTime(),
            cancellationSignal: cancellationSignal,
          );

          remainingTime();
          legs.add(leg);
          elapsedRouteTime += leg.duration;
        }

        if (lockedId != null) {
          order.add(lockedId);
          elapsedRouteTime += serviceAt(lockedId);
          currentStopId = lockedId;
          currentLocation = stopsById[lockedId]!.coordinate;
        }
      }

      remainingTime();

      segmenter.validateOrder(
        segmentation: segmentation,
        candidateOrder: order,
      );

      final travelDuration = legs.fold<Duration>(
        Duration.zero,
        (total, leg) => total + leg.duration,
      );
      final serviceDuration = tasksByStop.keys.fold<Duration>(
        Duration.zero,
        (total, stopId) => total + serviceAt(stopId),
      );

      if (elapsedRouteTime != travelDuration + serviceDuration) {
        _reject('The combined route has inconsistent duration totals.');
      }

      return RouteCandidate(
        stopOrder: List.unmodifiable(order),
        vehicleLegs: List.unmodifiable(legs),
        metrics: RouteMetrics(
          distanceMeters: legs.fold<int>(
            0,
            (total, leg) => total + leg.distanceMeters,
          ),
          travelDuration: travelDuration,
          serviceDuration: serviceDuration,
          calculationDuration: stopwatch.elapsed,
        ),
        explanation: const OptimizationExplanation(
          summary: 'Route optimized within manually locked boundaries.',
          warnings: [
            'Stops remain on their original side of each locked boundary.',
            'Segmented search does not guarantee a global optimum.',
            'Time windows and walking clusters are not supported.',
            'Travel estimates do not include live traffic.',
          ],
        ),
      );
    } finally {
      stopwatch.stop();
    }
  }

  Never _reject(String message) {
    throw RouteOptimizationFailure(
      type: RouteOptimizationFailureType.invalidResponse,
      message: message,
    );
  }
}
