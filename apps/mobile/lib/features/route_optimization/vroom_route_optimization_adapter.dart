import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'route_optimization_models.dart';
import 'route_optimization_port.dart';
import 'vroom_request_mapper.dart';
import 'vroom_response_mapper.dart';

class VroomRouteOptimizationAdapter implements RouteOptimizationPort {
  VroomRouteOptimizationAdapter({
    required this.endpoint,
    this.maximumResponseBytes = 4 * 1024 * 1024,
  }) {
    if (endpoint.scheme != 'http' ||
        !const ['127.0.0.1', 'localhost', '::1'].contains(endpoint.host) ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment) {
      throw ArgumentError(
        'This validation adapter requires a local HTTP endpoint.',
      );
    }

    if (maximumResponseBytes <= 0) {
      throw ArgumentError.value(maximumResponseBytes, 'maximumResponseBytes');
    }
  }

  final Uri endpoint;
  final int maximumResponseBytes;

  @override
  String get providerId => 'vroom-osrm-local';

  @override
  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  }) async {
    cancellationSignal?.throwIfCancelled();

    final mapped = const VroomRequestMapper().map(request);

    if (mapped.stopIdsByJobId.isEmpty) {
      return RouteCandidate(
        stopOrder: const [],
        vehicleLegs: const [],
        metrics: RouteMetrics(
          distanceMeters: 0,
          travelDuration: Duration.zero,
          serviceDuration: Duration.zero,
          calculationDuration: Duration.zero,
        ),
        explanation: const OptimizationExplanation(
          summary: 'There are no pending tasks to optimize.',
        ),
      );
    }

    final stopwatch = Stopwatch()..start();
    final client = HttpClient()
      ..connectionTimeout = request.timeout
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
      final response = await _send(client, mapped).timeout(request.timeout);

      cancellationSignal?.throwIfCancelled();
      stopwatch.stop();

      return const VroomResponseMapper().map(
        response: response,
        mappedRequest: mapped,
        calculationDuration: stopwatch.elapsed,
      );
    } on RouteOptimizationFailure {
      rethrow;
    } on TimeoutException {
      cancellationSignal?.throwIfCancelled();

      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.timeout,
        message: 'The local VROOM request exceeded its timeout.',
      );
    } on FormatException {
      cancellationSignal?.throwIfCancelled();

      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidResponse,
        message: 'VROOM returned invalid JSON or text encoding.',
      );
    } on IOException {
      cancellationSignal?.throwIfCancelled();

      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.unavailable,
        message: 'The local VROOM service could not be reached.',
      );
    } finally {
      stopwatch.stop();
      cancellationTimer?.cancel();
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _send(
    HttpClient client,
    VroomMappedRequest mapped,
  ) async {
    final outgoing = await client.postUrl(endpoint);
    outgoing.followRedirects = false;
    outgoing.headers.contentType = ContentType.json;
    outgoing.headers.set(HttpHeaders.acceptHeader, 'application/json');
    outgoing.add(utf8.encode(jsonEncode(mapped.payload)));

    final incoming = await outgoing.close();

    if (incoming.statusCode != HttpStatus.ok) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.providerError,
        message: 'VROOM returned an unsuccessful HTTP status.',
      );
    }

    final bytes = <int>[];

    await for (final chunk in incoming) {
      if (bytes.length + chunk.length > maximumResponseBytes) {
        throw const RouteOptimizationFailure(
          type: RouteOptimizationFailureType.invalidResponse,
          message: 'The VROOM response exceeded the permitted size.',
        );
      }

      bytes.addAll(chunk);
    }

    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map<String, dynamic>) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.invalidResponse,
        message: 'The VROOM response must be a JSON object.',
      );
    }

    return decoded;
  }
}
