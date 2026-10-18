import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

class VroomVehicleScenarioFactory {
  const VroomVehicleScenarioFactory();

  RouteOptimizationRequest create({
    required int taskCount,
    int completedTaskCount = 0,
  }) {
    if (![60, 80, 120].contains(taskCount)) {
      throw ArgumentError.value(
        taskCount,
        'taskCount',
        'Supported scenario sizes are 60, 80 and 120 tasks.',
      );
    }

    if (completedTaskCount < 0 || completedTaskCount > taskCount) {
      throw ArgumentError.value(
        completedTaskCount,
        'completedTaskCount',
        'Completed tasks must be between zero and task count.',
      );
    }

    final stops = <OperationalStop>[];
    final tasks = <RouteTask>[];

    for (var index = 0; index < taskCount; index++) {
      final suffix = (index + 1).toString().padLeft(3, '0');
      final stopId = 'STOP-SYN-VEHICLE-$suffix';
      final taskId = 'TASK-SYN-VEHICLE-$suffix';
      final isPickup = index % 5 == 0;

      final row = index ~/ 10;
      final column = index % 10;

      stops.add(
        OperationalStop(
          id: stopId,
          coordinate: RouteCoordinate(
            latitude: 42.8100 + row * 0.0005,
            longitude: -1.6400 + column * 0.0005,
          ),
          taskIds: [taskId],
        ),
      );

      tasks.add(
        RouteTask(
          id: taskId,
          stopId: stopId,
          type: isPickup ? RouteTaskType.pickup : RouteTaskType.delivery,
          status: index < completedTaskCount
              ? RouteTaskStatus.completed
              : RouteTaskStatus.pending,
          priority: RoutePriority.normal,
          serviceDuration: Duration(minutes: isPickup ? 4 : 2),
        ),
      );
    }

    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-VEHICLE-$taskCount',
        currentOrder: List.unmodifiable(stops.map((stop) => stop.id)),
        stops: List.unmodifiable(stops),
        tasks: List.unmodifiable(tasks),
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.utc(2026, 10, 18, 8),
      timeout: const Duration(seconds: 40),
      reoptimizePendingOnly: completedTaskCount > 0,
    );
  }
}
