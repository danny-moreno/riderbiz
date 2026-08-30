import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SyntheticScannerScreen extends StatefulWidget {
  const SyntheticScannerScreen({super.key});

  @override
  State<SyntheticScannerScreen> createState() => _SyntheticScannerScreenState();
}

class _SyntheticScannerScreenState extends State<SyntheticScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _hasDetectedCode = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_hasDetectedCode || capture.barcodes.isEmpty) {
      return;
    }

    final value = capture.barcodes.first.rawValue;

    if (value == null || value.isEmpty) {
      return;
    }

    _hasDetectedCode = true;
    _controller.stop();

    Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leer código sintético')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetection),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            right: 24,
            bottom: 40,
            left: 24,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Utiliza únicamente el QR sintético RB-SYN-0001. '
                  'No escanees etiquetas ni datos personales reales.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
