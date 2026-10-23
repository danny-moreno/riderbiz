import 'package:flutter/material.dart';

import 'route_optimization_models.dart';
import 'route_optimization_port.dart';
import 'vroom_route_optimization_adapter.dart';

class RouteValidationScreen extends StatefulWidget {
  const RouteValidationScreen({super.key});

  @override
  State<RouteValidationScreen> createState() => _RouteValidationScreenState();
}

class _RouteValidationScreenState extends State<RouteValidationScreen> {
  final _adapter = VroomRouteOptimizationAdapter(
    endpoint: Uri.parse('http://127.0.0.1:3000/'),
  );

  RouteOptimizationCancellationSignal? _signal;
  RouteCandidate? _candidate;
  String? _error;
  bool _isBusy = false;

  RouteOptimizationRequest _request() {
    return RouteOptimizationRequest(
      plan: RoutePlan(
        id: 'ROUTE-TABLET-SYNTHETIC',
        currentOrder: ['STOP-A', 'STOP-B'],
        stops: [
          OperationalStop(
            id: 'STOP-A',
            coordinate: const RouteCoordinate(
              latitude: 42.8100,
              longitude: -1.6400,
            ),
            taskIds: ['TASK-A'],
          ),
          OperationalStop(
            id: 'STOP-B',
            coordinate: const RouteCoordinate(
              latitude: 42.8150,
              longitude: -1.6350,
            ),
            taskIds: ['TASK-B'],
          ),
        ],
        tasks: [
          for (final id in ['A', 'B'])
            RouteTask(
              id: 'TASK-$id',
              stopId: 'STOP-$id',
              type: RouteTaskType.delivery,
              status: RouteTaskStatus.pending,
              priority: RoutePriority.normal,
              serviceDuration: const Duration(seconds: 120),
            ),
        ],
      ),
      currentLocation: const RouteCoordinate(
        latitude: 42.8125,
        longitude: -1.6458,
      ),
      departureAt: DateTime.now().toUtc(),
      timeout: const Duration(seconds: 40),
    );
  }

  Future<void> _calculate() async {
    if (_isBusy) return;

    final signal = RouteOptimizationCancellationSignal();
    _signal = signal;

    setState(() {
      _isBusy = true;
      _candidate = null;
      _error = null;
    });

    try {
      final candidate = await _adapter.optimize(
        _request(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidate = _candidate;

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
            'No se utiliza la ubicación del dispositivo.',
          ),
          const SizedBox(height: 16),
          const Text('Orden inicial: STOP-A → STOP-B'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isBusy ? null : _calculate,
            child: Text(_isBusy ? 'Calculando…' : 'Calcular propuesta'),
          ),
          if (_isBusy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 24),
            Text(_error!, semanticsLabel: 'Error: $_error'),
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
              'La propuesta no se guarda ni modifica el paquete local.',
            ),
          ],
        ],
      ),
    );
  }
}
