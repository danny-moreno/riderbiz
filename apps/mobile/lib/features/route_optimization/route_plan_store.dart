import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../data/local/riderbiz_database.dart';
import 'route_optimization_models.dart';
import 'route_optimization_request_validator.dart';

class RoutePlanStore {
  const RoutePlanStore(this.database);

  final RiderBizDatabase database;

  Future<void> save({
    required String deliveryRunId,
    required RoutePlan plan,
    required DateTime updatedAt,
  }) async {
    _validate(plan);
    final payload = jsonEncode({
      'version': 1,
      'routeId': plan.id,
      'currentOrder': plan.currentOrder,
      'stops': [
        for (final stop in plan.stops)
          {
            'id': stop.id,
            'coordinate': _coordinateJson(stop.coordinate),
            'taskIds': stop.taskIds,
            'isLocked': stop.isLocked,
            'walkingClusterId': stop.walkingClusterId,
          },
      ],
      'tasks': [
        for (final task in plan.tasks)
          {
            'id': task.id,
            'stopId': task.stopId,
            'type': task.type.name,
            'priority': task.priority.name,
            'serviceMicroseconds': task.serviceDuration.inMicroseconds,
            'timeWindow': task.timeWindow == null
                ? null
                : {
                    'startsAt': task.timeWindow!.startsAt
                        .toUtc()
                        .toIso8601String(),
                    'endsAt': task.timeWindow!.endsAt.toUtc().toIso8601String(),
                  },
          },
      ],
      'walkingClusters': [
        for (final cluster in plan.walkingClusters)
          {
            'id': cluster.id,
            'stopIds': cluster.stopIds,
            'anchor': _coordinateJson(cluster.anchor),
          },
      ],
    });

    await database.transaction(() async {
      await _statuses(deliveryRunId, plan.tasks.map((task) => task.id));
      await database
          .into(database.routePlanDefinitions)
          .insertOnConflictUpdate(
            RoutePlanDefinitionsCompanion(
              routeId: Value(plan.id),
              deliveryRunId: Value(deliveryRunId),
              definitionJson: Value(payload),
              updatedAt: Value(updatedAt.toUtc()),
            ),
          );
    });
  }

  Future<RoutePlan?> load(String routeId) {
    return database.transaction(() async {
      final row = await (database.select(
        database.routePlanDefinitions,
      )..where((table) => table.routeId.equals(routeId))).getSingleOrNull();
      if (row == null) return null;

      final json = jsonDecode(row.definitionJson) as Map<String, dynamic>;
      if (json['version'] != 1 || json['routeId'] != routeId) {
        throw const FormatException('Unsupported or inconsistent route plan.');
      }
      final rawTasks = (json['tasks'] as List).cast<Map<String, dynamic>>();
      final statuses = await _statuses(
        row.deliveryRunId,
        rawTasks.map((task) => task['id'] as String),
      );

      final plan = RoutePlan(
        id: routeId,
        currentOrder: List<String>.unmodifiable(json['currentOrder'] as List),
        stops: List.unmodifiable([
          for (final stop
              in (json['stops'] as List).cast<Map<String, dynamic>>())
            OperationalStop(
              id: stop['id'] as String,
              coordinate: _coordinate(stop['coordinate']),
              taskIds: List<String>.unmodifiable(stop['taskIds'] as List),
              isLocked: stop['isLocked'] as bool,
              walkingClusterId: stop['walkingClusterId'] as String?,
            ),
        ]),
        tasks: List.unmodifiable([
          for (final task in rawTasks)
            RouteTask(
              id: task['id'] as String,
              stopId: task['stopId'] as String,
              type: RouteTaskType.values.byName(task['type'] as String),
              status: statuses[task['id']]!,
              priority: RoutePriority.values.byName(task['priority'] as String),
              serviceDuration: Duration(
                microseconds: task['serviceMicroseconds'] as int,
              ),
              timeWindow: _window(task['timeWindow']),
            ),
        ]),
        walkingClusters: List.unmodifiable([
          for (final cluster
              in (json['walkingClusters'] as List).cast<Map<String, dynamic>>())
            WalkingCluster(
              id: cluster['id'] as String,
              stopIds: List<String>.unmodifiable(cluster['stopIds'] as List),
              anchor: _coordinate(cluster['anchor']),
            ),
        ]),
      );
      _validate(plan);
      return plan;
    });
  }

  Future<Map<String, RouteTaskStatus>> _statuses(
    String runId,
    Iterable<String> taskIds,
  ) async {
    final run = await (database.select(
      database.deliveryRuns,
    )..where((row) => row.id.equals(runId))).getSingleOrNull();
    if (run == null) throw StateError('Delivery run not found.');

    final ids = taskIds.toSet();
    final packages = await (database.select(
      database.syntheticPackages,
    )..where((row) => row.deliveryRunId.equals(runId))).get();
    final byId = {for (final package in packages) package.id: package};
    return {
      for (final id in ids)
        id: switch (byId[id]?.status) {
          'pending' => RouteTaskStatus.pending,
          'delivered' => RouteTaskStatus.completed,
          _ => throw StateError('Missing package or unsupported status: $id'),
        },
    };
  }

  static void _validate(RoutePlan plan) {
    if (plan.tasks.isEmpty ||
        plan.tasks.any((task) => task.type != RouteTaskType.delivery)) {
      throw ArgumentError('This store requires nonempty package deliveries.');
    }
    const RouteOptimizationRequestValidator().validate(
      RouteOptimizationRequest(
        plan: plan,
        currentLocation: const RouteCoordinate(latitude: 0, longitude: 0),
        departureAt: DateTime.utc(2026),
        timeout: const Duration(seconds: 1),
      ),
    );
  }

  static Map<String, double> _coordinateJson(RouteCoordinate coordinate) => {
    'latitude': coordinate.latitude,
    'longitude': coordinate.longitude,
  };

  static RouteCoordinate _coordinate(dynamic value) {
    final json = value as Map<String, dynamic>;
    return RouteCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  static RouteTimeWindow? _window(dynamic value) {
    if (value == null) return null;
    final json = value as Map<String, dynamic>;
    return RouteTimeWindow(
      startsAt: DateTime.parse(json['startsAt'] as String).toUtc(),
      endsAt: DateTime.parse(json['endsAt'] as String).toUtc(),
    );
  }
}
