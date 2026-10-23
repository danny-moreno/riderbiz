import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

import '../../support/route_optimization/vroom_vehicle_scenario_factory.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  const factory = VroomVehicleScenarioFactory();

  test(
    'reoptimizes 60 pending tasks after completing 20 of 80',
    () async {
      final scenario = factory.create(taskCount: 80, completedTaskCount: 20);

      final departure = DateTime.utc(2026, 10, 23, 10);

      final request = RouteOptimizationRequest(
        plan: scenario.plan,
        currentLocation: scenario.plan.stops[19].coordinate,
        departureAt: departure,
        timeout: scenario.timeout,
        reoptimizePendingOnly: true,
      );

      final pendingTasks = request.plan.pendingTasks;
      final pendingStopIds = pendingTasks.map((task) => task.stopId).toSet();
      final completedStopIds = request.plan.tasks
          .where((task) => task.status == RouteTaskStatus.completed)
          .map((task) => task.stopId)
          .toSet();

      final originalOrder = List<String>.of(request.plan.currentOrder);
      final originalStatuses = {
        for (final task in request.plan.tasks) task.id: task.status,
      };

      final adapter = VroomRouteOptimizationAdapter(
        endpoint: Uri.parse('http://127.0.0.1:3000/'),
      );

      final candidate = await adapter.optimize(request);

      expect(request.plan.tasks, hasLength(80));
      expect(completedStopIds, hasLength(20));
      expect(pendingTasks, hasLength(60));
      expect(candidate.stopOrder, hasLength(60));
      expect(candidate.stopOrder.toSet(), pendingStopIds);
      expect(candidate.stopOrder.any(completedStopIds.contains), isFalse);

      expect(candidate.vehicleLegs, hasLength(60));
      expect(candidate.vehicleLegs.first.fromStopId, 'CURRENT_LOCATION');
      expect(candidate.vehicleLegs.first.toStopId, candidate.stopOrder.first);

      for (var index = 1; index < candidate.vehicleLegs.length; index++) {
        final leg = candidate.vehicleLegs[index];

        expect(leg.fromStopId, candidate.stopOrder[index - 1]);
        expect(leg.toStopId, candidate.stopOrder[index]);
      }

      final expectedService = pendingTasks.fold<Duration>(
        Duration.zero,
        (total, task) => total + task.serviceDuration,
      );

      expect(candidate.metrics.serviceDuration, expectedService);
      expect(candidate.metrics.serviceDuration.inSeconds, 8640);
      expect(candidate.metrics.waitingDuration, Duration.zero);
      expect(candidate.metrics.departureDelay, Duration.zero);
      expect(candidate.metrics.distanceMeters, greaterThan(0));

      expect(request.plan.currentOrder, originalOrder);
      expect({
        for (final task in request.plan.tasks) task.id: task.status,
      }, originalStatuses);

      // Synthetic reoptimization evidence, not application telemetry.
      // ignore: avoid_print
      print(
        jsonEncode({
          'scenario': 'reoptimization_after_20_of_80_completed',
          'total_tasks': request.plan.tasks.length,
          'completed_tasks': completedStopIds.length,
          'pending_tasks': pendingTasks.length,
          'proposed_stops': candidate.stopOrder.length,
          'completed_stops_reintroduced': false,
          'departure_at_utc': request.departureAt.toUtc().toIso8601String(),
          'distance_m': candidate.metrics.distanceMeters,
          'travel_seconds': candidate.metrics.travelDuration.inSeconds,
          'service_seconds': candidate.metrics.serviceDuration.inSeconds,
          'waiting_seconds': candidate.metrics.waitingDuration.inSeconds,
          'departure_delay_seconds': candidate.metrics.departureDelay.inSeconds,
          'total_seconds': candidate.metrics.totalDuration.inSeconds,
        }),
      );
    },
    skip: enabled ? false : 'Requires RUN_LOCAL_VROOM=true and local services.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
