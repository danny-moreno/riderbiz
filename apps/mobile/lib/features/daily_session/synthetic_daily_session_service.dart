import 'package:drift/drift.dart' show Value;

import '../../data/local/riderbiz_database.dart';
import '../delivery_accounting/delivery_accounting_service.dart';
import '../operator_settings/operator_tariff_service.dart';
import '../route_optimization/accepted_route_store.dart';
import '../route_optimization/route_optimization_models.dart';
import '../route_optimization/route_plan_store.dart';
import 'daily_delivery_scenario_factory.dart';

class SyntheticDailySessionService {
  const SyntheticDailySessionService(this.database);

  final RiderBizDatabase database;

  static const databaseName = 'riderbiz_daily_session_validation';
  static const routeId = 'DAILY-150-60';
  static const runId = 'RUN-DAILY-SESSION';
  static const operatorId = 'OP-DAILY-SESSION';

  Future<void> prepare() {
    return database.transaction(() async {
      final existing = await RoutePlanStore(database).load(routeId);
      if (existing != null) return;

      final run = await (database.select(
        database.deliveryRuns,
      )..where((row) => row.id.equals(runId))).getSingleOrNull();
      if (run != null) {
        throw StateError('Existing daily session has no route definition.');
      }

      final createdAt = DateTime.utc(2026, 10, 24, 8);
      final plan = const DailyDeliveryScenarioFactory()
          .create(packageCount: 150, stopCount: 60)
          .plan;

      await OperatorTariffService(database).createInitialConfiguration(
        operatorId: operatorId,
        operatorName: 'Operador sintético de jornada',
        tariffId: 'TAR-DAILY-SESSION',
        unitPriceMinor: 120,
        currency: 'EUR',
        validFrom: createdAt,
        createdAt: createdAt,
      );
      await database
          .into(database.deliveryRuns)
          .insert(
            DeliveryRunsCompanion.insert(
              id: runId,
              operatorId: operatorId,
              startedAt: createdAt,
            ),
          );
      await database.batch((batch) {
        batch.insertAll(database.syntheticPackages, [
          for (final task in plan.tasks)
            SyntheticPackagesCompanion.insert(
              id: task.id,
              deliveryRunId: runId,
              identifiedOperatorId: const Value(operatorId),
              identificationStatus: const Value('identified'),
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
        ]);
      });
      await RoutePlanStore(database)
          .save(deliveryRunId: runId, plan: plan, updatedAt: createdAt);
    });
  }

  Future<RoutePlan> loadPlan() async {
    final plan = await RoutePlanStore(database).load(routeId);
    if (plan == null) throw StateError('Daily session is not prepared.');
    return plan;
  }

  Future<void> useUsualOrder() {
    return database.transaction(() async {
      final plan = await loadPlan();
      final order = plan.currentOrder;
      final stopIds = plan.stops.map((stop) => stop.id).toSet();

      if (order.isEmpty ||
          order.toSet().length != order.length ||
          order.length != stopIds.length ||
          !order.every(stopIds.contains)) {
        throw StateError('The usual order must contain every stop once.');
      }

      await AcceptedRouteStore(database).saveUsualOrder(
        routeId: routeId,
        stopOrder: order,
        acceptedAt: DateTime.now().toUtc(),
      );
    });
  }

  Future<void> confirmPackage(String packageId) {
    return database.transaction(() async {
      final plan = await loadPlan();
      final matching = plan.tasks.where((task) => task.id == packageId);
      if (matching.length != 1) {
        throw StateError('Package does not belong to the daily route.');
      }
      final task = matching.single;
      if (task.status != RouteTaskStatus.pending) {
        throw StateError('Package is not pending.');
      }

      final accepted = await AcceptedRouteStore(database)
          .loadSelection(routeId);
      if (accepted == null || !accepted.stopOrder.contains(task.stopId)) {
        throw StateError('Accept a route containing this stop first.');
      }

      await DeliveryAccountingService(database).confirmDelivery(
        packageId: packageId,
        eventId: 'DAILY-DELIVERED-$packageId',
        deliveredAt: DateTime.now().toUtc(),
      );
    });
  }
}
