import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riderbiz_mobile/data/local/riderbiz_database.dart'
    show RiderBizDatabase;
import 'package:riderbiz_mobile/features/daily_session/daily_session_screen.dart';
import 'package:riderbiz_mobile/features/daily_session/synthetic_daily_session_service.dart';
import 'package:riderbiz_mobile/features/route_optimization/accepted_route_store.dart';
import 'package:riderbiz_mobile/features/route_optimization/route_optimization_models.dart';

import 'daily_session_screen_test.dart' show DailyScreenAdapter;

void main() {
  for (final operation in ['route', 'delivery']) {
    testWidgets('recovers screen after failed $operation save', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final db = RiderBizDatabase.forTesting(NativeDatabase.memory());
      final adapter = DailyScreenAdapter();

      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            home: DailySessionScreen(database: db, adapter: adapter),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> header() async {
        await tester.scrollUntilVisible(
          find.text('Calcular pendientes'),
          -250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      Future<void> performAction() async {
        if (operation == 'route') {
          await tester.tap(find.text('Calcular pendientes'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Aceptar propuesta'));
          await tester.tap(find.text('Aceptar propuesta'));
        } else {
          await tester.ensureVisible(find.text('STOP-DAILY-001'));
          await tester.tap(find.text('STOP-DAILY-001'));
          await tester.pumpAndSettle();
          final confirm = find.byKey(
            const ValueKey('confirm-PACKAGE-DAILY-061'),
          );
          await tester.ensureVisible(confirm);
          await tester.tap(confirm);
        }
        await tester.pumpAndSettle();
        await header();
      }

      try {
        final service = SyntheticDailySessionService(db);
        await tester.runAsync(() async {
          await service.prepare();
          final plan = await service.loadPlan();
          await AcceptedRouteStore(db).save(
            routeId: plan.id,
            candidate: RouteCandidate(
              stopOrder: plan.currentOrder,
              vehicleLegs: const [],
              metrics: RouteMetrics(
                distanceMeters: 8000,
                travelDuration: const Duration(minutes: 25),
                serviceDuration: const Duration(minutes: 150),
                calculationDuration: Duration.zero,
              ),
              explanation: const OptimizationExplanation(
                summary: 'Saved baseline for screen failure test.',
              ),
            ),
            acceptedAt: DateTime.utc(2026, 10, 26, 8),
          );
          await service.confirmPackage('PACKAGE-DAILY-001');
        });

        final packagesBefore = await tester.runAsync(
          () => db.select(db.syntheticPackages).get(),
        );
        final eventsBefore = await tester.runAsync(
          () => db.select(db.deliveryEvents).get(),
        );
        final routesBefore = await tester.runAsync(
          () => db.select(db.acceptedRouteSnapshots).get(),
        );

        final trigger = operation == 'route'
            ? '''
              CREATE TRIGGER reject_screen_save
              BEFORE UPDATE ON accepted_route_snapshots
              BEGIN
                SELECT RAISE(ABORT, 'synthetic_screen_save_failure');
              END
              '''
            : '''
              CREATE TRIGGER reject_screen_save
              BEFORE INSERT ON delivery_events
              BEGIN
                SELECT RAISE(ABORT, 'synthetic_screen_save_failure');
              END
              ''';
        await tester.runAsync(() => db.customStatement(trigger));

        await open();
        await performAction();

        expect(
          find.text(
            operation == 'route'
                ? 'No se pudo verificar la ruta guardada. Vuelve a abrir.'
                : 'No se pudo verificar la entrega. Vuelve a abrir la jornada.',
          ),
          findsOneWidget,
        );
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Calcular pendientes'),
              )
              .onPressed,
          isNull,
        );

        if (operation == 'route') {
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Aceptar propuesta'),
                )
                .onPressed,
            isNull,
          );
        } else {
          final confirm = find.byKey(
            const ValueKey('confirm-PACKAGE-DAILY-061'),
          );
          await tester.ensureVisible(confirm);
          expect(tester.widget<IconButton>(confirm).onPressed, isNull);
        }

        expect(
          await tester.runAsync(() => db.select(db.syntheticPackages).get()),
          packagesBefore,
        );
        expect(
          await tester.runAsync(() => db.select(db.deliveryEvents).get()),
          eventsBefore,
        );
        expect(
          await tester.runAsync(
            () => db.select(db.acceptedRouteSnapshots).get(),
          ),
          routesBefore,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER reject_screen_save'),
        );
        final callsBeforeReopen = adapter.requests.length;
        await open();

        expect(adapter.requests, hasLength(callsBeforeReopen));
        expect(
          find.text('Entregados: 1 / 150 · Pendientes: 149'),
          findsOneWidget,
        );
        expect(find.text('Ruta aceptada: 60 paradas · 8000 m'), findsOneWidget);
        expect(find.text('Aceptar propuesta'), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Calcular pendientes'),
              )
              .onPressed,
          isNotNull,
        );

        await performAction();

        if (operation == 'route') {
          final saved = await tester.runAsync(
            () =>
                AcceptedRouteStore(db)
                    .load(SyntheticDailySessionService.routeId),
          );
          expect(saved!.metrics.distanceMeters, 7000);
          expect(
            await tester.runAsync(() => db.select(db.deliveryEvents).get()),
            eventsBefore,
          );
          expect(
            await tester.runAsync(() => db.select(db.syntheticPackages).get()),
            packagesBefore,
          );
        } else {
          expect(
            find.text('Entregados: 2 / 150 · Pendientes: 148'),
            findsOneWidget,
          );
          final events = await tester.runAsync(
            () => db.select(db.deliveryEvents).get(),
          );
          expect(events, hasLength(2));
          expect(
            events!.where((event) => event.packageId == 'PACKAGE-DAILY-061'),
            hasLength(1),
          );
          expect(
            await tester.runAsync(
              () => db.select(db.acceptedRouteSnapshots).get(),
            ),
            routesBefore,
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(() => db.close());
      }
    });
  }
}
