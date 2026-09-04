import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/features/operator_identification/operator_identifier.dart';

void main() {
  const identifier = OperatorIdentifier();

  final profiles = [
    OperatorLabelProfile(
      operatorId: 'OP-ALFA',
      markers: ['LOGISTICA ALFA', 'ALF-EXP', 'CENTRO ALFA'],
    ),
    OperatorLabelProfile(
      operatorId: 'OP-BETA',
      markers: ['TRANSPORTES BETA', 'BET-PACK', 'RED BETA'],
    ),
    OperatorLabelProfile(
      operatorId: 'OP-GAMMA',
      markers: ['DISTRIBUCION GAMMA', 'GAM-DEL', 'GRUPO GAMMA'],
    ),
  ];

  group('OperatorIdentifier', () {
    test('identifies Operador Alfa from a synthetic label', () {
      final result = identifier.identify(
        labelText: '''
          Logística Alfa
          Código de expedición: ALF-EXP-0001
          Paquete sintético
        ''',
        profiles: profiles,
      );

      expect(result.status, OperatorIdentificationStatus.identified);
      expect(result.operatorId, 'OP-ALFA');
      expect(result.confidence, closeTo(2 / 3, 0.001));
      expect(result.suggestedOperatorId, isNull);
    });

    test('identifies Operador Beta from a synthetic label', () {
      final result = identifier.identify(
        labelText: '''
          TRANSPORTES BETA
          Nodo de clasificación RED BETA
          Referencia sintética BET-0002
        ''',
        profiles: profiles,
      );

      expect(result.status, OperatorIdentificationStatus.identified);
      expect(result.operatorId, 'OP-BETA');
      expect(result.confidence, closeTo(2 / 3, 0.001));
    });

    test('identifies Operador Gamma from a synthetic label', () {
      final result = identifier.identify(
        labelText: '''
          Distribución Gamma
          Servicio GAM-DEL
          Etiqueta de prueba
        ''',
        profiles: profiles,
      );

      expect(result.status, OperatorIdentificationStatus.identified);
      expect(result.operatorId, 'OP-GAMMA');
      expect(result.confidence, closeTo(2 / 3, 0.001));
    });

    test('returns unknown when no synthetic marker matches', () {
      final result = identifier.identify(
        labelText: '''
          OPERADOR NO REGISTRADO
          REFERENCIA DESCONOCIDA
        ''',
        profiles: profiles,
      );

      expect(result.status, OperatorIdentificationStatus.unknown);
      expect(result.operatorId, isNull);
      expect(result.suggestedOperatorId, isNull);
      expect(result.confidence, 0);
    });

    test('suggests manual selection when confidence is insufficient', () {
      final result = identifier.identify(
        labelText: 'Envío procesado por Centro Alfa',
        profiles: profiles,
      );

      expect(result.status, OperatorIdentificationStatus.lowConfidence);
      expect(result.operatorId, isNull);
      expect(result.suggestedOperatorId, 'OP-ALFA');
      expect(result.confidence, closeTo(1 / 3, 0.001));
    });

    test('does not select an operator when candidates are tied', () {
      final result = identifier.identify(
        labelText: '''
          LOGISTICA ALFA
          TRANSPORTES BETA
          Etiqueta sintética ambigua
        ''',
        profiles: profiles,
      );

      expect(result.status, OperatorIdentificationStatus.lowConfidence);
      expect(result.operatorId, isNull);
      expect(result.suggestedOperatorId, isNull);
      expect(result.confidence, closeTo(1 / 3, 0.001));
    });

    test('normalizes accents, case and repeated separators', () {
      final result = identifier.identify(
        labelText: '''
          distribución---gamma
          GRUPO   GAMMA
        ''',
        profiles: profiles,
      );

      expect(result.status, OperatorIdentificationStatus.identified);
      expect(result.operatorId, 'OP-GAMMA');
      expect(result.confidence, closeTo(2 / 3, 0.001));
    });

    test('returns unknown when label text is empty', () {
      final result = identifier.identify(labelText: '   ', profiles: profiles);

      expect(result.status, OperatorIdentificationStatus.unknown);
      expect(result.operatorId, isNull);
      expect(result.confidence, 0);
    });
  });
}
