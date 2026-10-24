import 'package:flutter/material.dart';

import 'route_optimization_models.dart';
import 'route_optimization_port.dart';
import 'vroom_route_optimization_adapter.dart';
import 'synthetic_route_delivery_service.dart';

import 'dart:async';

import '../../data/local/riderbiz_database.dart' show RiderBizDatabase;
import 'accepted_route_store.dart';
import 'route_plan_store.dart';

class RouteValidationScreen extends StatefulWidget {
  const RouteValidationScreen({
    super.key,
    this.database,
    this.adapter,
    this.databaseName = 'riderbiz',
  });

  final String databaseName;

  final RiderBizDatabase? database;
  final RouteOptimizationPort? adapter;

  @override
  State<RouteValidationScreen> createState() => _RouteValidationScreenState();
}

class _RouteValidationScreenState extends State<RouteValidationScreen> {
  static const _routeId = 'ROUTE-TABLET-SYNTHETIC';

  late final RiderBizDatabase _database;
  late final AcceptedRouteStore _store;
  late final RouteOptimizationPort _adapter;
  late final SyntheticRouteDeliveryService _deliveries;
  Map<String, String> _deliveryStatuses = {};
  String? _confirmingStopId;
  String? _deliveryError;

  AcceptedRouteSnapshot? _accepted;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _storageReady = false;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    _database = widget.database ?? RiderBizDatabase(name: widget.databaseName);
    _store = AcceptedRouteStore(_database);
    _deliveries = SyntheticRouteDeliveryService(_database);
    _adapter =
        widget.adapter ??
        VroomRouteOptimizationAdapter(
          endpoint: Uri.parse('http://127.0.0.1:3000/'),
        );
    unawaited(_loadAccepted());
  }

  Future<void> _loadAccepted() async {
    setState(() {
      _isLoading = true;
      _storageReady = false;
      _storageError = null;
    });

    try {
      final accepted = await _store.load(_routeId);
      await _deliveries.prepare();
      await _deliveries.ensureRoutePlan();
      final progress = await _deliveries.loadProgress();
      if (!mounted) return;

      setState(() {
        _accepted = accepted;
        _deliveryStatuses = {
          for (final entry in progress.entries) entry.key: entry.value.status,
        };
        _deliveryError = null;
        _storageReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storageError =
            'No se pudo recuperar la ruta guardada. Intenta cargarla de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelivery(String stopId) async {
    if (_isBusy ||
        _isLoading ||
        _isSaving ||
        !_storageReady ||
        _confirmingStopId != null ||
        _deliveryStatuses[stopId] != 'pending' ||
        !(_accepted?.stopOrder.contains(stopId) ?? false)) {
      return;
    }

    setState(() {
      _confirmingStopId = stopId;
      _deliveryError = null;
    });

    try {
      final delivered = await _deliveries.confirmStop(
        stopId: stopId,
        deliveredAt: DateTime.now().toUtc(),
      );

      if (!mounted) return;
      setState(() {
        _deliveryStatuses = {..._deliveryStatuses, stopId: delivered.status};
        _candidate = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deliveryError =
            'No se pudo confirmar la entrega. Vuelve a cargar el progreso '
            'antes de intentarlo de nuevo.';
        _storageReady = false;
      });
    } finally {
      if (mounted) {
        setState(() => _confirmingStopId = null);
      }
    }
  }

  Future<void> _acceptProposal() async {
    final candidate = _candidate;
    if (candidate == null ||
        _isBusy ||
        _isLoading ||
        _isSaving ||
        _confirmingStopId != null ||
        !_storageReady) {
      return;
    }

    final acceptedAt = DateTime.now().toUtc();

    setState(() {
      _isSaving = true;
      _storageError = null;
    });

    try {
      await _store.save(
        routeId: _routeId,
        candidate: candidate,
        acceptedAt: acceptedAt,
      );

      if (!mounted) return;
      setState(() {
        _accepted = AcceptedRouteSnapshot(
          routeId: _routeId,
          stopOrder: candidate.stopOrder,
          metrics: candidate.metrics,
          acceptedAt: acceptedAt,
        );
        _candidate = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storageError =
            'No se pudo guardar la propuesta. No se confirmó su aceptación.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  RouteOptimizationCancellationSignal? _signal;
  RouteCandidate? _candidate;
  String? _error;
  bool _isBusy = false;

  Future<RouteOptimizationRequest> _request() async {
    final plan = await RoutePlanStore(_database).load(_routeId);
    if (plan == null) {
      throw StateError('The synthetic route definition is missing.');
    }

    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: plan.id,
        currentOrder: _accepted?.stopOrder ?? plan.currentOrder,
        stops: plan.stops,
        tasks: plan.tasks,
        walkingClusters: plan.walkingClusters,
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.now().toUtc(),
      timeout: const Duration(seconds: 40),
      reoptimizePendingOnly: true,
    );
  }

  Future<void> _calculate() async {
    if (_isBusy ||
        _isLoading ||
        _isSaving ||
        !_storageReady ||
        _confirmingStopId != null) {
      return;
    }

    if (_deliveryStatuses.length ==
            SyntheticRouteDeliveryService.packageIdsByStop.length &&
        _deliveryStatuses.values.every((status) => status == 'delivered')) {
      return;
    }

    final signal = RouteOptimizationCancellationSignal();
    _signal = signal;

    setState(() {
      _isBusy = true;
      _candidate = null;
      _error = null;
    });

    try {
      final request = await _request();
      if (!mounted) return;
      signal.throwIfCancelled();
      final candidate = await _adapter.optimize(
        request,
        cancellationSignal: signal,
      );

      if (!mounted) return;
      setState(() => _candidate = candidate);
    } on RouteOptimizationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = switch (failure.type) {
          RouteOptimizationFailureType.timeout =>
            'El cálculo superó el tiempo disponible.',
          RouteOptimizationFailureType.cancelled => 'Cálculo cancelado.',
          RouteOptimizationFailureType.unavailable =>
            'No se pudo conectar. Comprueba el USB y el servicio local.',
          RouteOptimizationFailureType.incompleteSolution =>
            'No se pudieron incluir todas las entregas.',
          _ => 'No se obtuvo una propuesta válida.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Se produjo un error al calcular la ruta.');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  void dispose() {
    _signal?.cancel();
    if (widget.database == null) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidate = _candidate;
    final accepted = _accepted;
    final allDelivered =
        _storageReady &&
        _deliveryStatuses.length ==
            SyntheticRouteDeliveryService.packageIdsByStop.length &&
        _deliveryStatuses.values.every((status) => status == 'delivered');

    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de ruta sintética')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Dos entregas en Pamplona',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Datos sintéticos. Cada entrega tiene dos minutos de servicio. '
            'Se calculan únicamente las entregas pendientes desde un origen '
            'sintético fijo. No se utiliza la ubicación del dispositivo.',
          ),
          const SizedBox(height: 16),
          const Text('Orden inicial: STOP-A → STOP-B'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed:
                _isBusy ||
                    _isLoading ||
                    _isSaving ||
                    !_storageReady ||
                    _confirmingStopId != null ||
                    allDelivered
                ? null
                : _calculate,
            child: Text(_isBusy ? 'Calculando…' : 'Calcular propuesta'),
          ),
          if (allDelivered) ...[
            const SizedBox(height: 16),
            const Text('No quedan entregas pendientes.'),
          ],
          if (_isBusy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 24),
            Text(_error!, semanticsLabel: 'Error: $_error'),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Text('Cargando ruta aceptada…'),
          ],
          if (_storageError != null) ...[
            const SizedBox(height: 16),
            Text(_storageError!),
            if (!_storageReady)
              TextButton(
                onPressed: _isLoading ? null : _loadAccepted,
                child: const Text('Volver a cargar ruta guardada'),
              ),
          ],
          if (_deliveryError != null) ...[
            const SizedBox(height: 16),
            Text(_deliveryError!),
            TextButton(
              onPressed: _isLoading ? null : _loadAccepted,
              child: const Text('Volver a cargar progreso'),
            ),
          ],
          if (accepted != null) ...[
            const SizedBox(height: 24),
            Text(
              'Ruta aceptada y guardada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Orden aceptado: ${accepted.stopOrder.join(' → ')}'),
            Text('Distancia aceptada: ${accepted.metrics.distanceMeters} m'),
            Text(
              'Total aceptado: ${accepted.metrics.totalDuration.inSeconds} s',
            ),
            Text('Aceptada: ${accepted.acceptedAt.toLocal()}'),
            const Text(
              'Esta ruta se conserva hasta que aceptes otra propuesta.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Entregas sintéticas · tarifa ficticia de 0,01 € por paquete.',
            ),
            for (final stopId in accepted.stopOrder)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stopId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _deliveryStatuses[stopId] == 'delivered'
                            ? 'Estado: Entregado'
                            : _deliveryStatuses[stopId] == 'pending'
                            ? 'Estado: Pendiente'
                            : 'Estado: No disponible',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed:
                            _deliveryStatuses[stopId] != 'pending' ||
                                !_storageReady ||
                                _isBusy ||
                                _isLoading ||
                                _isSaving ||
                                _confirmingStopId != null
                            ? null
                            : () => _confirmDelivery(stopId),
                        child: Text(
                          _confirmingStopId == stopId
                              ? 'Confirmando…'
                              : 'Confirmar entrega $stopId',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          if (candidate != null) ...[
            const SizedBox(height: 24),
            Text(
              'Propuesta calculada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Orden: ${candidate.stopOrder.join(' → ')}'),
            Text('Distancia: ${candidate.metrics.distanceMeters} m'),
            Text('Conducción: ${candidate.metrics.travelDuration.inSeconds} s'),
            Text('Servicio: ${candidate.metrics.serviceDuration.inSeconds} s'),
            Text('Total: ${candidate.metrics.totalDuration.inSeconds} s'),
            const SizedBox(height: 16),
            const Text(
              'Estimaciones sin tráfico en tiempo real. '
              'Solo se guarda al aceptar. No modifica el paquete local.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _isSaving || !_storageReady || _confirmingStopId != null
                  ? null
                  : _acceptProposal,
              child: Text(_isSaving ? 'Guardando…' : 'Aceptar propuesta'),
            ),
          ],
        ],
      ),
    );
  }
}
