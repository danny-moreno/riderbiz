import 'route_optimization_models.dart';

enum RouteComparisonOutcome { improved, equivalent, worsened }

class RouteComparison {
  const RouteComparison({
    required this.outcome,
    required this.distanceSavedMeters,
    required this.durationSaved,
    required this.distanceImprovementPercent,
    required this.durationImprovementPercent,
  });

  final RouteComparisonOutcome outcome;
  final int distanceSavedMeters;
  final Duration durationSaved;
  final double distanceImprovementPercent;
  final double durationImprovementPercent;

  bool get shouldRecommend => outcome == RouteComparisonOutcome.improved;
}

class RouteCandidateComparator {
  const RouteCandidateComparator();

  RouteComparison compare({
    required RouteMetrics currentMetrics,
    required RouteMetrics candidateMetrics,
  }) {
    final distanceSaved =
        currentMetrics.distanceMeters - candidateMetrics.distanceMeters;
    final durationSaved =
        currentMetrics.totalDuration - candidateMetrics.totalDuration;

    final outcome = _outcomeFor(
      distanceSaved: distanceSaved,
      durationSaved: durationSaved,
    );

    return RouteComparison(
      outcome: outcome,
      distanceSavedMeters: distanceSaved,
      durationSaved: durationSaved,
      distanceImprovementPercent: _percentage(
        original: currentMetrics.distanceMeters,
        difference: distanceSaved,
      ),
      durationImprovementPercent: _percentage(
        original: currentMetrics.totalDuration.inSeconds,
        difference: durationSaved.inSeconds,
      ),
    );
  }

  RouteComparisonOutcome _outcomeFor({
    required int distanceSaved,
    required Duration durationSaved,
  }) {
    if (durationSaved > Duration.zero) {
      return RouteComparisonOutcome.improved;
    }

    if (durationSaved < Duration.zero) {
      return RouteComparisonOutcome.worsened;
    }

    if (distanceSaved > 0) {
      return RouteComparisonOutcome.improved;
    }

    if (distanceSaved < 0) {
      return RouteComparisonOutcome.worsened;
    }

    return RouteComparisonOutcome.equivalent;
  }

  double _percentage({required int original, required int difference}) {
    if (original == 0) {
      return 0;
    }

    return (difference / original) * 100;
  }
}
