import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';

void main() {
  late RiderBizDatabase database;
  final startedAt = DateTime.utc(2026, 9, 1, 8);

  setUp(() {
    database = RiderBizDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertSyntheticOperation() async {
    await database
        .into(database.logisticsOperators)
        .insert(
          LogisticsOperatorsCompanion(
            id: const Value('OP-SYN-001'),
            name: const Value('Operador sintético'),
            createdAt: Value(startedAt),
          ),
        );

    await database
        .into(database.deliveryRuns)
        .insert(
          DeliveryRunsCompanion(
            id: const Value('RUN-SYN-001'),
            operatorId: const Value('OP-SYN-001'),
            startedAt: Value(startedAt),
          ),
        );

    await database
        .into(database.syntheticPackages)
        .insert(
          SyntheticPackagesCompanion(
            id: const Value('RB-SYN-0001'),
            deliveryRunId: const Value('RUN-SYN-001'),
            status: const Value('pending'),
            createdAt: Value(startedAt),
            updatedAt: Value(startedAt),
          ),
        );
  }

  test('stores related synthetic operational data', () async {
    await insertSyntheticOperation();

    final packages = await (database.select(
      database.syntheticPackages,
    )..where((row) => row.status.equals('pending'))).get();

    expect(packages, hasLength(1));
    expect(packages.single.id, 'RB-SYN-0001');
    expect(packages.single.deliveryRunId, 'RUN-SYN-001');
    expect(packages.single.needsSync, isTrue);
  });

  test('updates and filters package delivery status', () async {
    await insertSyntheticOperation();

    final updatedRows =
        await (database.update(
          database.syntheticPackages,
        )..where((row) => row.id.equals('RB-SYN-0001'))).write(
          SyntheticPackagesCompanion(
            status: const Value('delivered'),
            updatedAt: Value(startedAt.add(const Duration(hours: 1))),
          ),
        );

    final delivered = await (database.select(
      database.syntheticPackages,
    )..where((row) => row.status.equals('delivered'))).getSingle();

    expect(updatedRows, 1);
    expect(delivered.status, 'delivered');
  });

  test('rejects a package linked to a missing delivery run', () async {
    await expectLater(
      database
          .into(database.syntheticPackages)
          .insert(
            SyntheticPackagesCompanion(
              id: const Value('RB-SYN-INVALID'),
              deliveryRunId: const Value('RUN-MISSING'),
              status: const Value('pending'),
              createdAt: Value(startedAt),
              updatedAt: Value(startedAt),
            ),
          ),
      throwsA(anything),
    );
  });

  test('rolls back all writes when a transaction fails', () async {
    await insertSyntheticOperation();

    await expectLater(
      database.transaction(() async {
        await database
            .into(database.deliveryEvents)
            .insert(
              DeliveryEventsCompanion(
                id: const Value('EVENT-SYN-001'),
                packageId: const Value('RB-SYN-0001'),
                eventType: const Value('delivered'),
                occurredAt: Value(startedAt),
              ),
            );

        throw StateError('Synthetic transaction failure');
      }),
      throwsStateError,
    );

    final events = await database.select(database.deliveryEvents).get();

    expect(events, isEmpty);
  });
}
