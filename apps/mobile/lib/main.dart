import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riderbiz_mobile/scanner_screen.dart';
import 'package:riderbiz_mobile/location_validation_service.dart';

void main() {
  runApp(RiderBizValidationApp(store: LocalPackageStore()));
}

enum DeliveryStatus { pending, delivered }

class SyntheticPackage {
  const SyntheticPackage({required this.id, required this.status});

  final String id;
  final DeliveryStatus status;

  SyntheticPackage copyWith({DeliveryStatus? status}) {
    return SyntheticPackage(id: id, status: status ?? this.status);
  }

  Map<String, Object> toJson() {
    return {'id': id, 'status': status.name};
  }

  factory SyntheticPackage.fromJson(Map<String, dynamic> json) {
    return SyntheticPackage(
      id: json['id'] as String,
      status: DeliveryStatus.values.byName(json['status'] as String),
    );
  }
}

class LocalPackageStore {
  static const _storageKey = 'riderbiz.spike.synthetic_package';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<SyntheticPackage?> load() async {
    final storedValue = await _preferences.getString(_storageKey);

    if (storedValue == null) {
      return null;
    }

    return SyntheticPackage.fromJson(
      jsonDecode(storedValue) as Map<String, dynamic>,
    );
  }

  Future<void> save(SyntheticPackage package) async {
    await _preferences.setString(_storageKey, jsonEncode(package.toJson()));
  }

  Future<void> delete() async {
    await _preferences.remove(_storageKey);
  }
}

class RiderBizValidationApp extends StatelessWidget {
  const RiderBizValidationApp({required this.store, super.key});

  final LocalPackageStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiderBiz Validation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: PackageValidationScreen(store: store),
    );
  }
}

class PackageValidationScreen extends StatefulWidget {
  const PackageValidationScreen({required this.store, super.key});

  final LocalPackageStore store;

  @override
  State<PackageValidationScreen> createState() =>
      _PackageValidationScreenState();
}

class _PackageValidationScreenState extends State<PackageValidationScreen> {
  SyntheticPackage? _package;
  bool _isBusy = true;
  String? _lastScannedCode;
  final LocationValidationService _locationService =
      LocationValidationService();

  String? _locationMessage;
  bool _isLocating = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final storedPackage = await widget.store.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _package = storedPackage;
      _isBusy = false;
    });
  }

  Future<void> _createPackage() async {
    setState(() => _isBusy = true);

    await widget.store.save(
      const SyntheticPackage(id: 'RB-SYN-0001', status: DeliveryStatus.pending),
    );

    await _reload();
  }

  Future<void> _markAsDelivered() async {
    final currentPackage = _package;

    if (currentPackage == null) {
      return;
    }

    setState(() => _isBusy = true);

    await widget.store.save(
      currentPackage.copyWith(status: DeliveryStatus.delivered),
    );

    await _reload();
  }

  Future<void> _deletePackage() async {
    setState(() => _isBusy = true);
    await widget.store.delete();
    await _reload();
  }

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SyntheticScannerScreen()),
    );

    if (!mounted || scannedCode == null) {
      return;
    }

    setState(() {
      _lastScannedCode = scannedCode;
    });
  }

  Future<void> _validateLocation() async {
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    final message = await _locationService.validateCurrentLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLocating = false;
      _locationMessage = message;
    });
  }

  String _statusLabel(DeliveryStatus status) {
    return switch (status) {
      DeliveryStatus.pending => 'Pendiente',
      DeliveryStatus.delivered => 'Entregado',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RiderBiz · Validación local')),
      body: Center(
        child: _isBusy
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 72),
                    const SizedBox(height: 24),
                    Text(
                      _package == null
                          ? 'No existe ningún paquete local'
                          : 'Paquete: ${_package!.id}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _package == null
                          ? 'Crea un registro utilizando datos sintéticos.'
                          : 'Estado: ${_statusLabel(_package!.status)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _package == null ? _createPackage : null,
                      child: const Text('Crear paquete sintético'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _package?.status == DeliveryStatus.pending
                          ? _markAsDelivered
                          : null,
                      child: const Text('Marcar como entregado'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _package == null ? null : _openScanner,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Leer QR sintético'),
                    ),
                    if (_lastScannedCode != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _lastScannedCode == _package?.id
                            ? 'Código sintético válido: $_lastScannedCode'
                            : 'El código leído no coincide con el paquete local.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLocating ? null : _validateLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _isLocating
                            ? 'Obteniendo ubicación…'
                            : 'Validar ubicación',
                      ),
                    ),
                    if (_locationMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_locationMessage!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _package == null ? null : _deletePackage,
                      child: const Text('Eliminar prueba local'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
