import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/delivery_accounting/delivery_accounting_service.dart';
import 'package:riderbiz_mobile/features/operator_settings/operator_tariff_service.dart';

void main() {
  late RiderBizDatabase database;
  late OperatorTariffService tariffService;
  late DeliveryAccountingService deliveryService;

  final startedAt = DateTime.utc(2026, 9, 4, 8);
  final deliveredAt = DateTime.utc(2026, 9, 4, 10);

  setUp(() {
    database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    tariffService = OperatorTariffService(database);
    deliveryService = DeliveryAccountingService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createOperatorAndTariff() {
    return tariffService.createInitialConfiguration(
      operatorId: 'OP-ALFA',
      operatorName: 'Operador Alfa',
      tariffId: 'TAR-ALFA-1',
      unitPriceMinor: 120,
      currency: 'EUR',
      validFrom: startedAt,
      createdAt: startedAt,
    );
  }

  Future<void> createRunAndPackage({
    String? identifiedOperatorId = 'OP-ALFA',
  }) async {
    await database
        .into(database.deliveryRuns)
        .insert(
          DeliveryRunsCompanion.insert(
            id: 'RUN-SYN-001',
            operatorId: 'OP-ALFA',
            startedAt: startedAt,
          ),
        );

    await database
        .into(database.syntheticPackages)
        .insert(
          SyntheticPackagesCompanion.insert(
            id: 'RB-SYN-001',
            deliveryRunId: 'RUN-SYN-001',
            identifiedOperatorId: Value(identifiedOperatorId),
            identificationStatus: Value(
              identifiedOperatorId == null ? 'unknown' : 'identified',
            ),
            identificationConfidence: Value(
              identifiedOperatorId == null ? null : 1,
            ),
            createdAt: startedAt,
            updatedAt: startedAt,
          ),
        );
  }

  test('confirms delivery with an immutable tariff snapshot', () async {
    await createOperatorAndTariff();
    await createRunAndPackage();

    final deliveredPackage = await deliveryService.confirmDelivery(
      packageId: 'RB-SYN-001',
      eventId: 'EVENT-DELIVERED-001',
      deliveredAt: deliveredAt,
    );

    expect(deliveredPackage.status, 'delivered');
    expect(deliveredPackage.identifiedOperatorId, 'OP-ALFA');
    expect(deliveredPackage.tariffId, 'TAR-ALFA-1');
    expect(deliveredPackage.tariffVersionSnapshot, 1);
    expect(deliveredPackage.unitPriceMinorSnapshot, 120);
    expect(deliveredPackage.currencySnapshot, 'EUR');
    expect(deliveredPackage.deliveredAt?.toUtc(), deliveredAt);

    final event = await database.select(database.deliveryEvents).getSingle();

    expect(event.id, 'EVENT-DELIVERED-001');
    expect(event.packageId, 'RB-SYN-001');
    expect(event.eventType, 'delivered');
    expect(event.occurredAt.toUtc(), deliveredAt);
  });

  test('later tariff update does not change a delivered package', () async {
    await createOperatorAndTariff();
    await createRunAndPackage();

    await deliveryService.confirmDelivery(
      packageId: 'RB-SYN-001',
      eventId: 'EVENT-DELIVERED-001',
      deliveredAt: deliveredAt,
    );

    await tariffService.createTariffVersion(
      operatorId: 'OP-ALFA',
      tariffId: 'TAR-ALFA-2',
      unitPriceMinor: 150,
      currency: 'EUR',
      validFrom: DateTime.utc(2026, 10, 1),
      createdAt: DateTime.utc(2026, 9, 20),
    );

    final persistedPackage = await (database.select(
      database.syntheticPackages,
    )..where((row) => row.id.equals('RB-SYN-001'))).getSingle();

    expect(persistedPackage.tariffId, 'TAR-ALFA-1');
    expect(persistedPackage.tariffVersionSnapshot, 1);
    expect(persistedPackage.unitPriceMinorSnapshot, 120);
    expect(persistedPackage.currencySnapshot, 'EUR');

    final tariffs = await (database.select(
      database.operatorTariffs,
    )..orderBy([(row) => OrderingTerm.asc(row.version)])).get();

    expect(tariffs, hasLength(2));
    expect(tariffs.first.unitPriceMinor, 120);
    expect(tariffs.last.unitPriceMinor, 150);
  });

  test('rejects delivery when the operator is not identified', () async {
    await createOperatorAndTariff();
    await createRunAndPackage(identifiedOperatorId: null);

    await expectLater(
      deliveryService.confirmDelivery(
        packageId: 'RB-SYN-001',
        eventId: 'EVENT-DELIVERED-001',
        deliveredAt: deliveredAt,
      ),
      throwsA(isA<StateError>()),
    );

    final package = await database
        .select(database.syntheticPackages)
        .getSingle();

    expect(package.status, 'pending');
    expect(package.tariffId, equals(null));
    expect(await database.select(database.deliveryEvents).get(), isEmpty);
  });

  test('does not allow the same package to be delivered twice', () async {
    await createOperatorAndTariff();
    await createRunAndPackage();

    await deliveryService.confirmDelivery(
      packageId: 'RB-SYN-001',
      eventId: 'EVENT-DELIVERED-001',
      deliveredAt: deliveredAt,
    );

    await expectLater(
      deliveryService.confirmDelivery(
        packageId: 'RB-SYN-001',
        eventId: 'EVENT-DELIVERED-002',
        deliveredAt: deliveredAt.add(const Duration(minutes: 1)),
      ),
      throwsA(isA<StateError>()),
    );

    final events = await database.select(database.deliveryEvents).get();

    expect(events, hasLength(1));
    expect(events.single.id, 'EVENT-DELIVERED-001');
  });
}
