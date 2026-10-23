import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'route_optimization_models.dart';
import 'route_optimization_port.dart';

class OsrmDirectLegClient {
  OsrmDirectLegClient({required this.endpoint}) {
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

  Future<VehicleLeg> calculate({
    required String fromStopId,
    required String toStopId,
    required RouteCoordinate from,
    required RouteCoordinate to,
    required Duration timeout,
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.throwIfCancelled();

    if (fromStopId.trim().isEmpty ||
        toStopId.trim().isEmpty ||
        timeout <= Duration.zero ||
        !_validCoordinate(from) ||
        !_validCoordinate(to)) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidRequest,
        message: 'Invalid direct-leg identifiers, coordinates or timeout.',
      );
    }

    final coordinates =
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}';

    final uri = endpoint.replace(
      path: '/route/v1/driving/$coordinates',
      queryParameters: {
        'overview': 'false',
        'steps': 'false',
        'alternatives': 'false',
        'continue_straight': 'false',
      },
    );

    final client = HttpClient()
      ..connectionTimeout = timeout
      ..findProxy = (_) => 'DIRECT';

    Timer? cancellationTimer;

    if (cancellationSignal != null) {
      cancellationTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
        if (cancellationSignal.isCancelled) {
          client.close(force: true);
        }
      });
    }

    try {
      final route = await _fetch(client, uri).timeout(timeout);
      cancellationSignal?.throwIfCancelled();

      return VehicleLeg(
        fromStopId: fromStopId,
        toStopId: toStopId,
        distanceMeters: _number(route['distance']).round(),
        duration: Duration(
          microseconds:
              (_number(route['duration']) * Duration.microsecondsPerSecond)
                  .round(),
        ),
      );
    } on TimeoutException {
      cancellationSignal?.throwIfCancelled();

      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.timeout,
        message: 'The direct OSRM leg exceeded its timeout.',
      );
    } on FormatException {
      cancellationSignal?.throwIfCancelled();

      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidResponse,
        message: 'OSRM returned invalid JSON or text encoding.',
      );
    } on IOException {
      cancellationSignal?.throwIfCancelled();

      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.unavailable,
        message: 'The local OSRM service could not be reached.',
      );
    } finally {
      cancellationTimer?.cancel();
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _fetch(HttpClient client, Uri uri) async {
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
      if (bytes.length + chunk.length > 1024 * 1024) {
        _reject('The OSRM response exceeded the permitted size.');
      }

      bytes.addAll(chunk);
    }

    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map<String, dynamic> || decoded['code'] != 'Ok') {
      _reject('OSRM did not return a usable route.');
    }

    final routes = decoded['routes'];

    if (routes is! List || routes.length != 1) {
      _reject('Exactly one direct route is required.');
    }

    final route = routes.single;

    if (route is! Map<String, dynamic>) {
      _reject('OSRM returned a malformed route.');
    }

    final legs = route['legs'];

    if (legs is! List || legs.length != 1) {
      _reject('Exactly one direct route leg is required.');
    }

    _number(route['distance']);
    _number(route['duration']);

    return route;
  }

  bool _validCoordinate(RouteCoordinate coordinate) {
    return coordinate.latitude.isFinite &&
        coordinate.longitude.isFinite &&
        coordinate.latitude >= -90 &&
        coordinate.latitude <= 90 &&
        coordinate.longitude >= -180 &&
        coordinate.longitude <= 180;
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
