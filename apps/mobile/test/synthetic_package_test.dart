import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/main.dart';

void main() {
  group('SyntheticPackage', () {
    test('serializa y recupera un paquete sintético', () {
      const original = SyntheticPackage(
        id: 'RB-SYN-0001',
        status: DeliveryStatus.pending,
      );

      final encoded = jsonEncode(original.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = SyntheticPackage.fromJson(decoded);

      expect(restored.id, original.id);
      expect(restored.status, DeliveryStatus.pending);
    });

    test('permite cambiar el estado a entregado', () {
      const package = SyntheticPackage(
        id: 'RB-SYN-0001',
        status: DeliveryStatus.pending,
      );

      final delivered = package.copyWith(status: DeliveryStatus.delivered);

      expect(delivered.id, package.id);
      expect(delivered.status, DeliveryStatus.delivered);
    });
  });
}
