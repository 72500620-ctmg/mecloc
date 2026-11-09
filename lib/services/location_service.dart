import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Retorna instantaneamente a última posição em cache do dispositivo (sem esperar satélite)
  Future<LatLng?> getLastKnownLocation() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        return LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {}
    return null;
  }

  Future<LatLng> getCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      if (!enabled) {
        throw Exception(
            'A localização está desativada. Ative-a ou busque por cidade.');
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3));
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 6));
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
            'Permissão de localização negada. Busque por cidade ou altere a permissão do aplicativo.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(const Duration(seconds: 9));
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      throw Exception(
          'A localização demorou a responder. Tente novamente ou busque por cidade.');
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception(
          'Localização indisponível. Tente novamente ou busque por cidade.');
    }
  }
}
