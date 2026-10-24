import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/local/riderbiz_database.dart' show RiderBizDatabase;
import '../route_optimization/accepted_route_store.dart';
import '../route_optimization/route_optimization_models.dart';
import '../route_optimization/route_optimization_port.dart';
import '../route_optimization/vroom_route_optimization_adapter.dart';
import 'synthetic_daily_session_service.dart';

class DailySessionScreen extends StatefulWidget {
  const DailySessionScreen({this.database, this.adapter, super.key});

  final RiderBizDatabase? database;
  final RouteOptimizationPort? adapter;

  @override
  State<DailySessionScreen> createState() => _DailySessionScreenState();
}

class _DailySessionScreenState extends State<DailySessionScreen> {
  late final RiderBizDatabase _db;
  late final SyntheticDailySessionService _service;
  late final RouteOptimizationPort _adapter;
  RoutePlan? _plan;
  AcceptedRouteSnapshot? _accepted;
  RouteCandidate? _candidate;
  RouteOptimizationCancellationSignal? _signal;
  bool _busy = true;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _db =
        widget.database ??
        RiderBizDatabase(name: SyntheticDailySessionService.databaseName);
    _service = SyntheticDailySessionService(_db);
    _adapter =
        widget.adapter ??
        VroomRouteOptimizationAdapter(
          endpoint: Uri.parse('http://127.0.0.1:3000/'),
        );
    unawaited(_initialize());
  }

  Future<void> _reload() async {
    final plan = await _service.loadPlan();
    final accepted = await AcceptedRouteStore(_db).load(plan.id);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _accepted = accepted;
      _ready = true;
    });
  }

  Future<void> _initialize() async {
    try {
      await _service.prepare();
      await _reload();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo recuperar la jornada.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _calculate() async {
    if (_busy || !_ready) return;
    final signal = RouteOptimizationCancellationSignal();
    _signal = signal;
    setState(() {
      _busy = true;
      _candidate = null;
      _error = null;
    });
    try {
      await _reload();
      if (!mounted) return;
      signal.throwIfCancelled();
      final plan = _plan!;
      if (plan.pendingTasks.isEmpty) return;
      final candidate = await _adapter.optimize(
        RouteOptimizationRequest(
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
        ),
        cancellationSignal: signal,
      );
      if (mounted) setState(() => _candidate = candidate);
    } on RouteOptimizationFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = switch (failure.type) {
            RouteOptimizationFailureType.timeout =>
              'El cálculo superó el tiempo disponible.',
            RouteOptimizationFailureType.unavailable =>
              'No se pudo conectar con el servicio local.',
            RouteOptimizationFailureType.cancelled => 'Cálculo cancelado.',
            _ => 'No se obtuvo una propuesta válida.',
          };
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
          _error = 'No se pudo cargar o calcular la jornada. Vuelve a abrirla.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    final candidate = _candidate;
    if (_busy || !_ready || candidate == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AcceptedRouteStore(_db).save(
        routeId: SyntheticDailySessionService.routeId,
        candidate: candidate,
        acceptedAt: DateTime.now().toUtc(),
      );
      if (!mounted) return;
      setState(() => _candidate = null);
      await _reload();
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
          _error = 'No se pudo verificar la ruta guardada. Vuelve a abrir.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(String packageId) async {
    if (_busy || !_ready) return;
    setState(() {
      _busy = true;
      _candidate = null;
      _error = null;
    });
    try {
      await _service.confirmPackage(packageId);
      await _reload();
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
          _error =
              'No se pudo verificar la entrega. Vuelve a abrir la jornada.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _signal?.cancel();
    if (widget.database == null) unawaited(_db.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final candidate = _candidate;
    final tasksById = {
      if (plan != null)
        for (final task in plan.tasks) task.id: task,
    };
    final stopsById = {
      if (plan != null)
        for (final stop in plan.stops) stop.id: stop,
    };
    final order = <String>{
      ...?_accepted?.stopOrder,
      ...?plan?.currentOrder,
      ...stopsById.keys,
    }.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Jornada sintética')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: order.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Simulación de 150 paquetes · 60 paradas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Datos sintéticos. Origen fijo en Pamplona. '
                      'Servicio supuesto: 60 s por paquete. '
                      'Tarifa ficticia: 1,20 € por entrega.',
                    ),
                    if (plan != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Entregados: ${plan.tasks.length - plan.pendingTasks.length}'
                        ' / ${plan.tasks.length} · '
                        'Pendientes: ${plan.pendingTasks.length}',
                      ),
                    ],
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null) Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed:
                          _busy ||
                              !_ready ||
                              (plan?.pendingTasks.isEmpty ?? true)
                          ? null
                          : _calculate,
                      child: const Text('Calcular pendientes'),
                    ),
                    if (_accepted != null)
                      Text(
                        'Ruta aceptada: ${_accepted!.stopOrder.length} paradas · '
                        '${_accepted!.metrics.distanceMeters} m',
                      ),
                    if (candidate != null) ...[
                      Text(
                        'Nueva propuesta: ${candidate.stopOrder.length} paradas · '
                        '${candidate.metrics.distanceMeters} m · '
                        '${candidate.metrics.totalDuration.inSeconds} s',
                      ),
                      FilledButton(
                        onPressed: _busy || !_ready ? null : _accept,
                        child: const Text('Aceptar propuesta'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Confirma paquetes después de aceptar una ruta. '
                      'Las paradas completadas se muestran al final '
                      'si ya no están en el orden aceptado.',
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              final stopId = order[index - 1];
              final stop = stopsById[stopId];
              if (stop == null) {
                return ListTile(
                  title: Text('$stopId · definición no disponible'),
                );
              }
              final tasks = [for (final id in stop.taskIds) tasksById[id]!];
              final pending = tasks.where((task) => task.isPending).length;
              return Card(
                key: ValueKey('stop-$stopId'),
                child: ExpansionTile(
                  title: Text(stopId),
                  subtitle: Text('$pending pendientes de ${tasks.length}'),
                  children: [
                    for (final task in tasks)
                      ListTile(
                        title: Text(task.id),
                        subtitle: Text(
                          task.isPending ? 'Pendiente' : 'Entregado',
                        ),
                        trailing: task.isPending
                            ? IconButton(
                                key: ValueKey('confirm-${task.id}'),
                                tooltip: 'Confirmar ${task.id}',
                                onPressed:
                                    _busy ||
                                        !_ready ||
                                        !(_accepted?.stopOrder.contains(
                                              stopId,
                                            ) ??
                                            false)
                                    ? null
                                    : () => _confirm(task.id),
                                icon: const Icon(Icons.check_circle_outline),
                              )
                            : const Icon(Icons.check_circle),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
