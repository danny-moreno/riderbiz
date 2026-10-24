import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/delivery_accounting/delivery_accounting_service.dart';
import 'package:riderbiz_mobile/features/operator_settings/operator_tariff_service.dart';

void main() {
  for (final count in [100, 125, 150, 200, 250, 300, 500]) {
    test('$count packages retain accounting across SQLite reopen', () async {
      final directory = await Directory.systemTemp.createTemp('rb_daily_');
      final file = File('${directory.path}/daily.sqlite');
      RiderBizDatabase? connection;

      final startedAt = DateTime.utc(2026, 10, 24, 8);
      final firstDelivery = DateTime.utc(2026, 10, 24, 10);
      final tariffChange = DateTime.utc(2026, 10, 24, 12);
      final secondDelivery = DateTime.utc(2026, 10, 24, 14);
      final half = count ~/ 2;

      String packageId(int index) => 'PKG-DAILY-$index';
      String eventId(int index) => 'EVENT-DAILY-$index';

      Future<void> checkState(RiderBizDatabase db, int completed) async {
        final packages = await db.select(db.syntheticPackages).get();
        final events = await db.select(db.deliveryEvents).get();
        final byId = {for (final package in packages) package.id: package};

        expect(packages, hasLength(count));
        expect(byId.keys.toSet(), {
          for (var index = 0; index < count; index++) packageId(index),
        });
        expect(events, hasLength(completed));
        expect(events.map((event) => event.packageId).toSet(), {
          for (var index = 0; index < completed; index++) packageId(index),
        });
        expect(events.map((event) => event.id).toSet(), {
          for (var index = 0; index < completed; index++) eventId(index),
        });

        var totalMinor = 0;
        for (var index = 0; index < count; index++) {
          final package = byId[packageId(index)]!;
          expect(package.deliveryRunId, 'RUN-DAILY');
          expect(package.identifiedOperatorId, 'OP-DAILY');

          if (index < completed) {
            final first = index < half;
            expect(package.status, 'delivered');
            expect(package.tariffId, first ? 'TAR-DAILY-1' : 'TAR-DAILY-2');
            expect(package.tariffVersionSnapshot, first ? 1 : 2);
            expect(package.unitPriceMinorSnapshot, first ? 120 : 150);
            expect(package.currencySnapshot, 'EUR');
            expect(
              package.deliveredAt?.toUtc(),
              first ? firstDelivery : secondDelivery,
            );
            totalMinor += package.unitPriceMinorSnapshot!;
          } else {
            expect(package.status, 'pending');
            expect(package.tariffId, isNull);
            expect(package.tariffVersionSnapshot, isNull);
            expect(package.unitPriceMinorSnapshot, isNull);
            expect(package.currencySnapshot, isNull);
            expect(package.deliveredAt, isNull);
          }
        }

        expect(
          totalMinor,
          completed <= half
              ? completed * 120
              : half * 120 + (completed - half) * 150,
        );
        for (final event in events) {
          final package = byId[event.packageId]!;
          expect(event.eventType, 'delivered');
          expect(event.occurredAt.toUtc(), package.deliveredAt?.toUtc());
        }
      }

      try {
        var db = RiderBizDatabase.forTesting(NativeDatabase(file));
        connection = db;

        await OperatorTariffService(db).createInitialConfiguration(
          operatorId: 'OP-DAILY',
          operatorName: 'Operador sintético diario',
          tariffId: 'TAR-DAILY-1',
          unitPriceMinor: 120,
          currency: 'EUR',
          validFrom: startedAt,
          createdAt: startedAt,
        );
        await db
            .into(db.deliveryRuns)
            .insert(
              DeliveryRunsCompanion.insert(
                id: 'RUN-DAILY',
                operatorId: 'OP-DAILY',
                startedAt: startedAt,
              ),
            );
        await db.batch((batch) {
          batch.insertAll(db.syntheticPackages, [
            for (var index = 0; index < count; index++)
              SyntheticPackagesCompanion.insert(
                id: packageId(index),
                deliveryRunId: 'RUN-DAILY',
                identifiedOperatorId: const Value('OP-DAILY'),
                identificationStatus: const Value('identified'),
                createdAt: startedAt,
                updatedAt: startedAt,
              ),
          ]);
        });

        for (var index = 0; index < half; index++) {
          await DeliveryAccountingService(db).confirmDelivery(
            packageId: packageId(index),
            eventId: eventId(index),
            deliveredAt: firstDelivery,
          );
        }
        await checkState(db, half);

        await db.close();
        connection = null;
        db = RiderBizDatabase.forTesting(NativeDatabase(file));
        connection = db;
        await checkState(db, half);

        for (var index = 0; index < half; index++) {
          for (final retryId in [eventId(index), 'RETRY-$index']) {
            await expectLater(
              DeliveryAccountingService(db).confirmDelivery(
                packageId: packageId(index),
                eventId: retryId,
                deliveredAt: secondDelivery,
              ),
              throwsA(isA<StateError>()),
            );
          }
        }
        await checkState(db, half);

        await OperatorTariffService(db).createTariffVersion(
          operatorId: 'OP-DAILY',
          tariffId: 'TAR-DAILY-2',
          unitPriceMinor: 150,
          currency: 'EUR',
          validFrom: tariffChange,
          createdAt: tariffChange,
        );
        await checkState(db, half);

        // Force an event-ID collision after the service updates a pending
        // package. The transaction must roll that update back.
        await expectLater(
          DeliveryAccountingService(db).confirmDelivery(
            packageId: packageId(half),
            eventId: eventId(0),
            deliveredAt: secondDelivery,
          ),
          throwsA(isNot(isA<StateError>())),
        );
        await checkState(db, half);

        for (var index = half; index < count; index++) {
          await DeliveryAccountingService(db).confirmDelivery(
            packageId: packageId(index),
            eventId: eventId(index),
            deliveredAt: secondDelivery,
          );
        }
        await checkState(db, count);

        await db.close();
        connection = null;
        db = RiderBizDatabase.forTesting(NativeDatabase(file));
        connection = db;
        await checkState(db, count);
      } finally {
        await connection?.close();
        await directory.delete(recursive: true);
      }
    });
  }
}
