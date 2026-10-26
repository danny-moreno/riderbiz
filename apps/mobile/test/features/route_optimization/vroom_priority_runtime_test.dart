import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_response_mapper.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  const origin = RouteCoordinate(latitude: 42.8125, longitude: -1.6458);
  final departure = DateTime.utc(2026, 10, 26, 8);

  RouteOptimizationRequest request({
    required int urgentIndex,
    required int windowEnd,
    bool urgentUnreachable = false,
  }) {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-PRIORITY',
        currentOrder: ['STOP-1', 'STOP-2'],
        stops: [
          for (var index = 0; index < 2; index++)
            OperationalStop(
              id: 'STOP-${index + 1}',
              coordinate: urgentUnreachable && index == urgentIndex
                  ? const RouteCoordinate(latitude: 42.8100, longitude: -1.6400)
                  : origin,
              taskIds: ['TASK-${index + 1}'],
            ),
        ],
        tasks: [
          for (var index = 0; index < 2; index++)
            RouteTask(
              id: 'TASK-${index + 1}',
              stopId: 'STOP-${index + 1}',
              type: index == 0 ? RouteTaskType.delivery : RouteTaskType.pickup,
              status: RouteTaskStatus.pending,
              priority: index == urgentIndex
                  ? RoutePriority.urgent
                  : RoutePriority.normal,
              serviceDuration: const Duration(seconds: 120),
              timeWindow: RouteTimeWindow(
                startsAt: departure,
                endsAt: departure.add(
                  Duration(
                    seconds: urgentUnreachable && index == urgentIndex
                        ? 1
                        : windowEnd,
                  ),
                ),
              ),
            ),
        ],
      ),
      currentLocation: origin,
      departureAt: departure,
      timeout: const Duration(seconds: 40),
    );
  }

  Future<Map<String, dynamic>> rawResponse(VroomMappedRequest mapped) async {
    final client = HttpClient()..findProxy = (_) => 'DIRECT';
    try {
      return await (() async {
        final outgoing = await client.postUrl(
          Uri.parse('http://127.0.0.1:3000/'),
        );
        outgoing.followRedirects = false;
        outgoing.headers.contentType = ContentType.json;
        outgoing.add(utf8.encode(jsonEncode(mapped.payload)));
        final incoming = await outgoing.close();
        expect(incoming.statusCode, HttpStatus.ok);
        final body = await utf8.decoder.bind(incoming).join();
        return jsonDecode(body) as Map<String, dynamic>;
      })().timeout(const Duration(seconds: 40));
    } finally {
      client.close(force: true);
    }
  }

  final cases = [
    (name: 'urgent first identifier', urgent: 0, end: 60, unreachable: false),
    (name: 'urgent second identifier', urgent: 1, end: 60, unreachable: false),
    (name: 'both fit their windows', urgent: 1, end: 300, unreachable: false),
    (name: 'urgent cannot meet window', urgent: 1, end: 300, unreachable: true),
  ];

  for (final scenario in cases) {
    test(
      'local priorities: ${scenario.name}',
      () async {
        final input = request(
          urgentIndex: scenario.urgent,
          windowEnd: scenario.end,
          urgentUnreachable: scenario.unreachable,
        );
        final mapped = const VroomRequestMapper().map(input);
        final jobs = (mapped.payload['jobs'] as List).cast<Map>();
        final urgentId = scenario.urgent + 1;
        final normalId = scenario.urgent == 0 ? 2 : 1;
        final bothFit = scenario.end == 300 && !scenario.unreachable;

        expect(jobs[scenario.urgent]['priority'], 100);
        expect(jobs[scenario.urgent == 0 ? 1 : 0]['priority'], 30);

        final stopwatch = Stopwatch()..start();
        final response = await rawResponse(mapped);
        stopwatch.stop();

        expect(response['code'], 0);
        final routes = (response['routes'] as List).cast<Map>();
        expect(routes, hasLength(1));
        final route = routes.single;
        expect(route['vehicle'], 1);
        expect(route['violations'], isEmpty);

        final steps = (route['steps'] as List).cast<Map>();
        final jobSteps = steps.where((step) => step['type'] == 'job').toList();
        final assigned = jobSteps.map((step) => step['id'] as int).toSet();
        final unassigned = (response['unassigned'] as List)
            .cast<Map>()
            .map((job) => job['id'] as int)
            .toSet();

        expect(jobSteps.length, assigned.length);
        expect((response['unassigned'] as List).length, unassigned.length);
        expect(assigned.intersection(unassigned), isEmpty);
        expect({...assigned, ...unassigned}, {1, 2});

        if (bothFit) {
          expect(assigned, {1, 2});
          expect(unassigned, isEmpty);
        } else if (scenario.unreachable) {
          expect(assigned, {normalId});
          expect(unassigned, {urgentId});
        } else {
          expect(assigned, {urgentId});
          expect(unassigned, {normalId});
        }

        for (final step in jobSteps) {
          final id = step['id'] as int;
          final job = jobs.singleWhere((job) => job['id'] == id);
          final window = (job['time_windows'] as List).single as List;
          final serviceStart =
              (step['arrival'] as num) + (step['waiting_time'] as num);
          expect(serviceStart, inInclusiveRange(window[0], window[1]));
          expect(step['service'], 120);
          expect(step['violations'], isEmpty);
        }
        expect(route['service'], assigned.length * 120);

        RouteCandidate convert() => const VroomResponseMapper().map(
          response: response,
          mappedRequest: mapped,
          calculationDuration: stopwatch.elapsed,
        );

        if (bothFit) {
          final candidate = convert();
          expect(candidate.stopOrder.toSet(), {'STOP-1', 'STOP-2'});
          expect(
            candidate.metrics.serviceDuration,
            const Duration(seconds: 240),
          );
        } else {
          expect(
            convert,
            throwsA(
              isA<RouteOptimizationFailure>().having(
                (failure) => failure.type,
                'type',
                RouteOptimizationFailureType.incompleteSolution,
              ),
            ),
          );
        }

        expect(
          input.plan.tasks.every(
            (task) => task.status == RouteTaskStatus.pending,
          ),
          isTrue,
        );
        expect(input.plan.currentOrder, ['STOP-1', 'STOP-2']);

        // Synthetic evidence; no coordinates or credentials in output.
        // ignore: avoid_print
        print(
          jsonEncode({
            'scenario': scenario.name,
            'tasks': 2,
            'deliveries': 1,
            'independent_pickups': 1,
            'urgent_job_id': urgentId,
            'assigned_ids': assigned.toList(),
            'unassigned_ids': unassigned.toList(),
            'elapsed_ms': stopwatch.elapsedMicroseconds / 1000,
            'distance_m': route['distance'],
            'travel_seconds': route['duration'],
            'service_seconds': route['service'],
            'waiting_seconds': route['waiting_time'],
            'route_end_seconds': steps.last['arrival'],
            'declared_violations': route['violations'],
            'http_requests': 1,
            'mapper_outcome': bothFit ? 'candidate' : 'incompleteSolution',
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
