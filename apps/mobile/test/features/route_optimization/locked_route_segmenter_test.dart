import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/locked_route_segmenter.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';

void main() {
  const segmenter = LockedRouteSegmenter();

  RouteOptimizationRequest request({
    List<String> ids = const ['A', 'B', 'C', 'D', 'E'],
    Set<String> locked = const {},
    Set<String> completed = const {},
    List<String>? order,
    bool withWindow = false,
  }) {
    final departure = DateTime.utc(2026, 10, 23, 8);

    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-LOCKED',
        currentOrder: order ?? ids,
        stops: [
          for (final id in ids)
            OperationalStop(
              id: id,
              coordinate: const RouteCoordinate(
                latitude: 42.81,
                longitude: -1.64,
              ),
              taskIds: ['TASK-$id'],
              isLocked: locked.contains(id),
            ),
        ],
        tasks: [
          for (final id in ids)
            RouteTask(
              id: 'TASK-$id',
              stopId: id,
              type: RouteTaskType.delivery,
              status: completed.contains(id)
                  ? RouteTaskStatus.completed
                  : RouteTaskStatus.pending,
              priority: RoutePriority.normal,
              serviceDuration: const Duration(minutes: 2),
              timeWindow: withWindow
                  ? RouteTimeWindow(
                      startsAt: departure,
                      endsAt: departure.add(const Duration(hours: 8)),
                    )
                  : null,
            ),
        ],
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: departure,
      timeout: const Duration(seconds: 40),
      reoptimizePendingOnly: true,
    );
  }

  Matcher failure(RouteOptimizationFailureType type) {
    return throwsA(
      isA<RouteOptimizationFailure>().having(
        (error) => error.type,
        'type',
        type,
      ),
    );
  }

  group('LockedRouteSegmenter', () {
    test('creates one open segment without locked stops', () {
      final result = segmenter.split(request());

      expect(result.pendingOrder, ['A', 'B', 'C', 'D', 'E']);
      expect(result.segments, hasLength(1));
      expect(result.segments.single.stopIds, result.pendingOrder);
      expect(result.segments.single.endingLockedStopId, isNull);
      expect(result.lockedPositions, isEmpty);
    });

    test('splits the pending order around a middle locked stop', () {
      final result = segmenter.split(request(locked: {'C'}));

      expect(result.segments, hasLength(2));
      expect(result.segments.first.stopIds, ['A', 'B']);
      expect(result.segments.first.endingLockedStopId, 'C');
      expect(result.segments.last.stopIds, ['D', 'E']);
      expect(result.segments.last.endingLockedStopId, isNull);
      expect(result.lockedPositions, {'C': 2});
    });

    test('supports a locked first stop with an empty first segment', () {
      final result = segmenter.split(request(locked: {'A'}));

      expect(result.segments, hasLength(2));
      expect(result.segments.first.stopIds, isEmpty);
      expect(result.segments.first.endingLockedStopId, 'A');
      expect(result.segments.last.stopIds, ['B', 'C', 'D', 'E']);
      expect(result.lockedPositions, {'A': 0});
    });

    test('supports a locked final stop without an extra empty tail', () {
      final result = segmenter.split(request(locked: {'E'}));

      expect(result.segments, hasLength(1));
      expect(result.segments.single.stopIds, ['A', 'B', 'C', 'D']);
      expect(result.segments.single.endingLockedStopId, 'E');
    });

    test('supports consecutive locked stops', () {
      final result = segmenter.split(request(locked: {'B', 'C'}));

      expect(result.segments, hasLength(3));
      expect(result.segments[0].stopIds, ['A']);
      expect(result.segments[0].endingLockedStopId, 'B');
      expect(result.segments[1].stopIds, isEmpty);
      expect(result.segments[1].endingLockedStopId, 'C');
      expect(result.segments[2].stopIds, ['D', 'E']);
    });

    test('counts locked positions within the pending order', () {
      final result = segmenter.split(request(locked: {'C'}, completed: {'A'}));

      expect(result.pendingOrder, ['B', 'C', 'D', 'E']);
      expect(result.lockedPositions, {'C': 1});
      expect(result.segments.first.stopIds, ['B']);
    });

    test('appends unlocked pending stops omitted from the current order', () {
      final result = segmenter.split(
        request(order: ['A', 'B', 'C'], locked: {'C'}),
      );

      expect(result.pendingOrder, ['A', 'B', 'C', 'D', 'E']);
      expect(result.segments.last.stopIds, ['D', 'E']);
    });

    test('returns no segments when every task is completed', () {
      final result = segmenter.split(
        request(completed: {'A', 'B', 'C', 'D', 'E'}),
      );

      expect(result.pendingOrder, isEmpty);
      expect(result.segments, isEmpty);
      expect(result.lockedPositions, isEmpty);
    });

    test('accepts reordering inside each unlocked segment', () {
      final result = segmenter.split(request(locked: {'C'}));

      expect(
        () => segmenter.validateOrder(
          segmentation: result,
          candidateOrder: ['B', 'A', 'C', 'E', 'D'],
        ),
        returnsNormally,
      );
    });

    test('rejects movement of a locked stop', () {
      final result = segmenter.split(request(locked: {'C'}));

      expect(
        () => segmenter.validateOrder(
          segmentation: result,
          candidateOrder: ['A', 'C', 'B', 'D', 'E'],
        ),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test(
      'rejects crossing a boundary even if the lock position stays fixed',
      () {
        final result = segmenter.split(request(locked: {'C'}));

        expect(
          () => segmenter.validateOrder(
            segmentation: result,
            candidateOrder: ['D', 'B', 'C', 'A', 'E'],
          ),
          failure(RouteOptimizationFailureType.invalidResponse),
        );
      },
    );

    test('rejects duplicated or missing stops', () {
      final result = segmenter.split(request(locked: {'C'}));

      expect(
        () => segmenter.validateOrder(
          segmentation: result,
          candidateOrder: ['A', 'A', 'C', 'D', 'E'],
        ),
        failure(RouteOptimizationFailureType.invalidResponse),
      );

      expect(
        () => segmenter.validateOrder(
          segmentation: result,
          candidateOrder: ['A', 'B', 'C', 'D'],
        ),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('rejects time windows explicitly', () {
      expect(
        () => segmenter.split(request(locked: {'C'}, withWindow: true)),
        failure(RouteOptimizationFailureType.invalidRequest),
      );
    });

    test('protects segment collections from modification', () {
      final result = segmenter.split(request(locked: {'C'}));

      expect(() => result.pendingOrder.clear(), throwsUnsupportedError);
      expect(() => result.segments.clear(), throwsUnsupportedError);
      expect(
        () => result.segments.first.stopIds.clear(),
        throwsUnsupportedError,
      );
      expect(() => result.lockedPositions.clear(), throwsUnsupportedError);
    });
  });
}
