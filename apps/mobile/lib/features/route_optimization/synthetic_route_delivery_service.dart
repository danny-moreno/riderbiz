import 'package:drift/drift.dart';

import '../../data/local/riderbiz_database.dart';
import '../delivery_accounting/delivery_accounting_service.dart';
import '../operator_settings/operator_tariff_service.dart';
import 'accepted_route_store.dart' show AcceptedRouteStore;

class SyntheticRouteDeliveryService {
  const SyntheticRouteDeliveryService(this.database);

  final RiderBizDatabase database;

  static const routeId = 'ROUTE-TABLET-SYNTHETIC';
  static const _operatorId = 'OP-SYN-ROUTE-TABLET';
  static const _tariffId = 'TAR-SYN-ROUTE-TABLET-1';
  static const _runId = 'RUN-SYN-ROUTE-TABLET';

  static const packageIdsByStop = {
    'STOP-A': 'RB-SYN-ROUTE-A',
    'STOP-B': 'RB-SYN-ROUTE-B',
  };

  Future<void> prepare() {
    return database.transaction(() async {
      final createdAt = DateTime.utc(2026, 1, 1);

      final operator = await (database.select(
        database.logisticsOperators,
      )..where((row) => row.id.equals(_operatorId))).getSingleOrNull();

      if (operator == null) {
        await OperatorTariffService(database).createInitialConfiguration(
          operatorId: _operatorId,
          operatorName: 'Operador sintético de prueba de ruta',
          tariffId: _tariffId,
          unitPriceMinor: 1,
          currency: 'EUR',
          validFrom: createdAt,
          createdAt: createdAt,
        );
      }

      final run = await (database.select(
        database.deliveryRuns,
      )..where((row) => row.id.equals(_runId))).getSingleOrNull();

      if (run == null) {
        await database
            .into(database.deliveryRuns)
            .insert(
              DeliveryRunsCompanion.insert(
                id: _runId,
                operatorId: _operatorId,
                startedAt: createdAt,
              ),
            );
      }

      for (final packageId in packageIdsByStop.values) {
        final existing = await (database.select(
          database.syntheticPackages,
        )..where((row) => row.id.equals(packageId))).getSingleOrNull();

        if (existing != null) continue;

        await database
            .into(database.syntheticPackages)
            .insert(
              SyntheticPackagesCompanion.insert(
                id: packageId,
                deliveryRunId: _runId,
                identifiedOperatorId: const Value(_operatorId),
                identificationStatus: const Value('identified'),
                identificationConfidence: const Value(1.0),
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            );
      }
    });
  }

  Future<Map<String, SyntheticPackage>> loadProgress() async {
    final packages = await (database.select(
      database.syntheticPackages,
    )..where((row) => row.id.isIn(packageIdsByStop.values))).get();

    final byId = {for (final package in packages) package.id: package};
    final result = <String, SyntheticPackage>{};

    for (final entry in packageIdsByStop.entries) {
      final package = byId[entry.value];

      if (package == null || package.deliveryRunId != _runId) {
        throw StateError('Synthetic route packages are not prepared.');
      }

      result[entry.key] = package;
    }

    return Map.unmodifiable(result);
  }

  Future<SyntheticPackage> confirmStop({
    required String stopId,
    required DateTime deliveredAt,
  }) {
    final packageId = packageIdsByStop[stopId];

    if (packageId == null) {
      throw ArgumentError.value(stopId, 'stopId');
    }

    return database.transaction(() async {
      final accepted = await AcceptedRouteStore(database).load(routeId);

      if (accepted == null || !accepted.stopOrder.contains(stopId)) {
        throw StateError('The stop is not part of the accepted route.');
      }

      final package = await (database.select(
        database.syntheticPackages,
      )..where((row) => row.id.equals(packageId))).getSingleOrNull();

      if (package == null ||
          package.deliveryRunId != _runId ||
          package.identifiedOperatorId != _operatorId) {
        throw StateError('Unexpected synthetic route package.');
      }

      return DeliveryAccountingService(database).confirmDelivery(
        packageId: packageId,
        eventId: 'EVENT-DELIVERED-$packageId',
        deliveredAt: deliveredAt,
      );
    });
  }
}
