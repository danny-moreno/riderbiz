import 'route_optimization_models.dart';

enum RouteOptimizationFailureType {
  unavailable,
  timeout,
  cancelled,
  invalidRequest,
  invalidResponse,
  incompleteSolution,
  providerError,
}

class RouteOptimizationFailure implements Exception {
  const RouteOptimizationFailure({
    required this.type,
    required this.message,
    this.cause,
  });

  final RouteOptimizationFailureType type;
  final String message;
  final Object? cause;

  @override
  String toString() => 'RouteOptimizationFailure($type): $message';
}

class RouteOptimizationCancellationSignal {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.cancelled,
        message: 'Route optimization was cancelled.',
      );
    }
  }
}

abstract interface class RouteOptimizationPort {
  String get providerId;

  Future<RouteCandidate> optimize(
    RouteOptimizationRequest request, {
    RouteOptimizationCancellationSignal? cancellationSignal,
  });
}
