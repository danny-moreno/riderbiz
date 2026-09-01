import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';

import '../../generated_migrations/schema.dart';
import '../../generated_migrations/schema_v1.dart' as v1;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('migrates v1 data to v2 without losing the package', () async {
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

    await verifier.migrateAndValidate(migratedDatabase, 2);

    final migratedPackage = await (migratedDatabase.select(
      migratedDatabase.syntheticPackages,
    )..where((row) => row.id.equals('RB-SYN-MIGRATION'))).getSingle();

    expect(migratedPackage.status, 'pending');
    expect(migratedPackage.externalReference, equals(null));
    expect(migratedPackage.deliveryRunId, 'RUN-SYN-MIGRATION');

    await migratedDatabase.close();
  });
}
