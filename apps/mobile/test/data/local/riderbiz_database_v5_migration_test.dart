import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';

import '../../generated_migrations/schema.dart';
import '../../generated_migrations/schema_v4.dart' as v4;

void main() {
  test('migrates v4 to v5 preserving accounting and accepted route', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(4);
    final old = v4.DatabaseAtV4(schema.newConnection());
    final timestamp = DateTime.utc(2026, 10, 24, 8);
    final seconds =
        timestamp.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
    const acceptedJson = '{"version":1,"stopOrder":["STOP-A"]}';

    try {
      await old.customStatement(
        'INSERT INTO logistics_operators (id, name, created_at) VALUES (?, ?, ?)',
        ['OP-V4', 'Operador sintético', seconds],
      );
      await old.customStatement(
        'INSERT INTO delivery_runs (id, operator_id, started_at) VALUES (?, ?, ?)',
        ['RUN-V4', 'OP-V4', seconds],
      );
      await old.customStatement(
        'INSERT INTO operator_tariffs '
        '(id, operator_id, version, unit_price_minor, currency, valid_from, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['TAR-V4', 'OP-V4', 1, 120, 'EUR', seconds, seconds],
      );
      await old.customStatement(
        'INSERT INTO synthetic_packages '
        '(id, delivery_run_id, status, identified_operator_id, '
        'tariff_id, tariff_version_snapshot, unit_price_minor_snapshot, '
        'currency_snapshot, delivered_at, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'PKG-V4',
          'RUN-V4',
          'delivered',
          'OP-V4',
          'TAR-V4',
          1,
          120,
          'EUR',
          seconds,
          seconds,
          seconds,
        ],
      );
      await old.customStatement(
        'INSERT INTO delivery_events '
        '(id, package_id, event_type, occurred_at) VALUES (?, ?, ?, ?)',
        ['EVENT-V4', 'PKG-V4', 'delivered', seconds],
      );
      await old.customStatement(
        'INSERT INTO accepted_route_snapshots '
        '(route_id, snapshot_json, accepted_at) VALUES (?, ?, ?)',
        ['ROUTE-V4', acceptedJson, seconds],
      );
    } finally {
      await old.close();
    }

    final db = RiderBizDatabase.forTesting(schema.newConnection());
    try {
      await verifier.migrateAndValidate(db, 5);

      final package = await db.select(db.syntheticPackages).getSingle();
      expect(package.id, 'PKG-V4');
      expect(package.deliveryRunId, 'RUN-V4');
      expect(package.status, 'delivered');
      expect(package.identifiedOperatorId, 'OP-V4');
      expect(package.tariffId, 'TAR-V4');
      expect(package.tariffVersionSnapshot, 1);
      expect(package.unitPriceMinorSnapshot, 120);
      expect(package.currencySnapshot, 'EUR');
      expect(package.deliveredAt?.toUtc(), timestamp);

      final event = await db.select(db.deliveryEvents).getSingle();
      expect(event.id, 'EVENT-V4');
      expect(event.packageId, 'PKG-V4');
      expect(event.eventType, 'delivered');
      expect(event.occurredAt.toUtc(), timestamp);

      final tariff = await db.select(db.operatorTariffs).getSingle();
      expect(tariff.id, 'TAR-V4');
      expect(tariff.unitPriceMinor, 120);

      final accepted = await db.select(db.acceptedRouteSnapshots).getSingle();
      expect(accepted.routeId, 'ROUTE-V4');
      expect(accepted.snapshotJson, acceptedJson);
      expect(accepted.acceptedAt.toUtc(), timestamp);
      expect(await db.select(db.routePlanDefinitions).get(), isEmpty);

      await db
          .into(db.routePlanDefinitions)
          .insert(
            RoutePlanDefinitionsCompanion(
              routeId: const Value('ROUTE-V4'),
              deliveryRunId: const Value('RUN-V4'),
              definitionJson: const Value('{"version":1}'),
              updatedAt: Value(timestamp),
            ),
          );
      final definition = await db.select(db.routePlanDefinitions).getSingle();
      expect(definition.routeId, 'ROUTE-V4');
      expect(definition.deliveryRunId, 'RUN-V4');
      expect(definition.definitionJson, '{"version":1}');
      expect(definition.updatedAt.toUtc(), timestamp);
    } finally {
      await db.close();
    }
  });
}
