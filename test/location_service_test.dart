import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecloc/services/location_service.dart';

class _BrowserPosition extends GeolocatorPlatform {
  int positionCalls = 0, permissionCalls = 0;
  bool deny = false;
  LocationSettings? settings;
  @override
  Future<LocationPermission> checkPermission() async {
    permissionCalls++;
    throw UnsupportedError('Permissions API indisponível');
  }

  @override
  Future<LocationPermission> requestPermission() async {
    permissionCalls++;
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    positionCalls++;
    settings = locationSettings;
    if (deny) throw const PermissionDeniedException('denied');
    return Position(
        latitude: -19.92,
        longitude: -43.94,
        timestamp: DateTime(2026, 11, 9),
        accuracy: 20,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);
  }
}

void main() {
  late GeolocatorPlatform original;
  late _BrowserPosition browser;
  setUp(() {
    original = GeolocatorPlatform.instance;
    browser = _BrowserPosition();
    GeolocatorPlatform.instance = browser;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test('web obtém localização uma única vez sem depender da Permissions API',
      () async {
    final service = LocationService(useBrowserGeolocation: true);
    expect(await service.getCurrentLocation(), const LatLng(-19.92, -43.94));
    expect(browser.positionCalls, 1);
    expect(browser.permissionCalls, 0);
    expect(browser.settings, isA<WebSettings>());
  });

  test('permissão negada no navegador apresenta instrução de localização',
      () async {
    browser.deny = true;
    await expectLater(
        LocationService(useBrowserGeolocation: true).getCurrentLocation(),
        throwsA(predicate((error) =>
            error.toString().contains('Permita o acesso à localização'))));
  });
}
