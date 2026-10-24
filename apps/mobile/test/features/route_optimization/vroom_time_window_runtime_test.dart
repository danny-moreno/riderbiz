import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_response_mapper.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');
  final endpoint = Uri.parse('http://127.0.0.1:3000/');
  final departure = DateTime.utc(2026, 10, 19, 8);

  RouteOptimizationRequest request({
    required int windowStartSeconds,
    required int windowEndSeconds,
  }) {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-TIME-WINDOW',
        currentOrder: ['STOP-A'],
        stops: [
          OperationalStop(
            id: 'STOP-A',
            coordinate: const RouteCoordinate(
              latitude: 42.8100,
              longitude: -1.6400,
            ),
            taskIds: ['TASK-A'],
          ),
        ],
        tasks: [
          RouteTask(
            id: 'TASK-A',
            stopId: 'STOP-A',
            type: RouteTaskType.delivery,
            status: RouteTaskStatus.pending,
            priority: RoutePriority.normal,
            serviceDuration: const Duration(seconds: 120),
            timeWindow: RouteTimeWindow(
              startsAt: departure.add(Duration(seconds: windowStartSeconds)),
              endsAt: departure.add(Duration(seconds: windowEndSeconds)),
            ),
          ),
        ],
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: departure,
      timeout: const Duration(seconds: 40),
    );
  }

  Future<Map<String, dynamic>> rawResponse(
    RouteOptimizationRequest input,
  ) async {
    final mapped = const VroomRequestMapper().map(input);
    final client = HttpClient()..findProxy = (_) => 'DIRECT';

    try {
      return await (() async {
        final outgoing = await client.postUrl(endpoint);
        outgoing.followRedirects = false;
        outgoing.headers.contentType = ContentType.json;
        outgoing.add(utf8.encode(jsonEncode(mapped.payload)));

        final incoming = await outgoing.close();
        expect(incoming.statusCode, HttpStatus.ok);

        final body = await utf8.decoder.bind(incoming).join();
        return jsonDecode(body) as Map<String, dynamic>;
      })().timeout(input.timeout);
    } finally {
      client.close(force: true);
    }
  }

  group(
    'Local VROOM time windows',
    () {
      test('respects the service window and exposes its schedule', () async {
        final input = request(windowStartSeconds: 3600, windowEndSeconds: 7200);

        final response = await rawResponse(input);

        expect(response['code'], 0);
        expect(response['unassigned'], isEmpty);

        final route =
            (response['routes'] as List).single as Map<String, dynamic>;
        final steps = (route['steps'] as List).cast<Map<String, dynamic>>();
        final job = steps.singleWhere((step) => step['type'] == 'job');

        expect(job['id'], 1);
        expect(route['violations'], isEmpty);
        expect(job['violations'], isEmpty);

        final arrival = (job['arrival'] as num).toDouble();
        final waiting = (job['waiting_time'] as num).toDouble();
        final serviceStart = arrival + waiting;

        expect(serviceStart, inInclusiveRange(3600, 7200));
        expect(waiting, greaterThanOrEqualTo(0));

        final candidate = const VroomResponseMapper().map(
          response: response,
          mappedRequest: const VroomRequestMapper().map(input),
          calculationDuration: Duration.zero,
        );

        expect(candidate.stopOrder, ['STOP-A']);
        expect(candidate.metrics.serviceDuration, const Duration(seconds: 120));
        expect(
          candidate.metrics.totalDuration,
          candidate.metrics.departureDelay +
              candidate.metrics.travelDuration +
              candidate.metrics.serviceDuration +
              candidate.metrics.waitingDuration,
        );

        expect(
          candidate.metrics.totalDuration.inMicroseconds / 1000000,
          closeTo((steps.last['arrival'] as num).toDouble(), 0.001),
        );
        // Synthetic schedule evidence, not application telemetry.
        // ignore: avoid_print
        print(
          jsonEncode({
            'scenario': 'feasible_single_stop_time_window',
            'window_start_seconds': 3600,
            'window_end_seconds': 7200,
            'route_start_seconds': steps.first['arrival'],
            'job_arrival_seconds': arrival,
            'job_waiting_seconds': waiting,
            'job_service_start_seconds': serviceStart,
            'route_waiting_seconds': route['waiting_time'],
            'route_travel_seconds': route['duration'],
            'route_end_seconds': steps.last['arrival'],
            'mapped_departure_delay_seconds':
                candidate.metrics.departureDelay.inSeconds,
            'mapped_total_seconds': candidate.metrics.totalDuration.inSeconds,
          }),
        );
      });

      test('respects time windows at three different stops', () async {
        final coordinates = [
          const RouteCoordinate(latitude: 42.8100, longitude: -1.6400),
          const RouteCoordinate(latitude: 42.8150, longitude: -1.6350),
          const RouteCoordinate(latitude: 42.8125, longitude: -1.6458),
        ];

        final windows = [
          [600, 1800],
          [2400, 3600],
          [4200, 5400],
        ];

        final tasks = <RouteTask>[];
        final stops = <OperationalStop>[];

        for (var index = 0; index < coordinates.length; index++) {
          final suffix = index + 1;
          final stopId = 'STOP-SYN-WINDOW-$suffix';
          final taskId = 'TASK-SYN-WINDOW-$suffix';

          stops.add(
            OperationalStop(
              id: stopId,
              coordinate: coordinates[index],
              taskIds: [taskId],
            ),
          );

          tasks.add(
            RouteTask(
              id: taskId,
              stopId: stopId,
              type: RouteTaskType.delivery,
              status: RouteTaskStatus.pending,
              priority: RoutePriority.normal,
              serviceDuration: const Duration(seconds: 120),
              timeWindow: RouteTimeWindow(
                startsAt: departure.add(Duration(seconds: windows[index][0])),
                endsAt: departure.add(Duration(seconds: windows[index][1])),
              ),
            ),
          );
        }

        final input = RouteOptimizationRequest(
          plan: RoutePlan(
            id: 'ROUTE-SYN-MULTIPLE-WINDOWS',
            currentOrder: stops.map((stop) => stop.id).toList(),
            stops: stops,
            tasks: tasks,
          ),
          currentLocation: const RouteCoordinate(
            latitude: 42.8125,
            longitude: -1.6458,
          ),
          departureAt: departure,
          timeout: const Duration(seconds: 40),
        );

        final mapped = const VroomRequestMapper().map(input);
        final response = await rawResponse(input);

        expect(response['code'], 0);
        expect(response['unassigned'], isEmpty);

        final route =
            (response['routes'] as List).single as Map<String, dynamic>;
        final routeSteps = (route['steps'] as List)
            .cast<Map<String, dynamic>>();
        final jobSteps = routeSteps
            .where((step) => step['type'] == 'job')
            .toList();

        expect(jobSteps, hasLength(3));
        expect(route['violations'], isEmpty);

        final seenIds = <int>{};
        final scheduleEvidence = <Map<String, Object?>>[];

        for (final step in jobSteps) {
          final jobId = step['id'] as int;
          expect(mapped.stopIdsByJobId.containsKey(jobId), isTrue);
          expect(seenIds.add(jobId), isTrue);

          final stopId = mapped.stopIdsByJobId[jobId]!;
          final task = tasks.singleWhere((task) => task.stopId == stopId);
          final window = task.timeWindow!;

          final startBound = window.startsAt.difference(departure).inSeconds;
          final endBound = window.endsAt.difference(departure).inSeconds;
          final arrival = (step['arrival'] as num).toDouble();
          final waiting = (step['waiting_time'] as num).toDouble();
          final serviceStart = arrival + waiting;

          expect(waiting, greaterThanOrEqualTo(0));
          expect(serviceStart, inInclusiveRange(startBound, endBound));
          expect(step['service'], 120);
          expect(step['violations'], isEmpty);

          scheduleEvidence.add({
            'stop_id': stopId,
            'window_start_seconds': startBound,
            'window_end_seconds': endBound,
            'arrival_seconds': arrival,
            'waiting_seconds': waiting,
            'service_start_seconds': serviceStart,
          });
        }

        expect(seenIds, mapped.stopIdsByJobId.keys.toSet());

        final candidate = const VroomResponseMapper().map(
          response: response,
          mappedRequest: mapped,
          calculationDuration: Duration.zero,
        );

        expect(candidate.stopOrder, hasLength(3));
        expect(
          candidate.stopOrder.toSet(),
          stops.map((stop) => stop.id).toSet(),
        );
        expect(candidate.metrics.serviceDuration, const Duration(seconds: 360));
        expect(
          candidate.metrics.totalDuration.inMicroseconds / 1000000,
          closeTo((routeSteps.last['arrival'] as num).toDouble(), 0.001),
        );

        // Synthetic schedule evidence, not application telemetry.
        // ignore: avoid_print
        print(
          jsonEncode({
            'scenario': 'three_stops_with_successive_time_windows',
            'schedule': scheduleEvidence,
            'departure_delay_seconds':
                candidate.metrics.departureDelay.inSeconds,
            'travel_seconds': candidate.metrics.travelDuration.inSeconds,
            'service_seconds': candidate.metrics.serviceDuration.inSeconds,
            'waiting_seconds': candidate.metrics.waitingDuration.inSeconds,
            'total_seconds': candidate.metrics.totalDuration.inSeconds,
          }),
        );
      });

      test('rejects a job that cannot be reached within its window', () async {
        final input = request(windowStartSeconds: 0, windowEndSeconds: 1);

        final response = await rawResponse(input);

        expect(response['code'], 0);
        final unassigned = response['unassigned'] as List;
        expect(unassigned, hasLength(1));
        expect((unassigned.single as Map)['id'], 1);

        expect(
          () => const VroomResponseMapper().map(
            response: response,
            mappedRequest: const VroomRequestMapper().map(input),
            calculationDuration: Duration.zero,
          ),
          throwsA(
            isA<RouteOptimizationFailure>().having(
              (failure) => failure.type,
              'type',
              RouteOptimizationFailureType.incompleteSolution,
            ),
          ),
        );
      });
    },
    skip: enabled ? false : 'Requires RUN_LOCAL_VROOM=true and local services.',
  );
}
