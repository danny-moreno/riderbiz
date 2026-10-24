import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_candidate_comparator.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

void main() {
  const comparator = RouteCandidateComparator();

  RouteMetrics metrics({
    required int distanceMeters,
    required int travelMinutes,
    int serviceMinutes = 20,
  }) {
    return RouteMetrics(
      distanceMeters: distanceMeters,
      travelDuration: Duration(minutes: travelMinutes),
      serviceDuration: Duration(minutes: serviceMinutes),
      calculationDuration: const Duration(milliseconds: 10),
    );
  }

  group('RouteCandidateComparator', () {
    test('reports distance and time savings', () {
      final comparison = comparator.compare(
        currentMetrics: metrics(distanceMeters: 10000, travelMinutes: 100),
        candidateMetrics: metrics(distanceMeters: 8000, travelMinutes: 80),
      );

      expect(comparison.outcome, RouteComparisonOutcome.improved);
      expect(comparison.shouldRecommend, isTrue);
      expect(comparison.distanceSavedMeters, 2000);
      expect(comparison.durationSaved, const Duration(minutes: 20));
      expect(comparison.distanceImprovementPercent, closeTo(20, 0.001));
      expect(comparison.durationImprovementPercent, closeTo(16.666, 0.01));
    });

    test('reports an equivalent candidate', () {
      final current = metrics(distanceMeters: 10000, travelMinutes: 100);

      final comparison = comparator.compare(
        currentMetrics: current,
        candidateMetrics: metrics(distanceMeters: 10000, travelMinutes: 100),
      );

      expect(comparison.outcome, RouteComparisonOutcome.equivalent);
      expect(comparison.shouldRecommend, isFalse);
      expect(comparison.distanceSavedMeters, 0);
      expect(comparison.durationSaved, Duration.zero);
      expect(comparison.distanceImprovementPercent, 0);
      expect(comparison.durationImprovementPercent, 0);
    });

    test('reports a worsened candidate', () {
      final comparison = comparator.compare(
        currentMetrics: metrics(distanceMeters: 8000, travelMinutes: 80),
        candidateMetrics: metrics(distanceMeters: 10000, travelMinutes: 100),
      );

      expect(comparison.outcome, RouteComparisonOutcome.worsened);
      expect(comparison.shouldRecommend, isFalse);
      expect(comparison.distanceSavedMeters, -2000);
      expect(comparison.durationSaved, const Duration(minutes: -20));
      expect(comparison.distanceImprovementPercent, closeTo(-25, 0.001));
      expect(comparison.durationImprovementPercent, closeTo(-20, 0.001));
    });

    test('uses lower distance when total duration is equal', () {
      final comparison = comparator.compare(
        currentMetrics: metrics(distanceMeters: 10000, travelMinutes: 100),
        candidateMetrics: metrics(distanceMeters: 9000, travelMinutes: 100),
      );

      expect(comparison.outcome, RouteComparisonOutcome.improved);
      expect(comparison.shouldRecommend, isTrue);
      expect(comparison.distanceSavedMeters, 1000);
      expect(comparison.durationSaved, Duration.zero);
    });

    test('gives time precedence over a longer distance', () {
      final comparison = comparator.compare(
        currentMetrics: metrics(distanceMeters: 10000, travelMinutes: 100),
        candidateMetrics: metrics(distanceMeters: 11000, travelMinutes: 90),
      );

      expect(comparison.outcome, RouteComparisonOutcome.improved);
      expect(comparison.shouldRecommend, isTrue);
      expect(comparison.distanceSavedMeters, -1000);
      expect(comparison.durationSaved, const Duration(minutes: 10));
    });

    test('avoids division by zero for an empty route', () {
      final comparison = comparator.compare(
        currentMetrics: metrics(
          distanceMeters: 0,
          travelMinutes: 0,
          serviceMinutes: 0,
        ),
        candidateMetrics: metrics(
          distanceMeters: 0,
          travelMinutes: 0,
          serviceMinutes: 0,
        ),
      );

      expect(comparison.outcome, RouteComparisonOutcome.equivalent);
      expect(comparison.distanceImprovementPercent, 0);
      expect(comparison.durationImprovementPercent, 0);
    });
  });
}
