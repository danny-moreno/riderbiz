import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_candidate_comparator.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

import '../../support/route_optimization/osrm_route_order_evaluator.dart';
import '../../support/route_optimization/route_optimization_benchmark.dart';
import '../../support/route_optimization/vroom_vehicle_scenario_factory.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  const factory = VroomVehicleScenarioFactory();
  const comparator = RouteCandidateComparator();
  const benchmark = RouteOptimizationBenchmark();

  for (final taskCount in [60, 80, 120]) {
    test(
      'compares initial and VROOM orders for $taskCount tasks',
      () async {
        final request = factory.create(taskCount: taskCount);
        final pending = request.plan.pendingTasks;
        final expectedStops = pending.map((task) => task.stopId).toSet();
        final expectedService = pending.fold<Duration>(
          Duration.zero,
          (total, task) => total + task.serviceDuration,
        );

        // Restrict this comparison to the evaluator's supported scope.
        expect(pending.any((task) => task.timeWindow != null), isFalse);
        expect(request.plan.stops.any((stop) => stop.isLocked), isFalse);
        expect(request.plan.walkingClusters, isEmpty);

        final vroom = await _CountingLocalProxy.start(3000);
        addTearDown(vroom.close);
        final osrm = await _CountingLocalProxy.start(5000);
        addTearDown(osrm.close);

        final adapter = VroomRouteOptimizationAdapter(endpoint: vroom.endpoint);
        final evaluator = OsrmRouteOrderEvaluator(endpoint: osrm.endpoint);

        final evidence = <String, Object?>{
          'schema_version': 1,
          'scenario': 'synthetic_grid_initial_order_comparison',
          'task_count': request.plan.tasks.length,
          'pending_task_count': pending.length,
          'pending_deliveries': pending
              .where((task) => task.type.name == 'delivery')
              .length,
          'pending_independent_pickups': pending
              .where((task) => task.type.name == 'pickup')
              .length,
          'pending_stops': expectedStops.length,
          'baseline': 'generated_order_not_an_experienced_driver_route',
          'evaluator': 'same_local_osrm_for_both_orders',
          'scope': 'vehicle_without_windows_locks_or_walking',
          'timing_includes_local_counting_proxy': true,
          'infrastructure_cost_eur_per_execution': null,
          'cost_reference': 'RB-ROUTING-006-cost-and-resources.md',
          'paid_provider_api_calls': 0,
        };
        var stage = 'optimization';

        try {
          final result = await benchmark.run(
            adapter: adapter,
            request: request,
            repetitions: 5,
          );

          expect(result.candidates, hasLength(5));
          expect(vroom.requests, 5);

          stage = 'baseline_evaluation';
          final initialMetrics = await evaluator.evaluate(
            request: request,
            stopOrder: request.plan.currentOrder,
          );
          expect(initialMetrics.serviceDuration, expectedService);
          expect(initialMetrics.distanceMeters, greaterThan(0));
          expect(initialMetrics.waitingDuration, Duration.zero);

          final runs = <Map<String, Object?>>[];
          for (var index = 0; index < result.candidates.length; index++) {
            stage = 'candidate_evaluation_${index + 1}';
            final candidate = result.candidates[index];

            expect(candidate.stopOrder, hasLength(expectedStops.length));
            expect(candidate.stopOrder.toSet(), expectedStops);
            expect(candidate.metrics.serviceDuration, expectedService);

            final candidateMetrics = await evaluator.evaluate(
              request: request,
              stopOrder: candidate.stopOrder,
            );
            expect(candidateMetrics.serviceDuration, expectedService);
            expect(candidateMetrics.waitingDuration, Duration.zero);
            expect(candidateMetrics.distanceMeters, greaterThan(0));

            final comparison = comparator.compare(
              currentMetrics: initialMetrics,
              candidateMetrics: candidateMetrics,
            );

            runs.add({
              'run': index + 1,
              'candidate': _metrics(candidateMetrics),
              'optimizer_reported_metrics': _metrics(candidate.metrics),
              'unassigned_pending_stops': expectedStops
                  .difference(candidate.stopOrder.toSet())
                  .length,
              'stop_coverage_verified': true,
              'constraint_violations': null,
              'constraint_scope':
                  'coverage_and_service_checked; '
                  'no_windows_locks_or_walking',
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
            });
          }

          expect(osrm.requests, 6);
          expect(
            (evidence['pending_deliveries'] as int) +
                (evidence['pending_independent_pickups'] as int),
            pending.length,
          );

          evidence.addAll({
            'status': 'success',
            'failure_reason': null,
            'provider': result.providerId,
            'repetitions': result.repetitions,
            'optimization_wall_time_ms': {
              'minimum': result.minimumDuration.inMicroseconds / 1000,
              'median': result.medianDuration.inMicroseconds / 1000,
              'p95': result.percentile95Duration.inMicroseconds / 1000,
              'maximum': result.maximumDuration.inMicroseconds / 1000,
            },
            'p95_scope': 'nearest_rank_over_five_samples_not_a_service_sla',
            'order_repeatable': result.isOrderRepeatable,
            'initial': _metrics(initialMetrics),
            'runs': runs,
          });
        } catch (error) {
          evidence.addAll({
            'status': 'failed',
            'failure_stage': stage,
            'failure_reason': error is RouteOptimizationFailure
                ? error.type.name
                : 'unexpected_failure_or_test_assertion',
          });
          rethrow;
        } finally {
          evidence['http_requests'] = {
            'vroom_received_by_proxy': vroom.requests,
            'osrm_evaluation_received_by_proxy': osrm.requests,
            'total_received_by_proxies': vroom.requests + osrm.requests,
            'internal_vroom_to_osrm': null,
            'scope': 'test_client_requests; internal_engine_calls_not_measured',
          };

          // Synthetic aggregate evidence: no coordinates, raw responses or keys.
          // ignore: avoid_print
          print(jsonEncode(evidence));
        }
      },
      skip: enabled
          ? false
          : 'Requires RUN_LOCAL_VROOM=true and local services.',
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
}

Map<String, Object?> _metrics(RouteMetrics metrics) => {
  'distance_m': metrics.distanceMeters,
  'travel_seconds': metrics.travelDuration.inMicroseconds / 1000000,
  'service_seconds': metrics.serviceDuration.inMicroseconds / 1000000,
  'waiting_seconds': metrics.waitingDuration.inMicroseconds / 1000000,
  'departure_delay_seconds': metrics.departureDelay.inMicroseconds / 1000000,
  'total_seconds': metrics.totalDuration.inMicroseconds / 1000000,
  'calculation_ms': metrics.calculationDuration.inMicroseconds / 1000,
};

// Test-only loopback proxy. Counts incoming requests without logging payloads.
class _CountingLocalProxy {
  _CountingLocalProxy._(this._server, this._targetPort);

  final HttpServer _server;
  final int _targetPort;
  final HttpClient _client = HttpClient()..findProxy = (_) => 'DIRECT';
  int requests = 0;

  Uri get endpoint => Uri.http('127.0.0.1:${_server.port}', '/');

  static Future<_CountingLocalProxy> start(int targetPort) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = _CountingLocalProxy._(server, targetPort);
    server.listen((incoming) {
      unawaited(proxy._forward(incoming));
    });
    return proxy;
  }

  Future<void> _forward(HttpRequest incoming) async {
    requests++;
    try {
      final target = incoming.uri.replace(
        scheme: 'http',
        host: '127.0.0.1',
        port: _targetPort,
      );
      final outgoing = await _client.openUrl(incoming.method, target);
      outgoing.followRedirects = false;
      outgoing.headers.contentType = incoming.headers.contentType;
      await outgoing.addStream(incoming);
      final response = await outgoing.close();
      incoming.response.statusCode = response.statusCode;
      incoming.response.headers.contentType = response.headers.contentType;
      await incoming.response.addStream(response);
      await incoming.response.close();
    } catch (_) {
      try {
        incoming.response.statusCode = HttpStatus.internalServerError;
        incoming.response.headers.contentType = ContentType.json;
        incoming.response.write(
          '{"code":1,"error":"Local measurement proxy failed."}',
        );
        await incoming.response.close();
      } catch (_) {
        // The caller may already have closed its connection.
      }
    }
  }

  Future<void> close() async {
    _client.close(force: true);
    await _server.close(force: true);
  }
}
