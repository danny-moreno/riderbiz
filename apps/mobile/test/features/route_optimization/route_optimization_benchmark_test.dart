import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/fake_route_optimization_adapter.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';

import '../../support/route_optimization/route_optimization_benchmark.dart';
import '../../support/route_optimization/synthetic_route_scenario_factory.dart';

void main() {
  const benchmark = RouteOptimizationBenchmark();
  const factory = SyntheticRouteScenarioFactory();
  const adapter = FakeRouteOptimizationAdapter();

  group('RouteOptimizationBenchmark', () {
    for (final taskCount in [60, 80, 120]) {
      test('benchmarks $taskCount tasks over five repetitions', () async {
        final scenario = factory.create(taskCount: taskCount);

        final result = await benchmark.run(
          adapter: adapter,
          request: scenario.request,
          repetitions: 5,
        );

        expect(result.providerId, 'fake-deterministic');
        expect(result.taskCount, taskCount);
        expect(result.pendingTaskCount, taskCount);
        expect(result.repetitions, 5);
        expect(result.candidates, hasLength(5));
        expect(result.isOrderRepeatable, isTrue);

        expect(result.minimumDuration.inMicroseconds, greaterThanOrEqualTo(0));
        expect(
          result.medianDuration.inMicroseconds,
          greaterThanOrEqualTo(result.minimumDuration.inMicroseconds),
        );
        expect(
          result.percentile95Duration.inMicroseconds,
          greaterThanOrEqualTo(result.medianDuration.inMicroseconds),
        );
        expect(
          result.maximumDuration.inMicroseconds,
          greaterThanOrEqualTo(result.percentile95Duration.inMicroseconds),
        );

        for (final candidate in result.candidates) {
          expect(candidate.stopOrder, hasLength(taskCount));
          expect(candidate.metrics.distanceMeters, taskCount * 1000);
        }
      });
    }

    test('supports a single repetition', () async {
      final scenario = factory.create(taskCount: 60);

      final result = await benchmark.run(
        adapter: adapter,
        request: scenario.request,
        repetitions: 1,
      );

      expect(result.candidates, hasLength(1));
      expect(result.isOrderRepeatable, isTrue);
      expect(result.minimumDuration, result.maximumDuration);
      expect(result.medianDuration, result.minimumDuration);
      expect(result.percentile95Duration, result.minimumDuration);
    });

    test('supports an even number of repetitions', () async {
      final scenario = factory.create(taskCount: 60);

      final result = await benchmark.run(
        adapter: adapter,
        request: scenario.request,
        repetitions: 4,
      );

      expect(result.candidates, hasLength(4));
      expect(
        result.medianDuration.inMicroseconds,
        inInclusiveRange(
          result.minimumDuration.inMicroseconds,
          result.maximumDuration.inMicroseconds,
        ),
      );
    });

    test('distinguishes total tasks from pending tasks', () async {
      final scenario = factory.create(
        taskCount: 80,
        completedTaskCount: 20,
        reoptimizePendingOnly: true,
      );

      final result = await benchmark.run(
        adapter: adapter,
        request: scenario.request,
        repetitions: 2,
      );

      expect(result.taskCount, 80);
      expect(result.pendingTaskCount, 60);

      for (final candidate in result.candidates) {
        expect(candidate.stopOrder, hasLength(60));
      }
    });

    test('rejects zero repetitions', () async {
      final scenario = factory.create(taskCount: 60);

      await expectLater(
        benchmark.run(
          adapter: adapter,
          request: scenario.request,
          repetitions: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative repetitions', () async {
      final scenario = factory.create(taskCount: 60);

      await expectLater(
        benchmark.run(
          adapter: adapter,
          request: scenario.request,
          repetitions: -1,
        ),
        throwsArgumentError,
      );
    });

    test('propagates provider failures instead of reporting success', () async {
      final scenario = factory.create(taskCount: 60);
      const unavailableAdapter = FakeRouteOptimizationAdapter(
        simulatedFailure: RouteOptimizationFailureType.unavailable,
      );

      await expectLater(
        benchmark.run(adapter: unavailableAdapter, request: scenario.request),
        throwsA(
          isA<RouteOptimizationFailure>().having(
            (failure) => failure.type,
            'type',
            RouteOptimizationFailureType.unavailable,
          ),
        ),
      );
    });

    test('protects the result list from modification', () async {
      final scenario = factory.create(taskCount: 60);

      final result = await benchmark.run(
        adapter: adapter,
        request: scenario.request,
        repetitions: 1,
      );

      expect(() => result.candidates.clear(), throwsUnsupportedError);
    });
  });
}
