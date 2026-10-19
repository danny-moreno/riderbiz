import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_request_validator.dart';

class OsrmRouteOrderEvaluator {
  OsrmRouteOrderEvaluator({required this.endpoint}) {
    if (endpoint.scheme != 'http' ||
        !const ['127.0.0.1', 'localhost', '::1'].contains(endpoint.host) ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        (endpoint.path.isNotEmpty && endpoint.path != '/')) {
      throw ArgumentError('A local HTTP root endpoint is required.');
    }
  }

  final Uri endpoint;

  Future<RouteMetrics> evaluate({
    required RouteOptimizationRequest request,
    required List<String> stopOrder,
  }) async {
    const RouteOptimizationRequestValidator().validate(request);

    final pendingTasks = request.plan.pendingTasks;
    final pendingStopIds = pendingTasks.map((task) => task.stopId).toSet();

    if (stopOrder.length != pendingStopIds.length ||
        stopOrder.toSet().length != stopOrder.length ||
        !stopOrder.toSet().containsAll(pendingStopIds)) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidRequest,
        message: 'The order must contain every pending stop exactly once.',
      );
    }

    final stopsById = {for (final stop in request.plan.stops) stop.id: stop};

    if (pendingTasks.any((task) => task.timeWindow != null) ||
        stopOrder.any((id) => stopsById[id]!.walkingClusterId != null)) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidRequest,
        message: 'This evaluator does not support time windows or walking.',
      );
    }

    if (stopOrder.length > 249) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidRequest,
        message: 'The evaluator supports at most 249 pending stops.',
      );
    }

    final serviceDuration = pendingTasks.fold<Duration>(
      Duration.zero,
      (total, task) => total + task.serviceDuration,
    );

    if (stopOrder.isEmpty) {
      return RouteMetrics(
        distanceMeters: 0,
        travelDuration: Duration.zero,
        serviceDuration: serviceDuration,
        calculationDuration: Duration.zero,
      );
    }

    final coordinates = [
      request.currentLocation,
      for (final id in stopOrder) stopsById[id]!.coordinate,
    ];

    final coordinatePath = coordinates
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');

    final uri = endpoint.replace(
      path: '/route/v1/driving/$coordinatePath',
      queryParameters: {
        'overview': 'false',
        'steps': 'false',
        'alternatives': 'false',
        'continue_straight': 'false',
      },
    );

    final client = HttpClient()
      ..connectionTimeout = request.timeout
      ..findProxy = (_) => 'DIRECT';
    final stopwatch = Stopwatch()..start();

    try {
      final route = await _fetch(
        client,
        uri,
        expectedLegCount: stopOrder.length,
      ).timeout(request.timeout);

      stopwatch.stop();

      return RouteMetrics(
        distanceMeters: _number(route['distance']).round(),
        travelDuration: Duration(
          microseconds:
              (_number(route['duration']) * Duration.microsecondsPerSecond)
                  .round(),
        ),
        serviceDuration: serviceDuration,
        calculationDuration: stopwatch.elapsed,
      );
    } on TimeoutException {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.timeout,
        message: 'OSRM route evaluation timed out.',
      );
    } on FormatException {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidResponse,
        message: 'OSRM returned invalid JSON or text encoding.',
      );
    } on IOException {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.unavailable,
        message: 'The local OSRM service could not be reached.',
      );
    } finally {
      stopwatch.stop();
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _fetch(
    HttpClient client,
    Uri uri, {
    required int expectedLegCount,
  }) async {
    final outgoing = await client.getUrl(uri);
    outgoing.followRedirects = false;
    final incoming = await outgoing.close();

    if (incoming.statusCode != HttpStatus.ok) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.providerError,
        message: 'OSRM returned an unsuccessful HTTP status.',
      );
    }

    final bytes = <int>[];

    await for (final chunk in incoming) {
      if (bytes.length + chunk.length > 4 * 1024 * 1024) {
        _reject('The OSRM response exceeded the permitted size.');
      }
      bytes.addAll(chunk);
    }

    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map<String, dynamic>) {
      _reject('OSRM must return a JSON object.');
    }

    if (decoded['code'] != 'Ok') {
      _reject('OSRM did not return a usable route.');
    }

    final routes = decoded['routes'];

    if (routes is! List || routes.length != 1) {
      _reject('OSRM must return exactly one route.');
    }

    final route = routes.single;

    if (route is! Map<String, dynamic>) {
      _reject('OSRM returned a malformed route.');
    }

    final legs = route['legs'];

    if (legs is! List || legs.length != expectedLegCount) {
      _reject('OSRM returned an unexpected number of route legs.');
    }

    _number(route['distance']);
    _number(route['duration']);

    return route;
  }

  double _number(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      _reject('OSRM returned an invalid route metric.');
    }

    return value.toDouble();
  }

  Never _reject(String message) {
    throw RouteOptimizationFailure(
      type: RouteOptimizationFailureType.invalidResponse,
      message: message,
    );
  }
}
