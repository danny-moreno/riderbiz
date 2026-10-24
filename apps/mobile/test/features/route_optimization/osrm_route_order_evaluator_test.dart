import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';

import '../../support/route_optimization/osrm_route_order_evaluator.dart';

void main() {
  late HttpServer server;
  late OsrmRouteOrderEvaluator evaluator;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    evaluator = OsrmRouteOrderEvaluator(
      endpoint: Uri.parse('http://127.0.0.1:${server.port}/'),
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  RouteOptimizationRequest request({
    bool firstCompleted = false,
    bool withWindow = false,
    Duration timeout = const Duration(seconds: 2),
  }) {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-SYN-ORDER',
        currentOrder: ['STOP-A', 'STOP-B'],
        stops: [
          OperationalStop(
            id: 'STOP-A',
            coordinate: const RouteCoordinate(
              latitude: 42.81,
              longitude: -1.64,
            ),
            taskIds: ['TASK-A'],
          ),
          OperationalStop(
            id: 'STOP-B',
            coordinate: const RouteCoordinate(
              latitude: 42.815,
              longitude: -1.635,
            ),
            taskIds: ['TASK-B'],
          ),
        ],
        tasks: [
          RouteTask(
            id: 'TASK-A',
            stopId: 'STOP-A',
            type: RouteTaskType.delivery,
            status: firstCompleted
                ? RouteTaskStatus.completed
                : RouteTaskStatus.pending,
            priority: RoutePriority.normal,
            serviceDuration: const Duration(minutes: 2),
          ),
          RouteTask(
            id: 'TASK-B',
            stopId: 'STOP-B',
            type: RouteTaskType.pickup,
            status: RouteTaskStatus.pending,
            priority: RoutePriority.normal,
            serviceDuration: const Duration(minutes: 4),
            timeWindow: withWindow
                ? RouteTimeWindow(
                    startsAt: DateTime.utc(2026, 10, 18, 9),
                    endsAt: DateTime.utc(2026, 10, 18, 10),
                  )
                : null,
          ),
        ],
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.utc(2026, 10, 18, 8),
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

  void serve(Object body, {int status = HttpStatus.ok}) {
    server.listen((incoming) async {
      await incoming.drain<void>();
      incoming.response.statusCode = status;
      incoming.response.headers.contentType = ContentType.json;
      incoming.response.write(body is String ? body : jsonEncode(body));
      await incoming.response.close();
    });
  }

  Map<String, Object?> response({
    int legCount = 2,
    Object distance = 2501.4,
    Object duration = 351.5,
  }) {
    return {
      'code': 'Ok',
      'routes': [
        {
          'distance': distance,
          'duration': duration,
          'legs': List.generate(legCount, (_) => <String, Object?>{}),
        },
      ],
    };
  }

  group('OsrmRouteOrderEvaluator', () {
    test('sends the supplied stop order and sums pending service', () async {
      final received = Completer<Uri>();

      server.listen((incoming) async {
        await incoming.drain<void>();
        received.complete(incoming.uri);
        incoming.response.headers.contentType = ContentType.json;
        incoming.response.write(jsonEncode(response()));
        await incoming.response.close();
      });

      final metrics = await evaluator.evaluate(
        request: request(),
        stopOrder: ['STOP-B', 'STOP-A'],
      );

      final uri = await received.future;

      expect(
        uri.path,
        '/route/v1/driving/'
        '-1.6458,42.8125;-1.635,42.815;-1.64,42.81',
      );
      expect(uri.queryParameters['continue_straight'], 'false');
      expect(uri.queryParameters['overview'], 'false');
      expect(metrics.distanceMeters, 2501);
      expect(metrics.travelDuration, const Duration(milliseconds: 351500));
      expect(metrics.serviceDuration, const Duration(minutes: 6));
      expect(metrics.waitingDuration, Duration.zero);
      expect(metrics.totalDuration, const Duration(milliseconds: 711500));
    });

    test('excludes completed tasks and their service duration', () async {
      serve(response(legCount: 1));

      final metrics = await evaluator.evaluate(
        request: request(firstCompleted: true),
        stopOrder: ['STOP-B'],
      );

      expect(metrics.serviceDuration, const Duration(minutes: 4));
    });

    test('rejects a duplicated stop order', () async {
      await expectLater(
        evaluator.evaluate(request: request(), stopOrder: ['STOP-A', 'STOP-A']),
        failure(RouteOptimizationFailureType.invalidRequest),
      );
    });

    test('rejects an order missing a pending stop', () async {
      await expectLater(
        evaluator.evaluate(request: request(), stopOrder: ['STOP-A']),
        failure(RouteOptimizationFailureType.invalidRequest),
      );
    });

    test('rejects an unknown stop', () async {
      await expectLater(
        evaluator.evaluate(
          request: request(),
          stopOrder: ['STOP-A', 'UNKNOWN'],
        ),
        failure(RouteOptimizationFailureType.invalidRequest),
      );
    });

    test('rejects time windows instead of ignoring them', () async {
      await expectLater(
        evaluator.evaluate(
          request: request(withWindow: true),
          stopOrder: ['STOP-A', 'STOP-B'],
        ),
        failure(RouteOptimizationFailureType.invalidRequest),
      );
    });

    test('rejects an unexpected number of legs', () async {
      serve(response(legCount: 1));

      await expectLater(
        evaluator.evaluate(request: request(), stopOrder: ['STOP-A', 'STOP-B']),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('rejects negative metrics', () async {
      serve(response(distance: -1));

      await expectLater(
        evaluator.evaluate(request: request(), stopOrder: ['STOP-A', 'STOP-B']),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('rejects invalid JSON', () async {
      serve('invalid JSON');

      await expectLater(
        evaluator.evaluate(request: request(), stopOrder: ['STOP-A', 'STOP-B']),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('reports unsuccessful HTTP status', () async {
      serve({}, status: HttpStatus.serviceUnavailable);

      await expectLater(
        evaluator.evaluate(request: request(), stopOrder: ['STOP-A', 'STOP-B']),
        failure(RouteOptimizationFailureType.providerError),
      );
    });

    test('times out when the server does not respond', () async {
      server.listen((incoming) {
        incoming.drain<void>();
      });

      await expectLater(
        evaluator.evaluate(
          request: request(timeout: const Duration(milliseconds: 100)),
          stopOrder: ['STOP-A', 'STOP-B'],
        ),
        failure(RouteOptimizationFailureType.timeout),
      );
    });

    test('rejects a remote endpoint', () {
      expect(
        () => OsrmRouteOrderEvaluator(
          endpoint: Uri.parse('https://example.com/'),
        ),
        throwsArgumentError,
      );
    });
  });
}
