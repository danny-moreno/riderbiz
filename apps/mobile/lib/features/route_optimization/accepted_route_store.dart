import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/local/riderbiz_database.dart';
import 'route_optimization_models.dart';

class AcceptedRouteSnapshot {
  AcceptedRouteSnapshot({
    required this.routeId,
    required List<String> stopOrder,
    required this.metrics,
    required this.acceptedAt,
  }) : stopOrder = List.unmodifiable(stopOrder);

  final String routeId;
  final List<String> stopOrder;
  final RouteMetrics metrics;
  final DateTime acceptedAt;
}

enum RouteSelectionMode { usual, optimized }

class SelectedRouteSnapshot {
  SelectedRouteSnapshot({
    required this.routeId,
    required List<String> stopOrder,
    required this.mode,
    required this.metrics,
    required this.acceptedAt,
  }) : stopOrder = List.unmodifiable(stopOrder);

  final String routeId;
  final List<String> stopOrder;
  final RouteSelectionMode mode;
  final RouteMetrics? metrics;
  final DateTime acceptedAt;
}

class AcceptedRouteStore {
  const AcceptedRouteStore(this.database);

  final RiderBizDatabase database;

  Future<void> saveUsualOrder({
    required String routeId,
    required List<String> stopOrder,
    required DateTime acceptedAt,
  }) async {
    if (routeId.trim().isEmpty) {
      throw ArgumentError.value(routeId, 'routeId');
    }
    if (stopOrder.isEmpty ||
        stopOrder.any((id) => id.trim().isEmpty) ||
        stopOrder.toSet().length != stopOrder.length) {
      throw ArgumentError('The usual stop order must be nonempty and unique.');
    }

    final payload = jsonEncode({
      'version': 2,
      'mode': 'usual',
      'stopOrder': stopOrder,
    });

    await database
        .into(database.acceptedRouteSnapshots)
        .insertOnConflictUpdate(
          AcceptedRouteSnapshotsCompanion(
            routeId: Value(routeId),
            snapshotJson: Value(payload),
            acceptedAt: Value(acceptedAt.toUtc()),
          ),
        );
  }

  Future<void> save({
    required String routeId,
    required RouteCandidate candidate,
    required DateTime acceptedAt,
  }) async {
    if (routeId.trim().isEmpty) {
      throw ArgumentError.value(routeId, 'routeId');
    }

    final order = candidate.stopOrder;
    if (order.isEmpty ||
        order.any((id) => id.trim().isEmpty) ||
        order.toSet().length != order.length) {
      throw ArgumentError(
        'The accepted stop order must be nonempty and unique.',
      );
    }

    final metrics = candidate.metrics;
    final durations = [
      metrics.travelDuration,
      metrics.serviceDuration,
      metrics.waitingDuration,
      metrics.departureDelay,
      metrics.calculationDuration,
    ];

    if (metrics.distanceMeters < 0 ||
        durations.any((duration) => duration.isNegative)) {
      throw ArgumentError('Accepted route metrics must be nonnegative.');
    }

    final payload = jsonEncode({
      'version': 1,
      'stopOrder': order,
      'distanceMeters': metrics.distanceMeters,
      'travelMicroseconds': metrics.travelDuration.inMicroseconds,
      'serviceMicroseconds': metrics.serviceDuration.inMicroseconds,
      'waitingMicroseconds': metrics.waitingDuration.inMicroseconds,
      'departureDelayMicroseconds': metrics.departureDelay.inMicroseconds,
      'calculationMicroseconds': metrics.calculationDuration.inMicroseconds,
    });

    await database
        .into(database.acceptedRouteSnapshots)
        .insertOnConflictUpdate(
          AcceptedRouteSnapshotsCompanion(
            routeId: Value(routeId),
            snapshotJson: Value(payload),
            acceptedAt: Value(acceptedAt.toUtc()),
          ),
        );
  }

  Future<SelectedRouteSnapshot?> loadSelection(String routeId) {
    return database.transaction(() async {
      final row = await (database.select(
        database.acceptedRouteSnapshots,
      )..where((table) => table.routeId.equals(routeId))).getSingleOrNull();
      if (row == null) return null;

      final decoded = jsonDecode(row.snapshotJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid route selection.');
      }

      if (decoded['version'] == 1) {
        // Read the legacy format through its existing validator.
        // Both reads share this transaction.
        final accepted = await load(routeId);
        if (accepted == null) {
          throw StateError('Route selection disappeared during loading.');
        }
        return SelectedRouteSnapshot(
          routeId: accepted.routeId,
          stopOrder: accepted.stopOrder,
          mode: RouteSelectionMode.optimized,
          metrics: accepted.metrics,
          acceptedAt: accepted.acceptedAt,
        );
      }

      if (decoded['version'] != 2 ||
          decoded['mode'] != 'usual' ||
          decoded.keys.any(
            (key) => !const {'version', 'mode', 'stopOrder'}.contains(key),
          )) {
        throw const FormatException('Unsupported route selection.');
      }

      final rawOrder = decoded['stopOrder'];
      if (rawOrder is! List ||
          rawOrder.isEmpty ||
          rawOrder.any((id) => id is! String || id.trim().isEmpty)) {
        throw const FormatException('Invalid usual stop order.');
      }

      final order = rawOrder.cast<String>();
      if (order.toSet().length != order.length) {
        throw const FormatException('Duplicate usual stop identifiers.');
      }

      return SelectedRouteSnapshot(
        routeId: row.routeId,
        stopOrder: order,
        mode: RouteSelectionMode.usual,
        metrics: null,
        acceptedAt: row.acceptedAt.toUtc(),
      );
    });
  }

  Future<AcceptedRouteSnapshot?> load(String routeId) async {
    final row = await (database.select(
      database.acceptedRouteSnapshots,
    )..where((table) => table.routeId.equals(routeId))).getSingleOrNull();

    if (row == null) return null;

    final decoded = jsonDecode(row.snapshotJson);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException('Unsupported accepted route snapshot.');
    }

    final rawOrder = decoded['stopOrder'];
    if (rawOrder is! List ||
        rawOrder.isEmpty ||
        rawOrder.any((id) => id is! String || id.trim().isEmpty)) {
      throw const FormatException('Invalid accepted stop order.');
    }

    final order = rawOrder.cast<String>();
    if (order.toSet().length != order.length) {
      throw const FormatException('Duplicate accepted stop identifiers.');
    }

    int nonnegativeInteger(String key) {
      final value = decoded[key];
      if (value is! int || value < 0) {
        throw FormatException('Invalid accepted metric: $key.');
      }
      return value;
    }

    Duration duration(String key) =>
        Duration(microseconds: nonnegativeInteger(key));

    return AcceptedRouteSnapshot(
      routeId: row.routeId,
      stopOrder: order,
      acceptedAt: row.acceptedAt.toUtc(),
      metrics: RouteMetrics(
        distanceMeters: nonnegativeInteger('distanceMeters'),
        travelDuration: duration('travelMicroseconds'),
        serviceDuration: duration('serviceMicroseconds'),
        waitingDuration: duration('waitingMicroseconds'),
        departureDelay: duration('departureDelayMicroseconds'),
        calculationDuration: duration('calculationMicroseconds'),
      ),
    );
  }

  Future<void> delete(String routeId) async {
    await (database.delete(
      database.acceptedRouteSnapshots,
    )..where((table) => table.routeId.equals(routeId))).go();
  }
}
