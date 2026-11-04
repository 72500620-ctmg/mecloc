import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Future<LatLng> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Ative a localização do aparelho ou informe uma cidade.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(
        'Permita o acesso à localização ou informe uma cidade para continuar.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'A permissão de localização está bloqueada. Altere-a nas configurações '
        'ou informe uma cidade.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on LocationServiceDisabledException {
      throw Exception('Ative a localização do aparelho ou informe uma cidade.');
    } on PermissionDeniedException {
      throw Exception(
        'Permita o acesso à localização ou informe uma cidade para continuar.',
      );
    }
  }
}
