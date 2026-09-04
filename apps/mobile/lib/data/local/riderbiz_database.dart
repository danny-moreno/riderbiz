import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'riderbiz_database.g.dart';

class LogisticsOperators extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OperatorTariffs extends Table {
  TextColumn get id => text()();

  TextColumn get operatorId => text().references(
    LogisticsOperators,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get version => integer()();

  IntColumn get unitPriceMinor =>
      integer().customConstraint('NOT NULL CHECK (unit_price_minor >= 0)')();

  TextColumn get currency => text().withLength(min: 3, max: 3)();

  DateTimeColumn get validFrom => dateTime()();

  DateTimeColumn get validUntil => dateTime().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {operatorId, version},
  ];
}

class OperatorLabelProfiles extends Table {
  TextColumn get id => text()();

  TextColumn get operatorId =>
      text().references(LogisticsOperators, #id, onDelete: KeyAction.cascade)();

  TextColumn get marker => text()();

  IntColumn get priority => integer().withDefault(const Constant(0))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

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

  TextColumn get identifiedOperatorId => text().nullable().references(
    LogisticsOperators,
    #id,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get identificationStatus => text().customConstraint(
    "NOT NULL DEFAULT 'unknown' "
    "CHECK (identification_status IN "
    "('identified', 'low_confidence', 'unknown', 'manual'))",
  )();

  RealColumn get identificationConfidence => real().nullable()();

  TextColumn get tariffId => text().nullable().references(
    OperatorTariffs,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get unitPriceMinorSnapshot => integer().nullable()();

  TextColumn get currencySnapshot =>
      text().withLength(min: 3, max: 3).nullable()();

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
  tables: [
    LogisticsOperators,
    OperatorTariffs,
    OperatorLabelProfiles,
    DeliveryRuns,
    SyntheticPackages,
    DeliveryEvents,
  ],
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

      if (from < 3) {
        await migrator.addColumn(
          logisticsOperators,
          logisticsOperators.isActive,
        );

        await migrator.createTable(operatorTariffs);
        await migrator.createTable(operatorLabelProfiles);

        await migrator.addColumn(
          syntheticPackages,
          syntheticPackages.identifiedOperatorId,
        );
        await migrator.addColumn(
          syntheticPackages,
          syntheticPackages.identificationStatus,
        );
        await migrator.addColumn(
          syntheticPackages,
          syntheticPackages.identificationConfidence,
        );
        await migrator.addColumn(syntheticPackages, syntheticPackages.tariffId);
        await migrator.addColumn(
          syntheticPackages,
          syntheticPackages.unitPriceMinorSnapshot,
        );
        await migrator.addColumn(
          syntheticPackages,
          syntheticPackages.currencySnapshot,
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  @override
  int get schemaVersion => 3;
}
