import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

import '../../support/route_optimization/daily_delivery_scenario_factory.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  const factory = DailyDeliveryScenarioFactory();

  for (final size in [
    (100, 100),
    (125, 125),
    (150, 150),
    (150, 110),
    (150, 60),
  ]) {
    for (final completed in [0, size.$1 ~/ 2]) {
      test(
        'local daily route: ${size.$1} packages, ${size.$2} stops, $completed completed',
        () async {
          final request = factory.create(
            packageCount: size.$1,
            stopCount: size.$2,
            completedPackageCount: completed,
          );
          final adapter = VroomRouteOptimizationAdapter(
            endpoint: Uri.parse('http://127.0.0.1:3000/'),
          );
          final expectedStops = request.plan.pendingTasks
              .map((task) => task.stopId)
              .toSet();

          final stopwatch = Stopwatch()..start();
          final candidate = await adapter.optimize(request);
          stopwatch.stop();

          expect(candidate.stopOrder, hasLength(expectedStops.length));
          expect(candidate.stopOrder.toSet(), expectedStops);
          expect(candidate.vehicleLegs, hasLength(expectedStops.length));
          expect(
            candidate.metrics.serviceDuration,
            Duration(seconds: (size.$1 - completed) * 60),
          );
          expect(candidate.metrics.distanceMeters, greaterThan(0));
          expect(
            candidate.vehicleLegs.fold<int>(
              0,
              (total, leg) => total + leg.distanceMeters,
            ),
            candidate.metrics.distanceMeters,
          );
          expect(
            candidate.vehicleLegs.fold<Duration>(
              Duration.zero,
              (total, leg) => total + leg.duration,
            ),
            candidate.metrics.travelDuration,
          );

          // Structured synthetic evidence, not application telemetry.
          // ignore: avoid_print
          print(
            jsonEncode({
              'scenario': 'daily_delivery_synthetic_grid',
              'packages': size.$1,
              'stops': size.$2,
              'completed_packages': completed,
              'pending_packages': request.plan.pendingTasks.length,
              'returned_stops': candidate.stopOrder.length,
              'elapsed_ms': stopwatch.elapsedMicroseconds / 1000,
              'distance_m': candidate.metrics.distanceMeters,
              'travel_seconds': candidate.metrics.travelDuration.inSeconds,
              'service_seconds': candidate.metrics.serviceDuration.inSeconds,
              'total_seconds': candidate.metrics.totalDuration.inSeconds,
            }),
          );
        },
        skip: enabled
            ? false
            : 'Requires RUN_LOCAL_VROOM=true and local services.',
        timeout: const Timeout(Duration(minutes: 1)),
      );
    }
  }
}
