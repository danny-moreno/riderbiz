import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_response_mapper.dart';

void main() {
  const mapper = VroomResponseMapper();

  final mappedRequest = VroomMappedRequest(
    payload: {
      'jobs': [
        {'id': 1, 'service': 120},
        {'id': 2, 'service': 120},
      ],
    },
    stopIdsByJobId: {1: 'STOP-A', 2: 'STOP-B'},
  );

  Map<String, dynamic> validResponse() {
    return jsonDecode('''
      {
        "code": 0,
        "unassigned": [],
        "routes": [
          {
            "vehicle": 1,
            "setup": 0,
            "service": 240,
            "duration": 351,
            "waiting_time": 0,
            "distance": 2501,
            "violations": [],
            "steps": [
              {
                "type": "start",
                "arrival": 0,
                "duration": 0,
                "distance": 0,
                "violations": []
              },
              {
                "type": "job",
                "arrival": 146,
                "id": 1,
                "duration": 146,
                "distance": 998,
                "violations": []
              },
              {
                "type": "job",
                "arrival": 471,
                "id": 2,
                "duration": 351,
                "distance": 2501,
                "violations": []
              },
              {
                "type": "end",
                "arrival": 591,
                "duration": 351,
                "distance": 2501,
                "violations": []
              }
            ]
          }
        ]
      }
    ''') as Map<String, dynamic>;
  }

  Map<String, dynamic> route(Map<String, dynamic> response) {
    return (response['routes'] as List).single as Map<String, dynamic>;
  }

  List<dynamic> steps(Map<String, dynamic> response) {
    return route(response)['steps'] as List<dynamic>;
  }

  void expectInvalid(Map<String, dynamic> response) {
    expect(
      () => mapper.map(
        response: response,
        mappedRequest: mappedRequest,
        calculationDuration: const Duration(milliseconds: 20),
      ),
      throwsA(
        isA<RouteOptimizationFailure>().having(
          (failure) => failure.type,
          'type',
          RouteOptimizationFailureType.invalidResponse,
        ),
      ),
    );
  }

  group('VroomResponseMapper', () {
    test('maps the observed two-job route and its legs', () {
      final candidate = mapper.map(
        response: validResponse(),
        mappedRequest: mappedRequest,
        calculationDuration: const Duration(milliseconds: 20),
      );

      expect(candidate.stopOrder, ['STOP-A', 'STOP-B']);
      expect(candidate.vehicleLegs, hasLength(2));

      final first = candidate.vehicleLegs.first;
      expect(first.fromStopId, 'CURRENT_LOCATION');
      expect(first.toStopId, 'STOP-A');
      expect(first.distanceMeters, 998);
      expect(first.duration, const Duration(seconds: 146));

      final second = candidate.vehicleLegs.last;
      expect(second.fromStopId, 'STOP-A');
      expect(second.toStopId, 'STOP-B');
      expect(second.distanceMeters, 1503);
      expect(second.duration, const Duration(seconds: 205));

      expect(candidate.metrics.distanceMeters, 2501);
      expect(candidate.metrics.travelDuration, const Duration(seconds: 351));
      expect(candidate.metrics.serviceDuration, const Duration(seconds: 240));
      expect(candidate.metrics.waitingDuration, Duration.zero);
      expect(candidate.metrics.totalDuration, const Duration(seconds: 591));
      expect(
        candidate.metrics.calculationDuration,
        const Duration(milliseconds: 20),
      );
    });

    test('includes the final leg without adding an operational stop', () {
      final response = validResponse();
      route(response)['duration'] = 451;
      route(response)['distance'] = 3001;
      steps(response).last['duration'] = 451;
      steps(response).last['distance'] = 3001;
      steps(response).last['arrival'] = 691;

      final requestWithEnd = VroomMappedRequest(
        payload: mappedRequest.payload,
        stopIdsByJobId: {1: 'STOP-A', 2: 'STOP-B'},
        hasExplicitEnd: true,
      );

      final candidate = mapper.map(
        response: response,
        mappedRequest: requestWithEnd,
        calculationDuration: Duration.zero,
      );

      expect(candidate.stopOrder, ['STOP-A', 'STOP-B']);
      expect(candidate.vehicleLegs, hasLength(3));

      final lastLeg = candidate.vehicleLegs.last;
      expect(lastLeg.fromStopId, 'STOP-B');
      expect(lastLeg.toStopId, 'END_LOCATION');
      expect(lastLeg.distanceMeters, 500);
      expect(lastLeg.duration, const Duration(seconds: 100));

      expect(candidate.metrics.distanceMeters, 3001);
      expect(candidate.metrics.totalDuration, const Duration(seconds: 691));
      expect(
        candidate.vehicleLegs.fold<int>(
          0,
          (total, leg) => total + leg.distanceMeters,
        ),
        candidate.metrics.distanceMeters,
      );
    });

    test('allows an explicit end at the final job with a zero final leg', () {
      final candidate = mapper.map(
        response: validResponse(),
        mappedRequest: VroomMappedRequest(
          payload: mappedRequest.payload,
          stopIdsByJobId: {1: 'STOP-A', 2: 'STOP-B'},
          hasExplicitEnd: true,
        ),
        calculationDuration: Duration.zero,
      );

      expect(candidate.stopOrder, hasLength(2));
      expect(candidate.vehicleLegs, hasLength(3));
      expect(candidate.vehicleLegs.last.distanceMeters, 0);
      expect(candidate.vehicleLegs.last.duration, Duration.zero);
    });

    test('rejects additional final travel for an open route', () {
      final response = validResponse();
      route(response)['duration'] = 451;
      steps(response).last['duration'] = 451;
      steps(response).last['arrival'] = 691;

      expectInvalid(response);
    });

    test('rejects explicit end metrics that decrease after the final job', () {
      final response = validResponse();
      route(response)['distance'] = 2000;
      steps(response).last['distance'] = 2000;

      expect(
        () => mapper.map(
          response: response,
          mappedRequest: VroomMappedRequest(
            payload: mappedRequest.payload,
            stopIdsByJobId: {1: 'STOP-A', 2: 'STOP-B'},
            hasExplicitEnd: true,
          ),
          calculationDuration: Duration.zero,
        ),
        throwsA(
          isA<RouteOptimizationFailure>().having(
            (failure) => failure.type,
            'type',
            RouteOptimizationFailureType.invalidResponse,
          ),
        ),
      );
    });

    test('includes departure delay in total duration', () {
      final response = validResponse();

      for (final value in steps(response)) {
        final step = value as Map<String, dynamic>;
        step['arrival'] = (step['arrival'] as num) + 3454;
      }

      final candidate = mapper.map(
        response: response,
        mappedRequest: mappedRequest,
        calculationDuration: Duration.zero,
      );

      expect(candidate.metrics.departureDelay, const Duration(seconds: 3454));
      expect(candidate.metrics.travelDuration, const Duration(seconds: 351));
      expect(candidate.metrics.serviceDuration, const Duration(seconds: 240));
      expect(candidate.metrics.totalDuration, const Duration(seconds: 4045));
    });

    test('rejects an end arrival inconsistent with route totals', () {
      final response = validResponse();
      steps(response).last['arrival'] = 600;

      expectInvalid(response);
    });

    test('rejects a negative departure delay', () {
      final response = validResponse();
      steps(response).first['arrival'] = -1;

      expectInvalid(response);
    });

    test('rejects a missing departure arrival', () {
      final response = validResponse();
      (steps(response).first as Map<String, dynamic>).remove('arrival');

      expectInvalid(response);
    });
    test('rejects service totals that differ from the requested jobs', () {
      final response = validResponse();

      route(response)['service'] = 0;
      steps(response).last['arrival'] = 351;

      expectInvalid(response);
    });
    test('includes waiting time in total duration', () {
      final response = validResponse();
      route(response)['waiting_time'] = 60;
      steps(response).last['arrival'] = 651;

      final candidate = mapper.map(
        response: response,
        mappedRequest: mappedRequest,
        calculationDuration: Duration.zero,
      );

      expect(candidate.metrics.waitingDuration, const Duration(minutes: 1));
      expect(candidate.metrics.totalDuration, const Duration(seconds: 651));
    });

    test('reports a provider failure for a nonzero response code', () {
      expect(
        () => mapper.map(
          response: {'code': 3},
          mappedRequest: mappedRequest,
          calculationDuration: Duration.zero,
        ),
        throwsA(
          isA<RouteOptimizationFailure>().having(
            (failure) => failure.type,
            'type',
            RouteOptimizationFailureType.providerError,
          ),
        ),
      );
    });

    test('reports an incomplete solution when jobs remain unassigned', () {
      final response = validResponse();
      response['unassigned'] = [
        {'id': 2},
      ];

      expect(
        () => mapper.map(
          response: response,
          mappedRequest: mappedRequest,
          calculationDuration: Duration.zero,
        ),
        throwsA(
          isA<RouteOptimizationFailure>().having(
            (failure) => failure.type,
            'type',
            RouteOptimizationFailureType.incompleteSolution,
          ),
        ),
      );
    });

    test('rejects an unexpected vehicle', () {
      final response = validResponse();
      route(response)['vehicle'] = 2;

      expectInvalid(response);
    });

    test('rejects duplicate job identifiers', () {
      final response = validResponse();
      steps(response)[2]['id'] = 1;

      expectInvalid(response);
    });

    test('rejects unknown job identifiers', () {
      final response = validResponse();
      steps(response)[2]['id'] = 99;

      expectInvalid(response);
    });

    test('rejects a missing requested job', () {
      final response = validResponse();
      steps(response).removeAt(2);

      expectInvalid(response);
    });

    test('rejects missing distance metrics', () {
      final response = validResponse();
      route(response).remove('distance');

      expectInvalid(response);
    });

    test('rejects decreasing cumulative travel metrics', () {
      final response = validResponse();
      steps(response)[2]['duration'] = 100;

      expectInvalid(response);
    });

    test('rejects inconsistent route totals', () {
      final response = validResponse();
      route(response)['distance'] = 2600;

      expectInvalid(response);
    });

    test('rejects constraint violations', () {
      final response = validResponse();
      route(response)['violations'] = [
        {'cause': 'time_window'},
      ];

      expectInvalid(response);
    });

    test('rejects unsupported setup time', () {
      final response = validResponse();
      route(response)['setup'] = 30;

      expectInvalid(response);
    });

    test('rejects nonfinite metrics', () {
      final response = validResponse();
      route(response)['waiting_time'] = double.nan;

      expectInvalid(response);
    });

    test('rejects negative metrics', () {
      final response = validResponse();
      route(response)['service'] = -1;

      expectInvalid(response);
    });

    test('rejects malformed routes', () {
      final response = validResponse();
      response['routes'] = 'invalid';

      expectInvalid(response);
    });
  });
}
