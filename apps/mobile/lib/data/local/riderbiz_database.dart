import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'riderbiz_database.g.dart';

class LogisticsOperators extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DeliveryRuns extends Table {
  TextColumn get id => text()();

  TextColumn get operatorId => text().references(
    LogisticsOperators,
    #id,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyntheticPackages extends Table {
  TextColumn get id => text()();

  TextColumn get deliveryRunId =>
      text().references(DeliveryRuns, #id, onDelete: KeyAction.cascade)();

  TextColumn get status => text().customConstraint(
    "NOT NULL DEFAULT 'pending' "
    "CHECK (status IN ('pending', 'delivered', 'failed'))",
  )();

  TextColumn get externalReference => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DeliveryEvents extends Table {
  TextColumn get id => text()();

  TextColumn get packageId =>
      text().references(SyntheticPackages, #id, onDelete: KeyAction.cascade)();

  TextColumn get eventType => text()();

  DateTimeColumn get occurredAt => dateTime()();

  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [LogisticsOperators, DeliveryRuns, SyntheticPackages, DeliveryEvents],
)
class RiderBizDatabase extends _$RiderBizDatabase {
  RiderBizDatabase() : super(driftDatabase(name: 'riderbiz'));

  RiderBizDatabase.forTesting(super.executor);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          syntheticPackages,
          syntheticPackages.externalReference,
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  @override
  int get schemaVersion => 2;
}
