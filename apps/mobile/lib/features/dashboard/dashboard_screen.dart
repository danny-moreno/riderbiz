import 'dart:async';

import '../daily_session/daily_session_screen.dart';
import '../daily_session/synthetic_daily_session_service.dart';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../data/local/riderbiz_database.dart' show RiderBizDatabase;
import '../route_optimization/route_validation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.validationBuilder,
    this.database,
    super.key,
  });

  final WidgetBuilder validationBuilder;
  final RiderBizDatabase? database;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const ink = Color(0xFF002D33);
  static const teal = Color(0xFF00AEA6);
  static const surface = Color(0xFFF4F9FA);

  late final RiderBizDatabase _database;
  int _total = 0;
  int _delivered = 0;
  int? _incomeMinor;
  String? _nextPackage;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _database =
        widget.database ??
        RiderBizDatabase(name: SyntheticDailySessionService.databaseName);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final packages =
          await (_database.select(_database.syntheticPackages)
                ..where(
                  (row) => row.deliveryRunId.equals(
                    SyntheticDailySessionService.runId,
                  ),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.id)]))
              .get();
      final delivered = packages
          .where((package) => package.status == 'delivered')
          .toList();
      final pending = packages
          .where((package) => package.status == 'pending')
          .toList();
      final hasCompleteAmounts = delivered.every(
        (package) =>
            package.unitPriceMinorSnapshot != null &&
            package.currencySnapshot == 'EUR',
      );

      if (!mounted) return;
      setState(() {
        _total = packages.length;
        _delivered = delivered.length;
        _incomeMinor = hasCompleteAmounts
            ? delivered.fold<int>(
                0,
                (total, package) => total + package.unitPriceMinorSnapshot!,
              )
            : null;
        _nextPackage = pending.isEmpty ? null : pending.first.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar el progreso guardado.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(WidgetBuilder builder) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: builder));
    if (mounted) await _load();
  }

  @override
  void dispose() {
    if (widget.database == null) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  Widget _metric(String label, String value, String detail) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(detail, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = _incomeMinor == null
        ? '—'
        : '${(_incomeMinor! / 100).toStringAsFixed(2).replaceAll('.', ',')} €';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    color: ink,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.person_outline),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hola',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Tu jornada, en un solo lugar.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Jornada sintética de validación',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        if (_loading)
                          const LinearProgressIndicator()
                        else if (_error != null)
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _metric('Entregas', '$_delivered', 'de $_total'),
                              const SizedBox(width: 8),
                              _metric('Ingresos', income, 'ficticios'),
                              const SizedBox(width: 8),
                              _metric('Tiempo', '—', 'sin medición'),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tu operativa',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  color: teal,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _loading
                                      ? 'Cargando…'
                                      : _error != null
                                      ? 'Progreso no disponible'
                                      : _nextPackage ??
                                            (_total == 0
                                                ? 'Sin paquetes preparados'
                                                : 'Sin entregas pendientes'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Datos sintéticos. El paquete mostrado sigue '
                                  'el orden de identificadores; no indica la '
                                  'siguiente parada de la ruta aceptada.',
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: () => _open(
                                    (_) =>
                                        DailySessionScreen(database: _database),
                                  ),
                                  child: const Text('Abrir jornada'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _open(
                            (_) => const RouteValidationScreen(
                              databaseName:
                                  'riderbiz_partial_delivery_validation',
                            ),
                          ),
                          icon: const Icon(Icons.route_outlined),
                          label: const Text('Prueba anterior · 2 paquetes'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _open(widget.validationBuilder),
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Validaciones locales'),
                        ),
                        if (_error != null)
                          TextButton(
                            onPressed: _loading ? null : _load,
                            child: const Text('Reintentar carga'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) {
            _open((_) => DailySessionScreen(database: _database));
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sección pendiente de implementación.'),
            ),
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Operaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.euro_outlined),
            label: 'Finanzas',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Informes'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
