import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

class LocationValidationService {
  Future<String> validateCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return 'Activa los servicios de ubicación para realizar la prueba.';
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return 'Permiso de ubicación denegado.';
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Permiso bloqueado. Debe habilitarse desde los ajustes.';
    }

    try {
      final LocationSettings locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              forceLocationManager: true,
              timeLimit: const Duration(seconds: 45),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 45),
            );

      final lastKnownPosition = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: Platform.isAndroid,
      );

      final position =
          lastKnownPosition ??
          await Geolocator.getCurrentPosition(
            locationSettings: locationSettings,
          );

      return 'Ubicación obtenida correctamente. '
          'Precisión estimada: ${position.accuracy.toStringAsFixed(1)} m. '
          'Las coordenadas no se almacenaron.';
    } on TimeoutException {
      return 'No se obtuvo una posición dentro del tiempo permitido.';
    }
  }
}
