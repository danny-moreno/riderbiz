import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/locked_route_optimization_adapter.dart';
import 'package:riderbiz_mobile/features/route_optimization/locked_route_segmenter.dart';
import 'package:riderbiz_mobile/features/route_optimization/osrm_direct_leg_client.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

import '../../support/route_optimization/vroom_vehicle_scenario_factory.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  const factory = VroomVehicleScenarioFactory();

  test(
    'preserves initial consecutive and final locks with local engines',
    () async {
      final scenario = factory.create(taskCount: 60);
      const lockedIndexes = {0, 19, 20, 59};

      final stops = [
        for (var index = 0; index < scenario.plan.stops.length; index++)
          OperationalStop(
            id: scenario.plan.stops[index].id,
            coordinate: scenario.plan.stops[index].coordinate,
            taskIds: scenario.plan.stops[index].taskIds,
            isLocked: lockedIndexes.contains(index),
          ),
      ];

      final request = RouteOptimizationRequest(
        plan: RoutePlan(
          id: 'ROUTE-SYN-LOCKED-RUNTIME',
          currentOrder: scenario.plan.currentOrder,
          stops: stops,
          tasks: scenario.plan.tasks,
        ),
        currentLocation: scenario.currentLocation,
        departureAt: scenario.departureAt,
        timeout: const Duration(seconds: 60),
        reoptimizePendingOnly: true,
      );

      final originalOrder = List<String>.of(request.plan.currentOrder);
      final originalStatuses = {
        for (final task in request.plan.tasks) task.id: task.status,
      };

      final segmentation = const LockedRouteSegmenter().split(request);
      final adapter = LockedRouteOptimizationAdapter(
        vroom: VroomRouteOptimizationAdapter(
          endpoint: Uri.parse('http://127.0.0.1:3000/'),
        ),
        osrm: OsrmDirectLegClient(
          endpoint: Uri.parse('http://127.0.0.1:5000/'),
        ),
      );

      final candidate = await adapter.optimize(request);

      expect(candidate.stopOrder, hasLength(60));
      expect(candidate.stopOrder.toSet(), originalOrder.toSet());

      for (final index in lockedIndexes) {
        expect(candidate.stopOrder[index], originalOrder[index]);
      }

      expect(
        () => const LockedRouteSegmenter().validateOrder(
          segmentation: segmentation,
          candidateOrder: candidate.stopOrder,
        ),
        returnsNormally,
      );

      expect(candidate.vehicleLegs, hasLength(60));

      for (var index = 0; index < candidate.vehicleLegs.length; index++) {
        final leg = candidate.vehicleLegs[index];

        expect(
          leg.fromStopId,
          index == 0 ? 'CURRENT_LOCATION' : candidate.stopOrder[index - 1],
        );
        expect(leg.toStopId, candidate.stopOrder[index]);
      }

      final distance = candidate.vehicleLegs.fold<int>(
        0,
        (total, leg) => total + leg.distanceMeters,
      );
      final travel = candidate.vehicleLegs.fold<Duration>(
        Duration.zero,
        (total, leg) => total + leg.duration,
      );
      final service = request.plan.pendingTasks.fold<Duration>(
        Duration.zero,
        (total, task) => total + task.serviceDuration,
      );

      expect(candidate.metrics.distanceMeters, distance);
      expect(candidate.metrics.travelDuration, travel);
      expect(candidate.metrics.serviceDuration, service);
      expect(candidate.metrics.serviceDuration.inSeconds, 8640);
      expect(candidate.metrics.departureDelay, Duration.zero);
      expect(candidate.metrics.waitingDuration, Duration.zero);
      expect(candidate.metrics.totalDuration, travel + service);

      expect(request.plan.currentOrder, originalOrder);
      expect({
        for (final task in request.plan.tasks) task.id: task.status,
      }, originalStatuses);

      // Synthetic runtime evidence, not application telemetry.
      // ignore: avoid_print
      print(
        jsonEncode({
          'scenario': '60_tasks_with_initial_consecutive_and_final_locks',
          'task_count': request.plan.tasks.length,
          'proposed_stops': candidate.stopOrder.length,
          'locked_positions_zero_based': {
            for (final entry in segmentation.lockedPositions.entries)
              entry.key: entry.value,
          },
          'vehicle_legs': candidate.vehicleLegs.length,
          'distance_m': candidate.metrics.distanceMeters,
          'travel_seconds':
              candidate.metrics.travelDuration.inMicroseconds / 1000000,
          'service_seconds': candidate.metrics.serviceDuration.inSeconds,
          'total_seconds':
              candidate.metrics.totalDuration.inMicroseconds / 1000000,
          'calculation_ms':
              candidate.metrics.calculationDuration.inMicroseconds / 1000,
        }),
      );
    },
    skip: enabled ? false : 'Requires RUN_LOCAL_VROOM=true and local services.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
