import 'package:drift/drift.dart';

import '../../data/local/riderbiz_database.dart';

class OperatorTariffService {
  OperatorTariffService(this.database);

  final RiderBizDatabase database;

  Future<void> createInitialConfiguration({
    required String operatorId,
    required String operatorName,
    required String tariffId,
    required int unitPriceMinor,
    required String currency,
    required DateTime validFrom,
    DateTime? createdAt,
  }) async {
    final normalizedOperatorId = operatorId.trim();
    final normalizedName = operatorName.trim();
    final normalizedTariffId = tariffId.trim();
    final normalizedCurrency = currency.trim().toUpperCase();

    if (normalizedOperatorId.isEmpty) {
      throw ArgumentError.value(operatorId, 'operatorId');
    }
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(operatorName, 'operatorName');
    }
    if (normalizedTariffId.isEmpty) {
      throw ArgumentError.value(tariffId, 'tariffId');
    }
    if (unitPriceMinor <= 0) {
      throw ArgumentError.value(unitPriceMinor, 'unitPriceMinor');
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
      throw ArgumentError.value(currency, 'currency');
    }

    final timestamp = createdAt?.toUtc() ?? DateTime.now().toUtc();

    await database.transaction(() async {
      await database
          .into(database.logisticsOperators)
          .insert(
            LogisticsOperatorsCompanion.insert(
              id: normalizedOperatorId,
              name: normalizedName,
              createdAt: timestamp,
            ),
          );

      await database
          .into(database.operatorTariffs)
          .insert(
            OperatorTariffsCompanion.insert(
              id: normalizedTariffId,
              operatorId: normalizedOperatorId,
              version: 1,
              unitPriceMinor: unitPriceMinor,
              currency: normalizedCurrency,
              validFrom: validFrom.toUtc(),
              createdAt: timestamp,
            ),
          );
    });
  }

  Future<bool> hasActiveConfiguration({DateTime? at}) async {
    final moment = at?.toUtc() ?? DateTime.now().toUtc();
    final operators = database.logisticsOperators;
    final tariffs = database.operatorTariffs;

    final query =
        database.select(tariffs).join([
          innerJoin(operators, operators.id.equalsExp(tariffs.operatorId)),
        ])..where(
          operators.isActive.equals(true) &
              tariffs.isActive.equals(true) &
              tariffs.validFrom.isSmallerOrEqualValue(moment) &
              (tariffs.validUntil.isNull() |
                  tariffs.validUntil.isBiggerThanValue(moment)),
        );

    return (await query.get()).isNotEmpty;
  }

  Future<List<OperatorTariff>> activeTariffsForOperator({
    required String operatorId,
    DateTime? at,
  }) {
    final moment = at?.toUtc() ?? DateTime.now().toUtc();

    return (database.select(database.operatorTariffs)
          ..where(
            (tariff) =>
                tariff.operatorId.equals(operatorId) &
                tariff.isActive.equals(true) &
                tariff.validFrom.isSmallerOrEqualValue(moment) &
                (tariff.validUntil.isNull() |
                    tariff.validUntil.isBiggerThanValue(moment)),
          )
          ..orderBy([(tariff) => OrderingTerm.desc(tariff.version)]))
        .get();
  }
}
