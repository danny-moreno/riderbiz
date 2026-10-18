import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

import '../../support/route_optimization/route_optimization_benchmark.dart';
import '../../support/route_optimization/vroom_vehicle_scenario_factory.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  const factory = VroomVehicleScenarioFactory();
  const benchmark = RouteOptimizationBenchmark();

  for (final taskCount in [60, 80, 120]) {
    test(
      'benchmarks $taskCount tasks through local VROOM and OSRM',
      () async {
        final request = factory.create(taskCount: taskCount);
        final adapter = VroomRouteOptimizationAdapter(
          endpoint: Uri.parse('http://127.0.0.1:3000/'),
        );

        final result = await benchmark.run(
          adapter: adapter,
          request: request,
          repetitions: 5,
        );

        final expectedStops = request.plan.stops.map((stop) => stop.id).toSet();
        final expectedService = request.plan.pendingTasks.fold<Duration>(
          Duration.zero,
          (total, task) => total + task.serviceDuration,
        );

        expect(result.candidates, hasLength(5));

        for (final candidate in result.candidates) {
          expect(candidate.stopOrder, hasLength(taskCount));
          expect(candidate.stopOrder.toSet(), expectedStops);
          expect(candidate.vehicleLegs, hasLength(taskCount));
          expect(candidate.metrics.distanceMeters, greaterThan(0));
          expect(candidate.metrics.serviceDuration, expectedService);
          expect(candidate.metrics.waitingDuration, Duration.zero);

          final legDistance = candidate.vehicleLegs.fold<int>(
            0,
            (total, leg) => total + leg.distanceMeters,
          );
          final legDuration = candidate.vehicleLegs.fold<Duration>(
            Duration.zero,
            (total, leg) => total + leg.duration,
          );

          expect(legDistance, candidate.metrics.distanceMeters);
          expect(legDuration, candidate.metrics.travelDuration);
        }

        // Structured benchmark evidence, not application telemetry.
        // ignore: avoid_print
        print(
          jsonEncode({
            'scenario': 'synthetic_vehicle_without_time_windows',
            'provider': result.providerId,
            'task_count': taskCount,
            'repetitions': result.repetitions,
            'minimum_ms': result.minimumDuration.inMicroseconds / 1000,
            'median_ms': result.medianDuration.inMicroseconds / 1000,
            'p95_ms': result.percentile95Duration.inMicroseconds / 1000,
            'maximum_ms': result.maximumDuration.inMicroseconds / 1000,
            'order_repeatable': result.isOrderRepeatable,
            'runs': [
              for (final candidate in result.candidates)
                {
                  'distance_m': candidate.metrics.distanceMeters,
                  'travel_seconds': candidate.metrics.travelDuration.inSeconds,
                  'service_seconds':
                      candidate.metrics.serviceDuration.inSeconds,
                  'waiting_seconds':
                      candidate.metrics.waitingDuration.inSeconds,
                  'total_seconds': candidate.metrics.totalDuration.inSeconds,
                },
            ],
          }),
        );
      },
      skip: enabled
          ? false
          : 'Requires RUN_LOCAL_VROOM=true and local services.',
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
}
