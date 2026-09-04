import 'package:drift/drift.dart';

import '../../data/local/riderbiz_database.dart';

class DeliveryAccountingService {
  DeliveryAccountingService(this.database);

  final RiderBizDatabase database;

  Future<SyntheticPackage> confirmDelivery({
    required String packageId,
    required String eventId,
    required DateTime deliveredAt,
  }) {
    final normalizedPackageId = packageId.trim();
    final normalizedEventId = eventId.trim();
    final deliveryTime = deliveredAt.toUtc();

    if (normalizedPackageId.isEmpty) {
      throw ArgumentError.value(packageId, 'packageId');
    }
    if (normalizedEventId.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId');
    }

    return database.transaction<SyntheticPackage>(() async {
      final package = await (database.select(
        database.syntheticPackages,
      )..where((row) => row.id.equals(normalizedPackageId))).getSingleOrNull();

      if (package == null) {
        throw StateError('Synthetic package not found');
      }

      if (package.status == 'delivered') {
        throw StateError('Synthetic package is already delivered');
      }

      final operatorId = package.identifiedOperatorId;

      if (operatorId == null) {
        throw StateError('Logistics operator has not been identified');
      }

      final tariff =
          await (database.select(database.operatorTariffs)
                ..where(
                  (row) =>
                      row.operatorId.equals(operatorId) &
                      row.isActive.equals(true) &
                      row.validFrom.isSmallerOrEqualValue(deliveryTime) &
                      (row.validUntil.isNull() |
                          row.validUntil.isBiggerThanValue(deliveryTime)),
                )
                ..orderBy([(row) => OrderingTerm.desc(row.version)]))
              .getSingleOrNull();

      if (tariff == null) {
        throw StateError('No active tariff found for the delivery time');
      }

      await (database.update(
        database.syntheticPackages,
      )..where((row) => row.id.equals(normalizedPackageId))).write(
        SyntheticPackagesCompanion(
          status: const Value('delivered'),
          tariffId: Value(tariff.id),
          tariffVersionSnapshot: Value(tariff.version),
          unitPriceMinorSnapshot: Value(tariff.unitPriceMinor),
          currencySnapshot: Value(tariff.currency),
          deliveredAt: Value(deliveryTime),
          updatedAt: Value(deliveryTime),
          needsSync: const Value(true),
        ),
      );

      await database
          .into(database.deliveryEvents)
          .insert(
            DeliveryEventsCompanion.insert(
              id: normalizedEventId,
              packageId: normalizedPackageId,
              eventType: 'delivered',
              occurredAt: deliveryTime,
            ),
          );

      return (database.select(
        database.syntheticPackages,
      )..where((row) => row.id.equals(normalizedPackageId))).getSingle();
    });
  }
}
