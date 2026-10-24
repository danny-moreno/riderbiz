import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/dashboard/dashboard_screen.dart';
import 'package:riderbiz_mobile/features/daily_session/synthetic_daily_session_service.dart';
import 'package:riderbiz_mobile/features/delivery_accounting/delivery_accounting_service.dart';
import 'package:riderbiz_mobile/features/route_optimization/synthetic_route_delivery_service.dart';
import 'package:riderbiz_mobile/theme/riderbiz_theme.dart';

void main() {
  for (final width in [390.0, 1000.0]) {
    testWidgets(
      'loads progress and refreshes after navigation at width $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final database = RiderBizDatabase.forTesting(NativeDatabase.memory());
        final accounting = DeliveryAccountingService(database);

        try {
          await tester.runAsync(() async {
            await SyntheticRouteDeliveryService(database).prepare();
            await SyntheticDailySessionService(database).prepare();
            await accounting.confirmDelivery(
              packageId: 'PACKAGE-DAILY-001',
              eventId: 'DASHBOARD-EVENT-A',
              deliveredAt: DateTime.utc(2026, 10, 24, 10),
            );
          });

          await tester.pumpWidget(
            MaterialApp(
              theme: riderBizTheme(),
              home: DashboardScreen(
                database: database,
                validationBuilder: (_) => const Scaffold(
                  appBar: null,
                  body: Center(child: Text('Pantalla de prueba')),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('de 150'), findsOneWidget);
          expect(find.text('1'), findsOneWidget);
          expect(find.text('1,20 €'), findsOneWidget);
          expect(find.text('PACKAGE-DAILY-002'), findsOneWidget);
          expect(tester.takeException(), isNull);

          final validation = find.widgetWithText(
            OutlinedButton,
            'Validaciones locales',
          );
          await tester.ensureVisible(validation);
          await tester.tap(validation);
          await tester.pumpAndSettle();
          expect(find.text('Pantalla de prueba'), findsOneWidget);

          await tester.runAsync(() async {
            await accounting.confirmDelivery(
              packageId: 'PACKAGE-DAILY-002',
              eventId: 'DASHBOARD-EVENT-B',
              deliveredAt: DateTime.utc(2026, 10, 24, 11),
            );
          });

          tester.state<NavigatorState>(find.byType(Navigator)).pop();
          await tester.pumpAndSettle();

          expect(find.text('2'), findsOneWidget);
          expect(find.text('2,40 €'), findsOneWidget);
          expect(find.text('PACKAGE-DAILY-003'), findsOneWidget);
          expect(find.text('PACKAGE-DAILY-002'), findsNothing);
          expect(tester.takeException(), isNull);

          final events = await tester.runAsync(
            () => database.select(database.deliveryEvents).get(),
          );
          expect(events, hasLength(2));
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.runAsync(() => database.close());
        }
      },
    );
  }

  testWidgets('shows an empty state without preparing packages', (
    tester,
  ) async {
    final database = RiderBizDatabase.forTesting(NativeDatabase.memory());

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: riderBizTheme(),
          home: DashboardScreen(
            database: database,
            validationBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('de 0'), findsOneWidget);
      expect(find.text('0,00 €'), findsOneWidget);
      expect(find.text('Sin paquetes preparados'), findsOneWidget);

      final packages = await tester.runAsync(
        () => database.select(database.syntheticPackages).get(),
      );
      expect(packages, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => database.close());
    }
  });
}
