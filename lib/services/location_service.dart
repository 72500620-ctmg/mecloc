import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  LocationService({bool? useBrowserGeolocation})
      : _useBrowserGeolocation = useBrowserGeolocation ?? kIsWeb;
  final bool _useBrowserGeolocation;

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
      if (_useBrowserGeolocation) {
        // O navegador pede permissão e obtém a posição em uma única chamada.
        // requestPermission na implementação web já pede uma posição, o que
        // duplicava a consulta e expirava enquanto o usuário respondia ao Safari.
        final position = await Geolocator.getCurrentPosition(
          locationSettings: WebSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 20),
              maximumAge: const Duration(minutes: 2)),
        ).timeout(const Duration(seconds: 25));
        return LatLng(position.latitude, position.longitude);
      }
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
            .timeout(const Duration(seconds: 45));
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
    } on PermissionDeniedException {
      throw Exception(
          'Permita o acesso à localização deste site no navegador ou busque por cidade.');
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
