import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_candidate_comparator.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

void main() {
  RouteMetrics metrics({
    required int travelMinutes,
    int serviceMinutes = 10,
    int waitingMinutes = 0,
  }) {
    return RouteMetrics(
      distanceMeters: 5000,
      travelDuration: Duration(minutes: travelMinutes),
      serviceDuration: Duration(minutes: serviceMinutes),
      waitingDuration: Duration(minutes: waitingMinutes),
      calculationDuration: const Duration(seconds: 2),
    );
  }

  group('RouteMetrics', () {
    test('defaults waiting duration to zero', () {
      final result = RouteMetrics(
        distanceMeters: 5000,
        travelDuration: const Duration(minutes: 20),
        serviceDuration: const Duration(minutes: 10),
        calculationDuration: const Duration(seconds: 2),
      );

      expect(result.waitingDuration, Duration.zero);
      expect(result.totalDuration, const Duration(minutes: 30));
    });

    test('includes waiting and excludes calculation from route duration', () {
      final result = metrics(
        travelMinutes: 20,
        serviceMinutes: 10,
        waitingMinutes: 15,
      );

      expect(result.totalDuration, const Duration(minutes: 45));
    });

    test(
      'does not recommend less driving when waiting increases total time',
      () {
        const comparator = RouteCandidateComparator();

        final comparison = comparator.compare(
          currentMetrics: metrics(travelMinutes: 30),
          candidateMetrics: metrics(travelMinutes: 20, waitingMinutes: 15),
        );

        expect(comparison.outcome, RouteComparisonOutcome.worsened);
        expect(comparison.shouldRecommend, isFalse);
        expect(comparison.durationSaved, const Duration(minutes: -5));
        expect(comparison.durationImprovementPercent, closeTo(-12.5, 0.001));
      },
    );

    test('recognizes savings when waiting is reduced', () {
      const comparator = RouteCandidateComparator();

      final comparison = comparator.compare(
        currentMetrics: metrics(travelMinutes: 20, waitingMinutes: 15),
        candidateMetrics: metrics(travelMinutes: 20, waitingMinutes: 5),
      );

      expect(comparison.outcome, RouteComparisonOutcome.improved);
      expect(comparison.shouldRecommend, isTrue);
      expect(comparison.durationSaved, const Duration(minutes: 10));
      expect(comparison.durationImprovementPercent, closeTo(22.2222, 0.001));
    });
  });
}
