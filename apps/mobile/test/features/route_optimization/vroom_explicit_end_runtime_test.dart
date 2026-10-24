import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_response_mapper.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LOCAL_VROOM');

  test(
    'includes an explicit final destination without adding a task',
    () async {
      const origin = RouteCoordinate(latitude: 42.8125, longitude: -1.6458);

      final coordinates = [
        const RouteCoordinate(latitude: 42.8100, longitude: -1.6400),
        const RouteCoordinate(latitude: 42.8150, longitude: -1.6350),
      ];

      final stops = <OperationalStop>[];
      final tasks = <RouteTask>[];

      for (var index = 0; index < coordinates.length; index++) {
        final stopId = 'STOP-SYN-END-${index + 1}';
        final taskId = 'TASK-SYN-END-${index + 1}';

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
          ),
        );
      }

      final request = RouteOptimizationRequest(
        plan: RoutePlan(
          id: 'ROUTE-SYN-EXPLICIT-END',
          currentOrder: stops.map((stop) => stop.id).toList(),
          stops: stops,
          tasks: tasks,
        ),
        currentLocation: origin,
        departureAt: DateTime.utc(2026, 10, 23, 8),
        timeout: const Duration(seconds: 40),
      );

      final mapped = const VroomRequestMapper().map(
        request,
        endLocation: origin,
      );

      final client = HttpClient()..findProxy = (_) => 'DIRECT';
      final stopwatch = Stopwatch()..start();
      late Map<String, dynamic> response;

      try {
        response = await (() async {
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
        })().timeout(request.timeout);
      } finally {
        stopwatch.stop();
        client.close(force: true);
      }

      expect(response['code'], 0);
      expect(response['unassigned'], isEmpty);

      final route = (response['routes'] as List).single as Map<String, dynamic>;
      final steps = (route['steps'] as List).cast<Map<String, dynamic>>();

      expect((steps.last['location'] as List).cast<num>(), [
        origin.longitude,
        origin.latitude,
      ]);

      final candidate = const VroomResponseMapper().map(
        response: response,
        mappedRequest: mapped,
        calculationDuration: stopwatch.elapsed,
      );

      expect(mapped.hasExplicitEnd, isTrue);
      expect(candidate.stopOrder, hasLength(2));
      expect(candidate.stopOrder.toSet(), stops.map((stop) => stop.id).toSet());
      expect(candidate.stopOrder, isNot(contains('END_LOCATION')));
      expect(candidate.vehicleLegs, hasLength(3));

      final finalLeg = candidate.vehicleLegs.last;
      expect(finalLeg.fromStopId, candidate.stopOrder.last);
      expect(finalLeg.toStopId, 'END_LOCATION');
      expect(finalLeg.distanceMeters, greaterThan(0));
      expect(finalLeg.duration, greaterThan(Duration.zero));

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
      expect(candidate.metrics.serviceDuration, const Duration(seconds: 240));
      expect(
        candidate.metrics.totalDuration.inMicroseconds / 1000000,
        closeTo((steps.last['arrival'] as num).toDouble(), 0.001),
      );

      // Synthetic runtime evidence, not application telemetry.
      // ignore: avoid_print
      print(
        jsonEncode({
          'scenario': 'two_jobs_with_explicit_return_to_origin',
          'task_count': tasks.length,
          'proposed_stops': candidate.stopOrder.length,
          'vehicle_legs': candidate.vehicleLegs.length,
          'final_leg_distance_m': finalLeg.distanceMeters,
          'final_leg_duration_seconds': finalLeg.duration.inSeconds,
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
