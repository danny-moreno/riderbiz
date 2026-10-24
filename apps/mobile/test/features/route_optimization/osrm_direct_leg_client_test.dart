import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/osrm_direct_leg_client.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';

void main() {
  late HttpServer server;
  late OsrmDirectLegClient client;

  const from = RouteCoordinate(latitude: 42.8125, longitude: -1.6458);
  const to = RouteCoordinate(latitude: 42.8100, longitude: -1.6400);

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = OsrmDirectLegClient(
      endpoint: Uri.parse('http://127.0.0.1:${server.port}/'),
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  Future<VehicleLeg> calculate({
    Duration timeout = const Duration(seconds: 2),
    RouteOptimizationCancellationSignal? signal,
  }) {
    return client.calculate(
      fromStopId: 'STOP-A',
      toStopId: 'STOP-B',
      from: from,
      to: to,
      timeout: timeout,
      cancellationSignal: signal,
    );
  }

  Map<String, Object?> response({
    Object distance = 997.8,
    Object duration = 146.3,
    int legCount = 1,
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

  void serve(Object body, {int status = HttpStatus.ok}) {
    server.listen((incoming) async {
      await incoming.drain<void>();
      incoming.response.statusCode = status;
      incoming.response.headers.contentType = ContentType.json;
      incoming.response.write(body is String ? body : jsonEncode(body));
      await incoming.response.close();
    });
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

  group('OsrmDirectLegClient', () {
    test('requests two coordinates and converts the direct leg', () async {
      final received = Completer<Uri>();

      server.listen((incoming) async {
        await incoming.drain<void>();
        received.complete(incoming.uri);
        incoming.response.write(jsonEncode(response()));
        await incoming.response.close();
      });

      final leg = await calculate();
      final uri = await received.future;

      expect(uri.path, '/route/v1/driving/-1.6458,42.8125;-1.64,42.81');
      expect(uri.queryParameters['overview'], 'false');
      expect(uri.queryParameters['continue_straight'], 'false');
      expect(leg.fromStopId, 'STOP-A');
      expect(leg.toStopId, 'STOP-B');
      expect(leg.distanceMeters, 998);
      expect(leg.duration, const Duration(milliseconds: 146300));
    });

    test('accepts a zero-distance direct leg', () async {
      serve(response(distance: 0, duration: 0));

      final leg = await calculate();

      expect(leg.distanceMeters, 0);
      expect(leg.duration, Duration.zero);
    });

    test('rejects negative route metrics', () async {
      serve(response(distance: -1));

      await expectLater(
        calculate(),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('rejects an unexpected number of legs', () async {
      serve(response(legCount: 2));

      await expectLater(
        calculate(),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('rejects invalid JSON', () async {
      serve('invalid JSON');

      await expectLater(
        calculate(),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('rejects an unsuccessful OSRM result', () async {
      serve({'code': 'NoRoute', 'routes': []});

      await expectLater(
        calculate(),
        failure(RouteOptimizationFailureType.invalidResponse),
      );
    });

    test('reports unsuccessful HTTP status', () async {
      serve({}, status: HttpStatus.serviceUnavailable);

      await expectLater(
        calculate(),
        failure(RouteOptimizationFailureType.providerError),
      );
    });

    test('times out when the server does not respond', () async {
      server.listen((incoming) {
        incoming.drain<void>();
      });

      await expectLater(
        calculate(timeout: const Duration(milliseconds: 100)),
        failure(RouteOptimizationFailureType.timeout),
      );
    });

    test('cancels after the server receives the request', () async {
      final received = Completer<void>();
      final signal = RouteOptimizationCancellationSignal();

      server.listen((incoming) async {
        await incoming.drain<void>();
        received.complete();
      });

      final expectation = expectLater(
        calculate(signal: signal),
        failure(RouteOptimizationFailureType.cancelled),
      );

      await received.future.timeout(const Duration(seconds: 2));
      signal.cancel();
      await expectation;
    });

    test('rejects cancellation requested before execution', () async {
      final signal = RouteOptimizationCancellationSignal()..cancel();

      await expectLater(
        calculate(signal: signal),
        failure(RouteOptimizationFailureType.cancelled),
      );
    });

    test('rejects a nonpositive timeout', () async {
      await expectLater(
        calculate(timeout: Duration.zero),
        failure(RouteOptimizationFailureType.invalidRequest),
      );
    });

    test('rejects an empty stop identifier', () async {
      await expectLater(
        client.calculate(
          fromStopId: ' ',
          toStopId: 'STOP-B',
          from: from,
          to: to,
          timeout: const Duration(seconds: 2),
        ),
        failure(RouteOptimizationFailureType.invalidRequest),
      );
    });

    test('rejects a remote endpoint', () {
      expect(
        () => OsrmDirectLegClient(endpoint: Uri.parse('https://example.com/')),
        throwsArgumentError,
      );
    });
  });
}
