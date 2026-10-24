import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

class DailyDeliveryScenarioFactory {
  const DailyDeliveryScenarioFactory();

  RouteOptimizationRequest create({
    required int packageCount,
    required int stopCount,
    int completedPackageCount = 0,
  }) {
    if (![100, 125, 150].contains(packageCount)) {
      throw ArgumentError.value(packageCount, 'packageCount');
    }
    if (stopCount < 1 || stopCount > packageCount) {
      throw ArgumentError.value(stopCount, 'stopCount');
    }
    if (completedPackageCount < 0 || completedPackageCount > packageCount) {
      throw ArgumentError.value(completedPackageCount, 'completedPackageCount');
    }

    String stopId(int index) =>
        'STOP-DAILY-${(index + 1).toString().padLeft(3, '0')}';
    String taskId(int index) =>
        'PACKAGE-DAILY-${(index + 1).toString().padLeft(3, '0')}';

    final taskIdsByStop = List.generate(stopCount, (_) => <String>[]);
    final tasks = <RouteTask>[];

    for (var index = 0; index < packageCount; index++) {
      final stopIndex = index % stopCount;
      taskIdsByStop[stopIndex].add(taskId(index));
      tasks.add(
        RouteTask(
          id: taskId(index),
          stopId: stopId(stopIndex),
          type: RouteTaskType.delivery,
          status: index < completedPackageCount
              ? RouteTaskStatus.completed
              : RouteTaskStatus.pending,
          priority: RoutePriority.normal,
          serviceDuration: const Duration(seconds: 60),
        ),
      );
    }

    final stops = [
      for (var index = 0; index < stopCount; index++)
        OperationalStop(
          id: stopId(index),
          coordinate: RouteCoordinate(
            latitude: 42.8100 + (index ~/ 10) * 0.0005,
            longitude: -1.6400 + (index % 10) * 0.0005,
          ),
          taskIds: List.unmodifiable(taskIdsByStop[index]),
        ),
    ];

    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'DAILY-$packageCount-$stopCount',
        currentOrder: List.unmodifiable(stops.map((stop) => stop.id)),
        stops: List.unmodifiable(stops),
        tasks: List.unmodifiable(tasks),
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.utc(2026, 10, 24, 8),
      timeout: const Duration(seconds: 40),
      reoptimizePendingOnly: completedPackageCount > 0,
    );
  }
}
