import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/delivery_accounting/delivery_accounting_service.dart';
import 'package:riderbiz_mobile/features/delivery_reports/delivery_report_service.dart';
import 'package:riderbiz_mobile/features/operator_identification/operator_identification_service.dart';
import 'package:riderbiz_mobile/features/operator_identification/operator_identifier.dart';
import 'package:riderbiz_mobile/features/operator_settings/operator_tariff_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'runs operator identification tariffs and reports on native SQLite',
    (tester) async {
      final startedAt = DateTime.utc(2026, 9, 4, 8);
      final deliveredAt = DateTime.utc(2026, 9, 4, 10);

      RiderBizDatabase? database;

      Future<void> clearSyntheticData(RiderBizDatabase target) async {
        await target.delete(target.deliveryEvents).go();
        await target.delete(target.syntheticPackages).go();
        await target.delete(target.deliveryRuns).go();
        await target.delete(target.operatorLabelProfiles).go();
        await target.delete(target.operatorTariffs).go();
        await target.delete(target.logisticsOperators).go();
      }

      try {
        database = RiderBizDatabase.forTesting(
          driftDatabase(name: 'riderbiz_operator_tariff_integration_test'),
        );

        await clearSyntheticData(database);

        final tariffService = OperatorTariffService(database);

        await tariffService.createInitialConfiguration(
          operatorId: 'OP-ALFA',
          operatorName: 'Operador Alfa',
          tariffId: 'TAR-ALFA-1',
          unitPriceMinor: 120,
          currency: 'EUR',
          validFrom: startedAt,
          createdAt: startedAt,
        );

        await tariffService.createInitialConfiguration(
          operatorId: 'OP-BETA',
          operatorName: 'Operador Beta',
          tariffId: 'TAR-BETA-1',
          unitPriceMinor: 150,
          currency: 'EUR',
          validFrom: startedAt,
          createdAt: startedAt,
        );

        await tariffService.createInitialConfiguration(
          operatorId: 'OP-GAMMA',
          operatorName: 'Operador Gamma',
          tariffId: 'TAR-GAMMA-1',
          unitPriceMinor: 110,
          currency: 'EUR',
          validFrom: startedAt,
          createdAt: startedAt,
        );

        for (final profile in const [
          ('PROFILE-BETA-1', 'TRANSPORTES BETA'),
          ('PROFILE-BETA-2', 'BET-PACK'),
          ('PROFILE-BETA-3', 'RED BETA'),
        ]) {
          await database
              .into(database.operatorLabelProfiles)
              .insert(
                OperatorLabelProfilesCompanion.insert(
                  id: profile.$1,
                  operatorId: 'OP-BETA',
                  marker: profile.$2,
                  createdAt: startedAt,
                ),
              );
        }

        await database
            .into(database.deliveryRuns)
            .insert(
              DeliveryRunsCompanion.insert(
                id: 'RUN-SYN-NATIVE-015',
                operatorId: 'OP-BETA',
                startedAt: startedAt,
              ),
            );

        await database
            .into(database.syntheticPackages)
            .insert(
              SyntheticPackagesCompanion.insert(
                id: 'RB-SYN-NATIVE-015',
                deliveryRunId: 'RUN-SYN-NATIVE-015',
                createdAt: startedAt,
                updatedAt: startedAt,
              ),
            );

        final identificationService = OperatorIdentificationService(database);

        final identification = await identificationService.identifyAndStore(
          packageId: 'RB-SYN-NATIVE-015',
          labelText: '''
            TRANSPORTES BETA
            Código sintético BET-PACK-015
          ''',
          identifiedAt: DateTime.utc(2026, 9, 4, 9),
        );

        expect(identification.status, OperatorIdentificationStatus.identified);
        expect(identification.operatorId, 'OP-BETA');

        final deliveryService = DeliveryAccountingService(database);

        await deliveryService.confirmDelivery(
          packageId: 'RB-SYN-NATIVE-015',
          eventId: 'EVENT-SYN-NATIVE-015',
          deliveredAt: deliveredAt,
        );

        await tariffService.createTariffVersion(
          operatorId: 'OP-BETA',
          tariffId: 'TAR-BETA-2',
          unitPriceMinor: 175,
          currency: 'EUR',
          validFrom: DateTime.utc(2026, 10, 1),
          createdAt: DateTime.utc(2026, 9, 20),
        );

        final reportService = DeliveryReportService(database);
        final initialReport = await reportService.daily(deliveredAt);

        expect(initialReport.deliveredCount, 1);
        expect(initialReport.lines.single.operatorId, 'OP-BETA');
        expect(initialReport.lines.single.tariffVersion, 1);
        expect(initialReport.lines.single.unitPriceMinor, 150);
        expect(initialReport.totalMinorForCurrency('EUR'), 150);

        await database.close();
        database = null;

        database = RiderBizDatabase.forTesting(
          driftDatabase(name: 'riderbiz_operator_tariff_integration_test'),
        );

        final restoredPackage = await (database.select(
          database.syntheticPackages,
        )..where((row) => row.id.equals('RB-SYN-NATIVE-015'))).getSingle();

        expect(restoredPackage.status, 'delivered');
        expect(restoredPackage.identifiedOperatorId, 'OP-BETA');
        expect(restoredPackage.identificationStatus, 'identified');
        expect(restoredPackage.tariffId, 'TAR-BETA-1');
        expect(restoredPackage.tariffVersionSnapshot, 1);
        expect(restoredPackage.unitPriceMinorSnapshot, 150);
        expect(restoredPackage.currencySnapshot, 'EUR');
        expect(restoredPackage.externalReference, equals(null));

        final restoredReport = await DeliveryReportService(database)
            .daily(deliveredAt);

        expect(restoredReport.deliveredCount, 1);
        expect(restoredReport.lines.single.operatorName, 'Operador Beta');
        expect(restoredReport.lines.single.tariffVersion, 1);
        expect(restoredReport.totalMinorForCurrency('EUR'), 150);

        await clearSyntheticData(database);
      } finally {
        await database?.close();
      }
    },
  );
}
