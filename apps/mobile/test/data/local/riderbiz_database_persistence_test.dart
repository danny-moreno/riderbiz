import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';

void main() {
  late Directory temporaryDirectory;
  late File databaseFile;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'riderbiz_drift_test_',
    );
    databaseFile = File('${temporaryDirectory.path}/riderbiz.sqlite');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('keeps synthetic data after closing and reopening SQLite', () async {
    final createdAt = DateTime.utc(2026, 9, 1, 8);
    RiderBizDatabase? database;

    try {
      database = RiderBizDatabase.forTesting(NativeDatabase(databaseFile));

      await database
          .into(database.logisticsOperators)
          .insert(
            LogisticsOperatorsCompanion(
              id: const Value('OP-SYN-DISK'),
              name: const Value('Operador sintético en disco'),
              createdAt: Value(createdAt),
            ),
          );

      await database
          .into(database.deliveryRuns)
          .insert(
            DeliveryRunsCompanion(
              id: const Value('RUN-SYN-DISK'),
              operatorId: const Value('OP-SYN-DISK'),
              startedAt: Value(createdAt),
            ),
          );

      await database
          .into(database.syntheticPackages)
          .insert(
            SyntheticPackagesCompanion(
              id: const Value('RB-SYN-DISK'),
              deliveryRunId: const Value('RUN-SYN-DISK'),
              status: const Value('delivered'),
              externalReference: const Value('EXT-SYN-001'),
              createdAt: Value(createdAt),
              updatedAt: Value(createdAt),
            ),
          );

      await database.close();
      database = null;

      expect(await databaseFile.exists(), isTrue);

      database = RiderBizDatabase.forTesting(NativeDatabase(databaseFile));

      final restoredPackage = await (database.select(
        database.syntheticPackages,
      )..where((row) => row.id.equals('RB-SYN-DISK'))).getSingle();

      expect(restoredPackage.status, 'delivered');
      expect(restoredPackage.deliveryRunId, 'RUN-SYN-DISK');
      expect(restoredPackage.externalReference, 'EXT-SYN-001');
    } finally {
      await database?.close();
    }
  });
}
