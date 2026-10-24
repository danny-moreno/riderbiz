import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';

import '../../generated_migrations/schema.dart';
import '../../generated_migrations/schema_v1.dart' as v1;
import '../../generated_migrations/schema_v2.dart' as v2;
import '../../generated_migrations/schema_v3.dart' as v3;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('migrates v1 data to v3 without losing the package', () async {
    final schema = await verifier.schemaAt(1);
    final createdAt = DateTime.utc(2026, 9, 1, 8);
    final createdAtSeconds =
        createdAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

    final oldDatabase = v1.DatabaseAtV1(schema.newConnection());

    await oldDatabase
        .into(oldDatabase.logisticsOperators)
        .insert(
          v1.LogisticsOperatorsCompanion(
            id: const Value('OP-SYN-MIGRATION'),
            name: const Value('Operador sintético de migración'),
            createdAt: Value(createdAtSeconds),
          ),
        );

    await oldDatabase
        .into(oldDatabase.deliveryRuns)
        .insert(
          v1.DeliveryRunsCompanion(
            id: const Value('RUN-SYN-MIGRATION'),
            operatorId: const Value('OP-SYN-MIGRATION'),
            startedAt: Value(createdAtSeconds),
          ),
        );

    await oldDatabase
        .into(oldDatabase.syntheticPackages)
        .insert(
          v1.SyntheticPackagesCompanion(
            id: const Value('RB-SYN-MIGRATION'),
            deliveryRunId: const Value('RUN-SYN-MIGRATION'),
            status: const Value('pending'),
            createdAt: Value(createdAtSeconds),
            updatedAt: Value(createdAtSeconds),
          ),
        );

    await oldDatabase.close();

    final migratedDatabase = RiderBizDatabase.forTesting(
      schema.newConnection(),
    );

    await verifier.migrateAndValidate(migratedDatabase, 3);

    final migratedPackage = await (migratedDatabase.select(
      migratedDatabase.syntheticPackages,
    )..where((row) => row.id.equals('RB-SYN-MIGRATION'))).getSingle();

    expect(migratedPackage.status, 'pending');
    expect(migratedPackage.externalReference, equals(null));
    expect(migratedPackage.deliveryRunId, 'RUN-SYN-MIGRATION');
    expect(migratedPackage.tariffVersionSnapshot, equals(null));
    expect(migratedPackage.deliveredAt, equals(null));

    await migratedDatabase.close();
  });

  test('migrates v2 data to v3 without losing existing data', () async {
    final schema = await verifier.schemaAt(2);
    final createdAt = DateTime.utc(2026, 9, 4, 8);
    final createdAtSeconds =
        createdAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

    final oldDatabase = v2.DatabaseAtV2(schema.newConnection());

    await oldDatabase
        .into(oldDatabase.logisticsOperators)
        .insert(
          v2.LogisticsOperatorsCompanion(
            id: const Value('OP-SYN-V2'),
            name: const Value('Operador sintético V2'),
            createdAt: Value(createdAtSeconds),
          ),
        );

    await oldDatabase
        .into(oldDatabase.deliveryRuns)
        .insert(
          v2.DeliveryRunsCompanion(
            id: const Value('RUN-SYN-V2'),
            operatorId: const Value('OP-SYN-V2'),
            startedAt: Value(createdAtSeconds),
          ),
        );

    await oldDatabase
        .into(oldDatabase.syntheticPackages)
        .insert(
          v2.SyntheticPackagesCompanion(
            id: const Value('RB-SYN-V2'),
            deliveryRunId: const Value('RUN-SYN-V2'),
            status: const Value('pending'),
            externalReference: const Value('REF-SYN-V2'),
            createdAt: Value(createdAtSeconds),
            updatedAt: Value(createdAtSeconds),
          ),
        );

    await oldDatabase.close();

    final migratedDatabase = RiderBizDatabase.forTesting(
      schema.newConnection(),
    );

    await verifier.migrateAndValidate(migratedDatabase, 4);

    final migratedOperator = await (migratedDatabase.select(
      migratedDatabase.logisticsOperators,
    )..where((row) => row.id.equals('OP-SYN-V2'))).getSingle();

    final migratedPackage = await (migratedDatabase.select(
      migratedDatabase.syntheticPackages,
    )..where((row) => row.id.equals('RB-SYN-V2'))).getSingle();

    expect(migratedOperator.name, 'Operador sintético V2');
    expect(migratedOperator.isActive, equals(true));

    expect(migratedPackage.status, 'pending');
    expect(migratedPackage.externalReference, 'REF-SYN-V2');
    expect(migratedPackage.identifiedOperatorId, equals(null));
    expect(migratedPackage.identificationStatus, 'unknown');
    expect(migratedPackage.identificationConfidence, equals(null));
    expect(migratedPackage.tariffId, equals(null));
    expect(migratedPackage.tariffVersionSnapshot, equals(null));
    expect(migratedPackage.unitPriceMinorSnapshot, equals(null));
    expect(migratedPackage.currencySnapshot, equals(null));
    expect(migratedPackage.deliveredAt, equals(null));
    expect(
      await migratedDatabase.select(migratedDatabase.operatorTariffs).get(),
      isEmpty,
    );
    expect(
      await migratedDatabase
          .select(migratedDatabase.operatorLabelProfiles)
          .get(),
      isEmpty,
    );

    await migratedDatabase.close();
  });

  test(
    'migrates v3 to v4 preserving data and allowing route storage',
    () async {
      final schema = await verifier.schemaAt(3);
      final oldDatabase = v3.DatabaseAtV3(schema.newConnection());
      final acceptedAt = DateTime.utc(2026, 10, 24, 8);
      final timestamp =
          acceptedAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

      try {
        await oldDatabase.customStatement(
          'INSERT INTO logistics_operators (id, name, created_at) '
          'VALUES (?, ?, ?)',
          ['OP-SYN-V3', 'Operador sintético V3', timestamp],
        );

        await oldDatabase.customStatement(
          'INSERT INTO delivery_runs (id, operator_id, started_at) '
          'VALUES (?, ?, ?)',
          ['RUN-SYN-V3', 'OP-SYN-V3', timestamp],
        );

        await oldDatabase.customStatement(
          'INSERT INTO synthetic_packages '
          '(id, delivery_run_id, status, external_reference, '
          'unit_price_minor_snapshot, currency_snapshot, delivered_at, '
          'created_at, updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'RB-SYN-V3',
            'RUN-SYN-V3',
            'delivered',
            'REF-SYN-V3',
            125,
            'EUR',
            timestamp,
            timestamp,
            timestamp,
          ],
        );
      } finally {
        await oldDatabase.close();
      }

      final database = RiderBizDatabase.forTesting(schema.newConnection());

      try {
        await verifier.migrateAndValidate(database, 4);

        final package = await (database.select(
          database.syntheticPackages,
        )..where((row) => row.id.equals('RB-SYN-V3'))).getSingle();

        expect(package.status, 'delivered');
        expect(package.deliveryRunId, 'RUN-SYN-V3');
        expect(package.externalReference, 'REF-SYN-V3');
        expect(package.unitPriceMinorSnapshot, 125);
        expect(package.currencySnapshot, 'EUR');
        expect(package.deliveredAt?.toUtc(), acceptedAt);

        expect(
          await database.select(database.acceptedRouteSnapshots).get(),
          isEmpty,
        );

        const snapshot = '{"version":1,"stopOrder":["STOP-A","STOP-B"]}';

        await database
            .into(database.acceptedRouteSnapshots)
            .insert(
              AcceptedRouteSnapshotsCompanion(
                routeId: const Value('ROUTE-SYN-MIGRATION'),
                snapshotJson: const Value(snapshot),
                acceptedAt: Value(acceptedAt),
              ),
            );

        final restored = await database
            .select(database.acceptedRouteSnapshots)
            .getSingle();

        expect(restored.routeId, 'ROUTE-SYN-MIGRATION');
        expect(restored.snapshotJson, snapshot);
        expect(restored.acceptedAt.toUtc(), acceptedAt);
      } finally {
        await database.close();
      }
    },
  );
}
