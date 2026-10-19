import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_candidate_comparator.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

import '../../support/route_optimization/osrm_route_order_evaluator.dart';
import '../../support/route_optimization/vroom_vehicle_scenario_factory.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  const factory = VroomVehicleScenarioFactory();
  const comparator = RouteCandidateComparator();

  for (final taskCount in [60, 80, 120]) {
    test(
      'compares initial and VROOM orders for $taskCount tasks',
      () async {
        final request = factory.create(taskCount: taskCount);

        final adapter = VroomRouteOptimizationAdapter(
          endpoint: Uri.parse('http://127.0.0.1:3000/'),
        );
        final evaluator = OsrmRouteOrderEvaluator(
          endpoint: Uri.parse('http://127.0.0.1:5000/'),
        );

        final candidate = await adapter.optimize(request);

        final expectedStops = request.plan.pendingTasks
            .map((task) => task.stopId)
            .toSet();

        expect(candidate.stopOrder, hasLength(expectedStops.length));
        expect(candidate.stopOrder.toSet(), expectedStops);

        final initialMetrics = await evaluator.evaluate(
          request: request,
          stopOrder: request.plan.currentOrder,
        );

        final candidateMetrics = await evaluator.evaluate(
          request: request,
          stopOrder: candidate.stopOrder,
        );

        expect(
          initialMetrics.serviceDuration,
          candidateMetrics.serviceDuration,
        );
        expect(initialMetrics.waitingDuration, Duration.zero);
        expect(candidateMetrics.waitingDuration, Duration.zero);
        expect(initialMetrics.distanceMeters, greaterThan(0));
        expect(candidateMetrics.distanceMeters, greaterThan(0));

        final comparison = comparator.compare(
          currentMetrics: initialMetrics,
          candidateMetrics: candidateMetrics,
        );

        // Structured synthetic comparison evidence, not product telemetry.
        // ignore: avoid_print
        print(
          jsonEncode({
            'scenario': 'synthetic_grid_initial_order_comparison',
            'task_count': taskCount,
            'baseline': 'generated_order_not_an_experienced_driver_route',
            'evaluator': 'same_local_osrm_for_both_orders',
            'initial': {
              'distance_m': initialMetrics.distanceMeters,
              'travel_seconds':
                  initialMetrics.travelDuration.inMicroseconds / 1000000,
              'service_seconds': initialMetrics.serviceDuration.inSeconds,
              'total_seconds':
                  initialMetrics.totalDuration.inMicroseconds / 1000000,
            },
            'candidate': {
              'distance_m': candidateMetrics.distanceMeters,
              'travel_seconds':
                  candidateMetrics.travelDuration.inMicroseconds / 1000000,
              'service_seconds': candidateMetrics.serviceDuration.inSeconds,
              'total_seconds':
                  candidateMetrics.totalDuration.inMicroseconds / 1000000,
            },
            'comparison': {
              'outcome': comparison.outcome.name,
              'distance_saved_m': comparison.distanceSavedMeters,
              'duration_saved_seconds':
                  comparison.durationSaved.inMicroseconds / 1000000,
              'distance_improvement_percent':
                  comparison.distanceImprovementPercent,
              'duration_improvement_percent':
                  comparison.durationImprovementPercent,
              'should_recommend': comparison.shouldRecommend,
            },
          }),
        );
      },
      skip: enabled
          ? false
          : 'Requires RUN_LOCAL_VROOM=true and local services.',
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}
