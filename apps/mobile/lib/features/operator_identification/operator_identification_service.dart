import 'package:drift/drift.dart';

import '../../data/local/riderbiz_database.dart';
import 'operator_identifier.dart' as recognition;

class OperatorIdentificationService {
  OperatorIdentificationService(
    this.database, {
    recognition.OperatorIdentifier? identifier,
  }) : identifier = identifier ?? const recognition.OperatorIdentifier();

  final RiderBizDatabase database;
  final recognition.OperatorIdentifier identifier;

  Future<recognition.OperatorIdentificationResult> identifyAndStore({
    required String packageId,
    required String labelText,
    DateTime? identifiedAt,
  }) async {
    final normalizedPackageId = packageId.trim();

    if (normalizedPackageId.isEmpty) {
      throw ArgumentError.value(packageId, 'packageId');
    }

    final package = await (database.select(
      database.syntheticPackages,
    )..where((row) => row.id.equals(normalizedPackageId))).getSingleOrNull();

    if (package == null) {
      throw StateError('Synthetic package not found');
    }

    if (package.status == 'delivered') {
      throw StateError('Delivered package operator cannot be changed');
    }

    final activeOperators = await (database.select(
      database.logisticsOperators,
    )..where((operator) => operator.isActive.equals(true))).get();

    final activeOperatorIds = {
      for (final operator in activeOperators) operator.id,
    };

    final storedProfiles =
        await (database.select(database.operatorLabelProfiles)
              ..where((profile) => profile.isActive.equals(true))
              ..orderBy([(profile) => OrderingTerm.desc(profile.priority)]))
            .get();

    final markersByOperator = <String, List<String>>{};

    for (final profile in storedProfiles) {
      if (!activeOperatorIds.contains(profile.operatorId)) {
        continue;
      }

      markersByOperator
          .putIfAbsent(profile.operatorId, () => [])
          .add(profile.marker);
    }

    final profiles = markersByOperator.entries
        .map(
          (entry) => recognition.OperatorLabelProfile(
            operatorId: entry.key,
            markers: entry.value,
          ),
        )
        .toList(growable: false);

    final result = identifier.identify(
      labelText: labelText,
      profiles: profiles,
    );

    final timestamp = identifiedAt?.toUtc() ?? DateTime.now().toUtc();

    await (database.update(
      database.syntheticPackages,
    )..where((row) => row.id.equals(normalizedPackageId))).write(
      SyntheticPackagesCompanion(
        identifiedOperatorId: Value(result.operatorId),
        identificationStatus: Value(_databaseStatus(result.status)),
        identificationConfidence: Value(result.confidence),
        updatedAt: Value(timestamp),
        needsSync: const Value(true),
      ),
    );

    return result;
  }

  Future<void> selectManually({
    required String packageId,
    required String operatorId,
    DateTime? selectedAt,
  }) async {
    final normalizedPackageId = packageId.trim();
    final normalizedOperatorId = operatorId.trim();

    if (normalizedPackageId.isEmpty) {
      throw ArgumentError.value(packageId, 'packageId');
    }
    if (normalizedOperatorId.isEmpty) {
      throw ArgumentError.value(operatorId, 'operatorId');
    }

    await database.transaction(() async {
      final package = await (database.select(
        database.syntheticPackages,
      )..where((row) => row.id.equals(normalizedPackageId))).getSingleOrNull();

      if (package == null) {
        throw StateError('Synthetic package not found');
      }

      if (package.status == 'delivered') {
        throw StateError('Delivered package operator cannot be changed');
      }

      final operator =
          await (database.select(database.logisticsOperators)..where(
                (row) =>
                    row.id.equals(normalizedOperatorId) &
                    row.isActive.equals(true),
              ))
              .getSingleOrNull();

      if (operator == null) {
        throw StateError('Active logistics operator not found');
      }

      final timestamp = selectedAt?.toUtc() ?? DateTime.now().toUtc();

      await (database.update(
        database.syntheticPackages,
      )..where((row) => row.id.equals(normalizedPackageId))).write(
        SyntheticPackagesCompanion(
          identifiedOperatorId: Value(normalizedOperatorId),
          identificationStatus: const Value('manual'),
          identificationConfidence: const Value(null),
          updatedAt: Value(timestamp),
          needsSync: const Value(true),
        ),
      );
    });
  }

  String _databaseStatus(recognition.OperatorIdentificationStatus status) {
    return switch (status) {
      recognition.OperatorIdentificationStatus.identified => 'identified',
      recognition.OperatorIdentificationStatus.lowConfidence =>
        'low_confidence',
      recognition.OperatorIdentificationStatus.unknown => 'unknown',
      recognition.OperatorIdentificationStatus.manual => 'manual',
    };
  }
}
