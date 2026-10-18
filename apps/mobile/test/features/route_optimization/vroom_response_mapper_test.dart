import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_port.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_request_mapper.dart';
import 'package:riderbiz_mobile/features/route_optimization/vroom_response_mapper.dart';

void main() {
  const mapper = VroomResponseMapper();

  final mappedRequest = VroomMappedRequest(
    payload: {},
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
                "duration": 0,
                "distance": 0,
                "violations": []
              },
              {
                "type": "job",
                "id": 1,
                "duration": 146,
                "distance": 998,
                "violations": []
              },
              {
                "type": "job",
                "id": 2,
                "duration": 351,
                "distance": 2501,
                "violations": []
              },
              {
                "type": "end",
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

    test('includes waiting time in total duration', () {
      final response = validResponse();
      route(response)['waiting_time'] = 60;

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

    test('rejects unassigned jobs', () {
      final response = validResponse();
      response['unassigned'] = [
        {'id': 2},
      ];

      expectInvalid(response);
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
