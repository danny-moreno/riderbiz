import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('persists Drift data after a native database restart', (
    tester,
  ) async {
    final createdAt = DateTime.utc(2026, 9, 1, 8);
    RiderBizDatabase? database;

    Future<void> clearSyntheticData(RiderBizDatabase target) async {
      await target.delete(target.deliveryEvents).go();
      await target.delete(target.syntheticPackages).go();
      await target.delete(target.deliveryRuns).go();
      await target.delete(target.logisticsOperators).go();
    }

    try {
      database = RiderBizDatabase.forTesting(
        driftDatabase(name: 'riderbiz_integration_test'),
      );

      await clearSyntheticData(database);

      await database
          .into(database.logisticsOperators)
          .insert(
            LogisticsOperatorsCompanion(
              id: const Value('OP-SYN-NATIVE'),
              name: const Value('Operador sintético nativo'),
              createdAt: Value(createdAt),
            ),
          );

      await database
          .into(database.deliveryRuns)
          .insert(
            DeliveryRunsCompanion(
              id: const Value('RUN-SYN-NATIVE'),
              operatorId: const Value('OP-SYN-NATIVE'),
              startedAt: Value(createdAt),
            ),
          );

      await database
          .into(database.syntheticPackages)
          .insert(
            SyntheticPackagesCompanion(
              id: const Value('RB-SYN-NATIVE'),
              deliveryRunId: const Value('RUN-SYN-NATIVE'),
              status: const Value('delivered'),
              externalReference: const Value('EXT-SYN-NATIVE'),
              createdAt: Value(createdAt),
              updatedAt: Value(createdAt),
            ),
          );

      await database.close();
      database = null;

      database = RiderBizDatabase.forTesting(
        driftDatabase(name: 'riderbiz_integration_test'),
      );

      final restoredPackage = await (database.select(
        database.syntheticPackages,
      )..where((row) => row.id.equals('RB-SYN-NATIVE'))).getSingle();

      expect(restoredPackage.status, 'delivered');
      expect(restoredPackage.deliveryRunId, 'RUN-SYN-NATIVE');
      expect(restoredPackage.externalReference, 'EXT-SYN-NATIVE');

      await clearSyntheticData(database);
    } finally {
      await database?.close();
    }
  });
}
