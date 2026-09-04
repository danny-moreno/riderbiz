import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart';
import 'package:riderbiz_mobile/features/operator_identification/operator_identification_service.dart';
import 'package:riderbiz_mobile/features/operator_identification/operator_identifier.dart';

void main() {
  late RiderBizDatabase database;
  late OperatorIdentificationService service;

  final createdAt = DateTime.utc(2026, 9, 4, 8);

  setUp(() async {
    database = RiderBizDatabase.forTesting(NativeDatabase.memory());
    service = OperatorIdentificationService(database);

    for (final operator in const [
      ('OP-ALFA', 'Operador Alfa'),
      ('OP-BETA', 'Operador Beta'),
      ('OP-GAMMA', 'Operador Gamma'),
    ]) {
      await database
          .into(database.logisticsOperators)
          .insert(
            LogisticsOperatorsCompanion.insert(
              id: operator.$1,
              name: operator.$2,
              createdAt: createdAt,
            ),
          );
    }

    final profiles = [
      ('PROFILE-ALFA-1', 'OP-ALFA', 'LOGISTICA ALFA'),
      ('PROFILE-ALFA-2', 'OP-ALFA', 'ALF-EXP'),
      ('PROFILE-ALFA-3', 'OP-ALFA', 'CENTRO ALFA'),
      ('PROFILE-BETA-1', 'OP-BETA', 'TRANSPORTES BETA'),
      ('PROFILE-BETA-2', 'OP-BETA', 'BET-PACK'),
      ('PROFILE-BETA-3', 'OP-BETA', 'RED BETA'),
      ('PROFILE-GAMMA-1', 'OP-GAMMA', 'DISTRIBUCION GAMMA'),
      ('PROFILE-GAMMA-2', 'OP-GAMMA', 'GAM-DEL'),
      ('PROFILE-GAMMA-3', 'OP-GAMMA', 'GRUPO GAMMA'),
    ];

    for (final profile in profiles) {
      await database
          .into(database.operatorLabelProfiles)
          .insert(
            OperatorLabelProfilesCompanion.insert(
              id: profile.$1,
              operatorId: profile.$2,
              marker: profile.$3,
              createdAt: createdAt,
            ),
          );
    }

    await database
        .into(database.deliveryRuns)
        .insert(
          DeliveryRunsCompanion.insert(
            id: 'RUN-SYN-001',
            operatorId: 'OP-ALFA',
            startedAt: createdAt,
          ),
        );

    await database
        .into(database.syntheticPackages)
        .insert(
          SyntheticPackagesCompanion.insert(
            id: 'RB-SYN-001',
            deliveryRunId: 'RUN-SYN-001',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  Future<SyntheticPackage> storedPackage() {
    return database.select(database.syntheticPackages).getSingle();
  }

  test('loads active profiles and stores automatic identification', () async {
    final result = await service.identifyAndStore(
      packageId: 'RB-SYN-001',
      labelText: '''
        LOGÍSTICA ALFA
        Código sintético ALF-EXP-0001
      ''',
      identifiedAt: DateTime.utc(2026, 9, 4, 9),
    );

    final package = await storedPackage();

    expect(result.status, OperatorIdentificationStatus.identified);
    expect(result.operatorId, 'OP-ALFA');

    expect(package.identifiedOperatorId, 'OP-ALFA');
    expect(package.identificationStatus, 'identified');
    expect(package.identificationConfidence, closeTo(2 / 3, 0.001));
    expect(package.externalReference, equals(null));
  });

  test('stores unknown without assigning a false operator', () async {
    final result = await service.identifyAndStore(
      packageId: 'RB-SYN-001',
      labelText: '''
        OPERADOR NO REGISTRADO
        MODELO DE ETIQUETA DESCONOCIDO
      ''',
    );

    final package = await storedPackage();

    expect(result.status, OperatorIdentificationStatus.unknown);
    expect(result.operatorId, equals(null));
    expect(package.identifiedOperatorId, equals(null));
    expect(package.identificationStatus, 'unknown');
    expect(package.identificationConfidence, 0);
  });

  test('stores low confidence without automatic assignment', () async {
    final result = await service.identifyAndStore(
      packageId: 'RB-SYN-001',
      labelText: 'Paquete procesado en Centro Alfa',
    );

    final package = await storedPackage();

    expect(result.status, OperatorIdentificationStatus.lowConfidence);
    expect(result.suggestedOperatorId, 'OP-ALFA');
    expect(package.identifiedOperatorId, equals(null));
    expect(package.identificationStatus, 'low_confidence');
    expect(package.identificationConfidence, closeTo(1 / 3, 0.001));
  });

  test('allows manual selection of an active operator', () async {
    await service.selectManually(
      packageId: 'RB-SYN-001',
      operatorId: 'OP-BETA',
      selectedAt: DateTime.utc(2026, 9, 4, 9),
    );

    final package = await storedPackage();

    expect(package.identifiedOperatorId, 'OP-BETA');
    expect(package.identificationStatus, 'manual');
    expect(package.identificationConfidence, equals(null));
  });

  test('ignores profiles belonging to an inactive operator', () async {
    await (database.update(database.logisticsOperators)
          ..where((operator) => operator.id.equals('OP-ALFA')))
        .write(const LogisticsOperatorsCompanion(isActive: Value(false)));

    final result = await service.identifyAndStore(
      packageId: 'RB-SYN-001',
      labelText: '''
        LOGISTICA ALFA
        ALF-EXP-0001
      ''',
    );

    expect(result.status, OperatorIdentificationStatus.unknown);
    expect((await storedPackage()).identifiedOperatorId, equals(null));
  });

  test('prevents changing the operator after delivery', () async {
    await (database.update(database.syntheticPackages))
        .write(const SyntheticPackagesCompanion(status: Value('delivered')));

    await expectLater(
      service.selectManually(packageId: 'RB-SYN-001', operatorId: 'OP-BETA'),
      throwsA(isA<StateError>()),
    );

    await expectLater(
      service.identifyAndStore(
        packageId: 'RB-SYN-001',
        labelText: 'TRANSPORTES BETA BET-PACK',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
