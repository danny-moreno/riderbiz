import 'route_optimization_models.dart';
import 'route_optimization_port.dart';
import 'vroom_request_mapper.dart';

class VroomResponseMapper {
  const VroomResponseMapper();

  RouteCandidate map({
    required Map<String, dynamic> response,
    required VroomMappedRequest mappedRequest,
    required Duration calculationDuration,
  }) {
    if (response['code'] != 0) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.providerError,
        message: 'VROOM did not return a successful result.',
      );
    }

    final unassigned = _list(response['unassigned'], 'unassigned');

    if (unassigned.isNotEmpty) {
      throw const RouteOptimizationFailure(
        type: RouteOptimizationFailureType.incompleteSolution,
        message: 'VROOM returned a solution with unassigned tasks.',
      );
    }

    final routes = _list(response['routes'], 'routes');

    if (routes.length != 1) {
      _reject('Exactly one vehicle route is required.');
    }

    final route = _object(routes.single, 'route');

    if (route['vehicle'] != 1) {
      _reject('The response references an unexpected vehicle.');
    }

    _checkViolations(route['violations']);

    final steps = _list(route['steps'], 'steps');

    if (steps.length < 2) {
      _reject('The route must contain start and end steps.');
    }

    final first = _object(steps.first, 'start step');
    final last = _object(steps.last, 'end step');

    if (first['type'] != 'start' || last['type'] != 'end') {
      _reject('The route has invalid boundary steps.');
    }

    if (_number(first['duration'], 'start duration') != 0 ||
        _number(first['distance'], 'start distance') != 0) {
      _reject('The route must start with zero cumulative travel metrics.');
    }

    final stopOrder = <String>[];
    final legs = <VehicleLeg>[];
    final seenJobIds = <int>{};
    var previousStopId = 'CURRENT_LOCATION';
    var previousDuration = 0.0;
    var previousDistance = 0.0;

    for (final value in steps.skip(1).take(steps.length - 2)) {
      final step = _object(value, 'job step');

      if (step['type'] != 'job') {
        _reject('The route contains an unsupported step type.');
      }

      _checkViolations(step['violations']);

      final jobId = step['id'];

      if (jobId is! int || !seenJobIds.add(jobId)) {
        _reject('Job identifiers must be integers and unique.');
      }

      final stopId = mappedRequest.stopIdsByJobId[jobId];

      if (stopId == null) {
        _reject('The response references an unknown job.');
      }

      final duration = _number(step['duration'], 'step duration');
      final distance = _number(step['distance'], 'step distance');

      if (duration < previousDuration || distance < previousDistance) {
        _reject('Cumulative travel metrics must not decrease.');
      }

      legs.add(
        VehicleLeg(
          fromStopId: previousStopId,
          toStopId: stopId,
          distanceMeters: distance.round() - previousDistance.round(),
          duration: _duration(duration - previousDuration),
        ),
      );

      stopOrder.add(stopId);
      previousStopId = stopId;
      previousDuration = duration;
      previousDistance = distance;
    }

    if (seenJobIds.length != mappedRequest.stopIdsByJobId.length) {
      _reject('The response does not contain every requested job.');
    }

    final travel = _number(route['duration'], 'route duration');
    final distance = _number(route['distance'], 'route distance');
    final endTravel = _number(last['duration'], 'end duration');
    final endDistance = _number(last['distance'], 'end distance');

    if (endTravel != travel || endDistance != distance) {
      _reject('Route totals do not match the end step.');
    }

    if (travel < previousDuration || distance < previousDistance) {
      _reject('End metrics must not precede the final job metrics.');
    }

    if (mappedRequest.hasExplicitEnd) {
      legs.add(
        VehicleLeg(
          fromStopId: previousStopId,
          toStopId: 'END_LOCATION',
          distanceMeters: distance.round() - previousDistance.round(),
          duration: _duration(travel - previousDuration),
        ),
      );
    } else if (travel != previousDuration || distance != previousDistance) {
      _reject('Open-route totals do not match the final job.');
    }

    _checkViolations(last['violations']);

    final service = _number(route['service'], 'service duration');

    final requestedJobs = _list(
      mappedRequest.payload['jobs'],
      'requested jobs',
    );

    final expectedService = requestedJobs.fold<double>(0, (total, value) {
      final job = _object(value, 'requested job');
      return total + _number(job['service'], 'requested service');
    });

    if (service != expectedService) {
      _reject('Route service does not match the requested jobs.');
    }

    final waiting = _number(route['waiting_time'], 'waiting duration');
    final setup = _number(route['setup'], 'setup duration');
    final departureDelay = _number(first['arrival'], 'departure delay');
    final endArrival = _number(last['arrival'], 'end arrival');

    final expectedEnd = departureDelay + travel + service + waiting + setup;

    if ((endArrival - expectedEnd).abs() > 0.001) {
      _reject('The route schedule does not match its duration totals.');
    }

    if (setup != 0) {
      _reject('Unexpected setup time is not supported.');
    }

    return RouteCandidate(
      stopOrder: List.unmodifiable(stopOrder),
      vehicleLegs: List.unmodifiable(legs),
      metrics: RouteMetrics(
        distanceMeters: distance.round(),
        travelDuration: _duration(travel),
        serviceDuration: _duration(service),
        waitingDuration: _duration(waiting),
        departureDelay: _duration(departureDelay),
        calculationDuration: calculationDuration,
      ),
      explanation: const OptimizationExplanation(
        summary: 'Vehicle route calculated by local VROOM and OSRM.',
        warnings: [
          'Travel times are estimates without live traffic.',
          'Walking routes and vehicle capacity are not evaluated.',
        ],
      ),
    );
  }

  Map<String, dynamic> _object(Object? value, String field) {
    if (value is! Map<String, dynamic>) {
      _reject('Invalid object: $field.');
    }

    return value;
  }

  List<dynamic> _list(Object? value, String field) {
    if (value is! List) {
      _reject('Invalid list: $field.');
    }

    return value;
  }

  double _number(Object? value, String field) {
    if (value is! num || !value.isFinite || value < 0) {
      _reject('Invalid nonnegative number: $field.');
    }

    return value.toDouble();
  }

  void _checkViolations(Object? value) {
    if (_list(value, 'violations').isNotEmpty) {
      _reject('The route contains constraint violations.');
    }
  }

  Duration _duration(double seconds) {
    return Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round(),
    );
  }

  Never _reject(String message) {
    throw RouteOptimizationFailure(
      type: RouteOptimizationFailureType.invalidResponse,
      message: message,
    );
  }
}
