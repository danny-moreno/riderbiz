import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_route_optimization_adapter.dart';

void main() {
  late HttpServer server;
  late Uri endpoint;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    endpoint = Uri.parse('http://127.0.0.1:${server.port}/');
  });

  tearDown(() async {
    await server.close(force: true);
  });

  RouteOptimizationRequest request({
    Duration timeout = const Duration(seconds: 2),
    bool completed = false,
  }) {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-HTTP',
        currentOrder: ['STOP-A'],
        stops: [
          OperationalStop(
            id: 'STOP-A',
            coordinate: const RouteCoordinate(
              latitude: 42.81,
              longitude: -1.64,
            ),
            taskIds: ['TASK-A'],
          ),
        ],
        tasks: [
          RouteTask(
            id: 'TASK-A',
            stopId: 'STOP-A',
            type: RouteTaskType.delivery,
            status: completed
                ? RouteTaskStatus.completed
                : RouteTaskStatus.pending,
            priority: RoutePriority.normal,
            serviceDuration: const Duration(seconds: 120),
          ),
        ],
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.utc(2026, 10, 15, 8),
      timeout: timeout,
    );
  }

  Matcher failure(RouteOptimizationFailureType type) {
    return throwsA(
      isA<RouteOptimizationFailure>().having(
        (error) => error.type,
        'type',
        type,
      ),
    );
  }

  String successfulResponse() {
    return jsonEncode({
      'code': 0,
      'unassigned': [],
      'routes': [
        {
          'vehicle': 1,
          'setup': 0,
          'service': 120,
          'duration': 146,
          'waiting_time': 0,
          'distance': 998,
          'violations': [],
          'steps': [
            {
              'type': 'start',
              'arrival': 0,
              'duration': 0,
              'distance': 0,
              'violations': [],
            },
            {
              'type': 'job',
              'arrival': 146,
              'id': 1,
              'duration': 146,
              'distance': 998,
              'violations': [],
            },
            {
              'type': 'end',
              'arrival': 266,
              'duration': 146,
              'distance': 998,
              'violations': [],
            },
          ],
        },
      ],
    });
  }

  group('VroomRouteOptimizationAdapter', () {
    test('posts a mapped request and converts the response', () async {
      final received = Completer<Map<String, dynamic>>();

      server.listen((incoming) async {
        final body = await utf8.decoder.bind(incoming).join();
        received.complete({
          'method': incoming.method,
          'body': jsonDecode(body),
        });

        incoming.response.headers.contentType = ContentType.json;
        incoming.response.write(successfulResponse());
        await incoming.response.close();
      });

      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);
      final result = await adapter.optimize(request());
      final captured = await received.future;
      final payload = captured['body'] as Map<String, dynamic>;

      expect(captured['method'], 'POST');
      expect(payload['jobs'], hasLength(1));
      expect(result.stopOrder, ['STOP-A']);
      expect(result.metrics.distanceMeters, 998);
      expect(result.metrics.totalDuration, const Duration(seconds: 266));
    });

    test('sends an explicit destination and includes its final leg', () async {
      final received = Completer<Map<String, dynamic>>();

      server.listen((incoming) async {
        final body = await utf8.decoder.bind(incoming).join();
        received.complete(jsonDecode(body) as Map<String, dynamic>);

        final response =
            jsonDecode(successfulResponse()) as Map<String, dynamic>;
        final route =
            (response['routes'] as List).single as Map<String, dynamic>;
        final steps = route['steps'] as List;

        route['duration'] = 246;
        route['distance'] = 1498;
        steps.last['duration'] = 246;
        steps.last['distance'] = 1498;
        steps.last['arrival'] = 366;

        incoming.response.headers.contentType = ContentType.json;
        incoming.response.write(jsonEncode(response));
        await incoming.response.close();
      });

      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);
      final result = await adapter.optimize(
        request(),
        endLocation: const RouteCoordinate(latitude: 42.82, longitude: -1.63),
      );

      final payload = await received.future;
      final vehicle = (payload['vehicles'] as List).single as Map;

      expect(vehicle['end'], [-1.63, 42.82]);
      expect(result.stopOrder, ['STOP-A']);
      expect(result.vehicleLegs, hasLength(2));
      expect(result.vehicleLegs.last.fromStopId, 'STOP-A');
      expect(result.vehicleLegs.last.toStopId, 'END_LOCATION');
      expect(result.vehicleLegs.last.distanceMeters, 500);
      expect(result.vehicleLegs.last.duration, const Duration(seconds: 100));
      expect(result.metrics.distanceMeters, 1498);
      expect(result.metrics.totalDuration, const Duration(seconds: 366));
    });

    test(
      'rejects an explicit destination when no pending tasks remain',
      () async {
        final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);

        await expectLater(
          adapter.optimize(
            request(completed: true),
            endLocation: const RouteCoordinate(
              latitude: 42.82,
              longitude: -1.63,
            ),
          ),
          failure(RouteOptimizationFailureType.invalidRequest),
        );
      },
    );

    test('maps unsuccessful HTTP status to a provider error', () async {
      server.listen((incoming) async {
        await incoming.drain<void>();
        incoming.response.statusCode = HttpStatus.serviceUnavailable;
        await incoming.response.close();
      });

      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);

      await expectLater(
        adapter.optimize(request()),
        failure(RouteOptimizationFailureType.providerError),
      );
    });

    test('rejects invalid JSON', () async {
      server.listen((incoming) async {
        await incoming.drain<void>();
        incoming.response.write('not JSON');
        await incoming.response.close();
      });

      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);

      await expectLater(
        adapter.optimize(request()),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('rejects an oversized response', () async {
      server.listen((incoming) async {
        await incoming.drain<void>();
        incoming.response.write(successfulResponse());
        await incoming.response.close();
      });

      final adapter = VroomRouteOptimizationAdapter(
        endpoint: endpoint,
        maximumResponseBytes: 10,
      );

      await expectLater(
        adapter.optimize(request()),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('times out when the server does not respond', () async {
      server.listen((incoming) {
        incoming.drain<void>();
      });

      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);

      await expectLater(
        adapter.optimize(request(timeout: const Duration(milliseconds: 100))),
        failure(RouteOptimizationFailureType.timeout),
      );
    });

    test('cancels after the server receives the request', () async {
      final received = Completer<void>();

      server.listen((incoming) async {
        await incoming.drain<void>();
        received.complete();
      });

      final signal = RouteOptimizationCancellationSignal();
      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);

      final expectation = expectLater(
        adapter.optimize(request(), cancellationSignal: signal),
        failure(RouteOptimizationFailureType.cancelled),
      );

      await received.future.timeout(const Duration(seconds: 2));
      signal.cancel();
      await expectation;
    });

    test('rejects cancellation requested before execution', () async {
      final signal = RouteOptimizationCancellationSignal()..cancel();
      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);

      await expectLater(
        adapter.optimize(request(), cancellationSignal: signal),
        failure(RouteOptimizationFailureType.cancelled),
      );
    });

    test('returns an empty candidate without contacting the server', () async {
      var contacted = false;

      server.listen((incoming) {
        contacted = true;
        incoming.response.close();
      });

      final adapter = VroomRouteOptimizationAdapter(endpoint: endpoint);
      final result = await adapter.optimize(request(completed: true));

      expect(result.stopOrder, isEmpty);
      expect(result.metrics.totalDuration, Duration.zero);
      expect(contacted, isFalse);
    });

    test('rejects a remote endpoint', () {
      expect(
        () => VroomRouteOptimizationAdapter(
          endpoint: Uri.parse('https://example.com/'),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a nonpositive response size limit', () {
      expect(
        () => VroomRouteOptimizationAdapter(
          endpoint: endpoint,
          maximumResponseBytes: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
