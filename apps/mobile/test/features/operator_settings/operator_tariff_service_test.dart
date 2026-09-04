import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/operator_settings/operator_tariff_service.dart';

void main() {
  late RiderBizDatabase database;
  late OperatorTariffService service;

  final validationTime = DateTime.utc(2026, 9, 4, 10);
  final validFrom = DateTime.utc(2026, 9, 4, 8);

  setUp(() {
    database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    service = OperatorTariffService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createConfiguration() {
    return service.createInitialConfiguration(
      operatorId: 'OP-ALFA',
      operatorName: 'Operador Alfa',
      tariffId: 'TAR-ALFA-1',
      unitPriceMinor: 120,
      currency: 'eur',
      validFrom: validFrom,
      createdAt: validFrom,
    );
  }

  test('configuration is incomplete without an operator and tariff', () async {
    expect(await service.hasActiveConfiguration(at: validationTime), isFalse);
  });

  test('creates an active operator and normalized tariff atomically', () async {
    await createConfiguration();

    expect(await service.hasActiveConfiguration(at: validationTime), isTrue);

    final operator = await database
        .select(database.logisticsOperators)
        .getSingle();
    final tariff = await database.select(database.operatorTariffs).getSingle();

    expect(operator.id, 'OP-ALFA');
    expect(operator.name, 'Operador Alfa');
    expect(operator.isActive, isTrue);

    expect(tariff.operatorId, 'OP-ALFA');
    expect(tariff.version, 1);
    expect(tariff.unitPriceMinor, 120);
    expect(tariff.currency, 'EUR');
    expect(tariff.isActive, isTrue);
  });

  test('rejects zero or negative tariff prices', () async {
    await expectLater(
      service.createInitialConfiguration(
        operatorId: 'OP-ZERO',
        operatorName: 'Operador Cero',
        tariffId: 'TAR-ZERO-1',
        unitPriceMinor: 0,
        currency: 'EUR',
        validFrom: validFrom,
      ),
      throwsA(isA<ArgumentError>()),
    );

    await expectLater(
      service.createInitialConfiguration(
        operatorId: 'OP-NEGATIVE',
        operatorName: 'Operador Negativo',
        tariffId: 'TAR-NEGATIVE-1',
        unitPriceMinor: -1,
        currency: 'EUR',
        validFrom: validFrom,
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await database.select(database.logisticsOperators).get(), isEmpty);
    expect(await database.select(database.operatorTariffs).get(), isEmpty);
  });

  test('rejects a currency that is not a three-letter code', () async {
    await expectLater(
      service.createInitialConfiguration(
        operatorId: 'OP-ALFA',
        operatorName: 'Operador Alfa',
        tariffId: 'TAR-ALFA-1',
        unitPriceMinor: 120,
        currency: 'EURO',
        validFrom: validFrom,
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await database.select(database.logisticsOperators).get(), isEmpty);
  });

  test('inactive operator makes the configuration incomplete', () async {
    await createConfiguration();

    await (database.update(database.logisticsOperators)
          ..where((operator) => operator.id.equals('OP-ALFA')))
        .write(const LogisticsOperatorsCompanion(isActive: Value(false)));

    expect(await service.hasActiveConfiguration(at: validationTime), isFalse);
  });

  test('inactive tariff makes the configuration incomplete', () async {
    await createConfiguration();

    await (database.update(database.operatorTariffs)
          ..where((tariff) => tariff.id.equals('TAR-ALFA-1')))
        .write(const OperatorTariffsCompanion(isActive: Value(false)));

    expect(await service.hasActiveConfiguration(at: validationTime), isFalse);
  });

  test('future tariff is not considered active yet', () async {
    await service.createInitialConfiguration(
      operatorId: 'OP-FUTURE',
      operatorName: 'Operador Futuro',
      tariffId: 'TAR-FUTURE-1',
      unitPriceMinor: 150,
      currency: 'EUR',
      validFrom: DateTime.utc(2026, 9, 5),
      createdAt: validFrom,
    );

    expect(await service.hasActiveConfiguration(at: validationTime), isFalse);
  });
  test(
    'creates a new tariff version without deleting the previous one',
    () async {
      await createConfiguration();

      final secondValidFrom = DateTime.utc(2026, 10, 1);

      final secondTariff = await service.createTariffVersion(
        operatorId: 'OP-ALFA',
        tariffId: 'TAR-ALFA-2',
        unitPriceMinor: 135,
        currency: 'eur',
        validFrom: secondValidFrom,
        createdAt: DateTime.utc(2026, 9, 20),
      );

      final tariffs = await (database.select(
        database.operatorTariffs,
      )..orderBy([(tariff) => OrderingTerm.asc(tariff.version)])).get();

      expect(tariffs, hasLength(2));

      expect(tariffs.first.id, 'TAR-ALFA-1');
      expect(tariffs.first.version, 1);
      expect(tariffs.first.unitPriceMinor, 120);
      expect(tariffs.first.validUntil?.toUtc(), secondValidFrom);

      expect(secondTariff.id, 'TAR-ALFA-2');
      expect(secondTariff.version, 2);
      expect(secondTariff.unitPriceMinor, 135);
      expect(secondTariff.currency, 'EUR');
      expect(secondTariff.validFrom.toUtc(), secondValidFrom);
      expect(secondTariff.validUntil, equals(null));
    },
  );

  test('selects the tariff that is valid at the requested time', () async {
    await createConfiguration();

    await service.createTariffVersion(
      operatorId: 'OP-ALFA',
      tariffId: 'TAR-ALFA-2',
      unitPriceMinor: 135,
      currency: 'EUR',
      validFrom: DateTime.utc(2026, 10, 1),
    );

    final septemberTariffs = await service.activeTariffsForOperator(
      operatorId: 'OP-ALFA',
      at: DateTime.utc(2026, 9, 15),
    );

    final octoberTariffs = await service.activeTariffsForOperator(
      operatorId: 'OP-ALFA',
      at: DateTime.utc(2026, 10, 15),
    );

    expect(septemberTariffs, hasLength(1));
    expect(septemberTariffs.single.id, 'TAR-ALFA-1');
    expect(septemberTariffs.single.unitPriceMinor, 120);

    expect(octoberTariffs, hasLength(1));
    expect(octoberTariffs.single.id, 'TAR-ALFA-2');
    expect(octoberTariffs.single.unitPriceMinor, 135);
  });

  test('rejects a tariff version with an invalid effective date', () async {
    await createConfiguration();

    await expectLater(
      service.createTariffVersion(
        operatorId: 'OP-ALFA',
        tariffId: 'TAR-ALFA-2',
        unitPriceMinor: 135,
        currency: 'EUR',
        validFrom: validFrom,
      ),
      throwsA(isA<StateError>()),
    );

    final tariffs = await database.select(database.operatorTariffs).get();

    expect(tariffs, hasLength(1));
    expect(tariffs.single.id, 'TAR-ALFA-1');
    expect(tariffs.single.validUntil, equals(null));
  });
}
