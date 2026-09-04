import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/delivery_reports/delivery_report_service.dart';

void main() {
  late RiderBizDatabase database;
  late DeliveryReportService service;

  setUp(() {
    database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    service = DeliveryReportService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertOperator({required String id, required String name}) {
    return database
        .into(database.logisticsOperators)
        .insert(
          LogisticsOperatorsCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        );
  }

  Future<void> insertTariff({
    required String id,
    required String operatorId,
    required int version,
    required int unitPriceMinor,
    required DateTime validFrom,
    DateTime? validUntil,
  }) {
    return database
        .into(database.operatorTariffs)
        .insert(
          OperatorTariffsCompanion.insert(
            id: id,
            operatorId: operatorId,
            version: version,
            unitPriceMinor: unitPriceMinor,
            currency: 'EUR',
            validFrom: validFrom,
            validUntil: Value(validUntil),
            createdAt: validFrom,
          ),
        );
  }

  Future<void> insertRun({required String id, required String operatorId}) {
    return database
        .into(database.deliveryRuns)
        .insert(
          DeliveryRunsCompanion.insert(
            id: id,
            operatorId: operatorId,
            startedAt: DateTime.utc(2026, 9, 1),
          ),
        );
  }

  Future<void> insertDeliveredPackage({
    required String id,
    required String runId,
    required String operatorId,
    required String tariffId,
    required int tariffVersion,
    required int unitPriceMinor,
    required DateTime deliveredAt,
  }) {
    return database
        .into(database.syntheticPackages)
        .insert(
          SyntheticPackagesCompanion.insert(
            id: id,
            deliveryRunId: runId,
            status: const Value('delivered'),
            identifiedOperatorId: Value(operatorId),
            identificationStatus: const Value('identified'),
            identificationConfidence: const Value(1),
            tariffId: Value(tariffId),
            tariffVersionSnapshot: Value(tariffVersion),
            unitPriceMinorSnapshot: Value(unitPriceMinor),
            currencySnapshot: const Value('EUR'),
            deliveredAt: Value(deliveredAt),
            createdAt: deliveredAt,
            updatedAt: deliveredAt,
          ),
        );
  }

  test('creates a daily report grouped by operator', () async {
    await insertOperator(id: 'OP-ALFA', name: 'Operador Alfa');
    await insertOperator(id: 'OP-BETA', name: 'Operador Beta');

    await insertTariff(
      id: 'TAR-ALFA-1',
      operatorId: 'OP-ALFA',
      version: 1,
      unitPriceMinor: 120,
      validFrom: DateTime.utc(2026, 9, 1),
    );
    await insertTariff(
      id: 'TAR-BETA-1',
      operatorId: 'OP-BETA',
      version: 1,
      unitPriceMinor: 150,
      validFrom: DateTime.utc(2026, 9, 1),
    );

    await insertRun(id: 'RUN-ALFA', operatorId: 'OP-ALFA');
    await insertRun(id: 'RUN-BETA', operatorId: 'OP-BETA');

    await insertDeliveredPackage(
      id: 'PKG-ALFA-1',
      runId: 'RUN-ALFA',
      operatorId: 'OP-ALFA',
      tariffId: 'TAR-ALFA-1',
      tariffVersion: 1,
      unitPriceMinor: 120,
      deliveredAt: DateTime.utc(2026, 9, 4, 8),
    );
    await insertDeliveredPackage(
      id: 'PKG-ALFA-2',
      runId: 'RUN-ALFA',
      operatorId: 'OP-ALFA',
      tariffId: 'TAR-ALFA-1',
      tariffVersion: 1,
      unitPriceMinor: 120,
      deliveredAt: DateTime.utc(2026, 9, 4, 12),
    );
    await insertDeliveredPackage(
      id: 'PKG-BETA-1',
      runId: 'RUN-BETA',
      operatorId: 'OP-BETA',
      tariffId: 'TAR-BETA-1',
      tariffVersion: 1,
      unitPriceMinor: 150,
      deliveredAt: DateTime.utc(2026, 9, 4, 15),
    );

    final report = await service.daily(DateTime.utc(2026, 9, 4));

    expect(report.lines, hasLength(2));
    expect(report.deliveredCount, 3);
    expect(report.totalMinorForCurrency('eur'), 390);

    final alfa = report.lines.first;
    final beta = report.lines.last;

    expect(alfa.operatorName, 'Operador Alfa');
    expect(alfa.deliveredCount, 2);
    expect(alfa.unitPriceMinor, 120);
    expect(alfa.totalMinor, 240);

    expect(beta.operatorName, 'Operador Beta');
    expect(beta.deliveredCount, 1);
    expect(beta.unitPriceMinor, 150);
    expect(beta.totalMinor, 150);
  });

  test('keeps tariff versions separate in a monthly report', () async {
    await insertOperator(id: 'OP-ALFA', name: 'Operador Alfa');

    await insertTariff(
      id: 'TAR-ALFA-1',
      operatorId: 'OP-ALFA',
      version: 1,
      unitPriceMinor: 120,
      validFrom: DateTime.utc(2026, 9, 1),
      validUntil: DateTime.utc(2026, 9, 15),
    );
    await insertTariff(
      id: 'TAR-ALFA-2',
      operatorId: 'OP-ALFA',
      version: 2,
      unitPriceMinor: 150,
      validFrom: DateTime.utc(2026, 9, 15),
    );

    await insertRun(id: 'RUN-ALFA', operatorId: 'OP-ALFA');

    await insertDeliveredPackage(
      id: 'PKG-OLD-PRICE',
      runId: 'RUN-ALFA',
      operatorId: 'OP-ALFA',
      tariffId: 'TAR-ALFA-1',
      tariffVersion: 1,
      unitPriceMinor: 120,
      deliveredAt: DateTime.utc(2026, 9, 10),
    );
    await insertDeliveredPackage(
      id: 'PKG-NEW-PRICE',
      runId: 'RUN-ALFA',
      operatorId: 'OP-ALFA',
      tariffId: 'TAR-ALFA-2',
      tariffVersion: 2,
      unitPriceMinor: 150,
      deliveredAt: DateTime.utc(2026, 9, 20),
    );

    final report = await service.monthly(year: 2026, month: 9);

    expect(report.lines, hasLength(2));
    expect(report.deliveredCount, 2);
    expect(report.totalMinorForCurrency('EUR'), 270);

    expect(report.lines.first.tariffVersion, 1);
    expect(report.lines.first.totalMinor, 120);
    expect(report.lines.last.tariffVersion, 2);
    expect(report.lines.last.totalMinor, 150);
  });

  test('weekly report includes Monday through Sunday only', () async {
    await insertOperator(id: 'OP-GAMMA', name: 'Operador Gamma');
    await insertTariff(
      id: 'TAR-GAMMA-1',
      operatorId: 'OP-GAMMA',
      version: 1,
      unitPriceMinor: 110,
      validFrom: DateTime.utc(2026, 9, 1),
    );
    await insertRun(id: 'RUN-GAMMA', operatorId: 'OP-GAMMA');

    await insertDeliveredPackage(
      id: 'PKG-MONDAY',
      runId: 'RUN-GAMMA',
      operatorId: 'OP-GAMMA',
      tariffId: 'TAR-GAMMA-1',
      tariffVersion: 1,
      unitPriceMinor: 110,
      deliveredAt: DateTime.utc(2026, 9, 7),
    );
    await insertDeliveredPackage(
      id: 'PKG-SUNDAY',
      runId: 'RUN-GAMMA',
      operatorId: 'OP-GAMMA',
      tariffId: 'TAR-GAMMA-1',
      tariffVersion: 1,
      unitPriceMinor: 110,
      deliveredAt: DateTime.utc(2026, 9, 13, 23, 59),
    );
    await insertDeliveredPackage(
      id: 'PKG-NEXT-MONDAY',
      runId: 'RUN-GAMMA',
      operatorId: 'OP-GAMMA',
      tariffId: 'TAR-GAMMA-1',
      tariffVersion: 1,
      unitPriceMinor: 110,
      deliveredAt: DateTime.utc(2026, 9, 14),
    );

    final report = await service.weekly(DateTime.utc(2026, 9, 10));

    expect(report.deliveredCount, 2);
    expect(report.lines.single.operatorId, 'OP-GAMMA');
    expect(report.lines.single.totalMinor, 220);
  });

  test('rejects invalid report periods', () async {
    expect(() => service.monthly(year: 2026, month: 13), throwsArgumentError);

    await expectLater(
      service.forPeriod(
        start: DateTime.utc(2026, 9, 5),
        end: DateTime.utc(2026, 9, 5),
      ),
      throwsArgumentError,
    );
  });
}
