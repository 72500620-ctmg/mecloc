import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Localização padrão simulada caso o dispositivo/navegador não tenha GPS ativo
  /// (São Paulo - Região Central / Av. Paulista)
  static const mockLocation = LatLng(-23.561684, -46.655981);

  Future<LatLng> getCurrentLocation() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);

      if (!isServiceEnabled) {
        debugPrint('Serviço de GPS indisponível. Usando localização mockada.');
        return mockLocation;
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 4), onTimeout: () => LocationPermission.denied);
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Permissão de GPS não concedida. Usando localização mockada.');
        return mockLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Falha ao obter localização do dispositivo ($e). Usando localização mockada.');
      return mockLocation;
    }
  }
}
