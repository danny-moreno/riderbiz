import 'route_optimization_models.dart';
import 'route_optimization_port.dart';
import 'route_optimization_request_validator.dart';

class LockedRouteSegment {
  LockedRouteSegment({required List<String> stopIds, this.endingLockedStopId})
    : stopIds = List.unmodifiable(stopIds);

  final List<String> stopIds;
  final String? endingLockedStopId;
}

class LockedRouteSegmentation {
  LockedRouteSegmentation({
    required List<String> pendingOrder,
    required List<LockedRouteSegment> segments,
    required Map<String, int> lockedPositions,
  }) : pendingOrder = List.unmodifiable(pendingOrder),
       segments = List.unmodifiable(segments),
       lockedPositions = Map.unmodifiable(lockedPositions);

  final List<String> pendingOrder;
  final List<LockedRouteSegment> segments;
  final Map<String, int> lockedPositions;
}

class LockedRouteSegmenter {
  const LockedRouteSegmenter();

  LockedRouteSegmentation split(RouteOptimizationRequest request) {
    const RouteOptimizationRequestValidator().validate(request);

    final pendingTasks = request.plan.pendingTasks;
    final pendingStopIds = pendingTasks.map((task) => task.stopId).toSet();
    final stopsById = {for (final stop in request.plan.stops) stop.id: stop};

    if (pendingTasks.any((task) => task.timeWindow != null)) {
      _reject('Segmented optimization does not support time windows yet.');
    }

    if (pendingStopIds.any((id) => stopsById[id]!.walkingClusterId != null)) {
      _reject('Segmented optimization does not support walking clusters yet.');
    }

    final pendingOrder = <String>[];
    final included = <String>{};

    for (final id in request.plan.currentOrder) {
      if (pendingStopIds.contains(id) && included.add(id)) {
        pendingOrder.add(id);
      }
    }

    for (final task in pendingTasks) {
      if (included.add(task.stopId)) {
        pendingOrder.add(task.stopId);
      }
    }

    final segments = <LockedRouteSegment>[];
    final lockedPositions = <String, int>{};
    var currentStopIds = <String>[];

    for (var index = 0; index < pendingOrder.length; index++) {
      final stopId = pendingOrder[index];
      final stop = stopsById[stopId]!;

      if (stop.isLocked) {
        lockedPositions[stopId] = index;
        segments.add(
          LockedRouteSegment(
            stopIds: currentStopIds,
            endingLockedStopId: stopId,
          ),
        );
        currentStopIds = <String>[];
      } else {
        currentStopIds.add(stopId);
      }
    }

    if (currentStopIds.isNotEmpty) {
      segments.add(LockedRouteSegment(stopIds: currentStopIds));
    }

    return LockedRouteSegmentation(
      pendingOrder: pendingOrder,
      segments: segments,
      lockedPositions: lockedPositions,
    );
  }

  void validateOrder({
    required LockedRouteSegmentation segmentation,
    required List<String> candidateOrder,
  }) {
    if (candidateOrder.length != segmentation.pendingOrder.length ||
        candidateOrder.toSet().length != candidateOrder.length ||
        !candidateOrder.toSet().containsAll(segmentation.pendingOrder)) {
      _rejectResult('The candidate must contain every pending stop once.');
    }

    for (final entry in segmentation.lockedPositions.entries) {
      if (candidateOrder[entry.value] != entry.key) {
        _rejectResult('The candidate moved a locked stop.');
      }
    }

    var offset = 0;

    for (final segment in segmentation.segments) {
      final actualStopIds = candidateOrder
          .skip(offset)
          .take(segment.stopIds.length)
          .toSet();

      if (actualStopIds.length != segment.stopIds.length ||
          !actualStopIds.containsAll(segment.stopIds)) {
        _rejectResult('The candidate moved stops across a locked boundary.');
      }

      offset += segment.stopIds.length;

      if (segment.endingLockedStopId != null) {
        if (candidateOrder[offset] != segment.endingLockedStopId) {
          _rejectResult('The candidate changed a segment boundary.');
        }
        offset++;
      }
    }
  }

  Never _reject(String message) {
    throw RouteOptimizationFailure(
      type: RouteOptimizationFailureType.invalidRequest,
      message: message,
    );
  }

  Never _rejectResult(String message) {
    throw RouteOptimizationFailure(
      type: RouteOptimizationFailureType.invalidResponse,
      message: message,
    );
  }
}
