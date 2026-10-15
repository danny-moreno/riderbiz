import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';

class RouteBenchmarkResult {
  RouteBenchmarkResult({
    required this.providerId,
    required this.taskCount,
    required this.pendingTaskCount,
    required this.repetitions,
    required this.minimumDuration,
    required this.medianDuration,
    required this.percentile95Duration,
    required this.maximumDuration,
    required this.isOrderRepeatable,
    required List<RouteCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final String providerId;
  final int taskCount;
  final int pendingTaskCount;
  final int repetitions;
  final Duration minimumDuration;
  final Duration medianDuration;
  final Duration percentile95Duration;
  final Duration maximumDuration;
  final bool isOrderRepeatable;
  final List<RouteCandidate> candidates;
}

class RouteOptimizationBenchmark {
  const RouteOptimizationBenchmark();

  Future<RouteBenchmarkResult> run({
    required RouteOptimizationPort adapter,
    required RouteOptimizationRequest request,
    int repetitions = 5,
  }) async {
    if (repetitions <= 0) {
      throw ArgumentError.value(
        repetitions,
        'repetitions',
        'Repetitions must be greater than zero.',
      );
    }

    final elapsedMicroseconds = <int>[];
    final candidates = <RouteCandidate>[];

    for (var index = 0; index < repetitions; index++) {
      final stopwatch = Stopwatch()..start();

      try {
        final candidate = await adapter.optimize(request);
        candidates.add(candidate);
      } finally {
        stopwatch.stop();
      }

      elapsedMicroseconds.add(stopwatch.elapsedMicroseconds);
    }

    final sortedDurations = List<int>.of(elapsedMicroseconds)..sort();
    final referenceOrder = candidates.first.stopOrder;

    final isOrderRepeatable = candidates.every(
      (candidate) => _sameOrder(referenceOrder, candidate.stopOrder),
    );

    return RouteBenchmarkResult(
      providerId: adapter.providerId,
      taskCount: request.plan.tasks.length,
      pendingTaskCount: request.plan.pendingTasks.length,
      repetitions: repetitions,
      minimumDuration: Duration(microseconds: sortedDurations.first),
      medianDuration: Duration(microseconds: _median(sortedDurations)),
      percentile95Duration: Duration(
        microseconds: _percentile95(sortedDurations),
      ),
      maximumDuration: Duration(microseconds: sortedDurations.last),
      isOrderRepeatable: isOrderRepeatable,
      candidates: candidates,
    );
  }

  int _median(List<int> sortedValues) {
    final middle = sortedValues.length ~/ 2;

    if (sortedValues.length.isOdd) {
      return sortedValues[middle];
    }

    return (sortedValues[middle - 1] + sortedValues[middle]) ~/ 2;
  }

  int _percentile95(List<int> sortedValues) {
    final rank = (sortedValues.length * 95 + 99) ~/ 100;
    return sortedValues[rank - 1];
  }

  bool _sameOrder(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
