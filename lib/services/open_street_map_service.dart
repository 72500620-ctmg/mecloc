import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/workshop.dart';

class OpenStreetMapService {
  OpenStreetMapService({http.Client? client})
      : _client = client ?? http.Client();

  static const _overpassEndpoint = 'https://overpass-api.de/api/interpreter';
  static const _nominatimHost = 'nominatim.openstreetmap.org';
  static const _userAgent = 'MecLoc/1.0 (academic project)';
  static const _searchRadiusMeters = 7000;

  final http.Client _client;
  final Map<String, LatLng> _geocodedCities = {};
  DateTime? _lastGeocodingRequest;

  Future<LatLng> geocodeCity(String city) async {
    final normalizedCity = city.trim().toLowerCase();
    final cached = _geocodedCities[normalizedCity];
    if (cached != null) return cached;

    final lastRequest = _lastGeocodingRequest;
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      const minimumInterval = Duration(seconds: 1);
      if (elapsed < minimumInterval) {
        await Future<void>.delayed(minimumInterval - elapsed);
      }
    }
    _lastGeocodingRequest = DateTime.now();

    final uri = Uri.https(_nominatimHost, '/search', {
      'q': city.trim(),
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'br',
    });
    final response = await _client.get(uri, headers: {
      'User-Agent': _userAgent,
      'Accept-Language': 'pt-BR',
    });
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao localizar a cidade (HTTP ${response.statusCode}).',
      );
    }

    final results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) {
      throw Exception('Não foi possível localizar essa cidade.');
    }
    final result = results.first as Map<String, dynamic>;
    final point = LatLng(
      double.parse(result['lat'] as String),
      double.parse(result['lon'] as String),
    );
    _geocodedCities[normalizedCity] = point;
    return point;
  }

  Future<List<Workshop>> searchNearbyWorkshops(LatLng center) async {
    final query = '''
[out:json][timeout:20];
(
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["shop"="car_repair"];
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["craft"="car_repair"];
);
out body center 100;
''';
    final response = await _client.post(
      Uri.parse(_overpassEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'User-Agent': _userAgent,
      },
      body: {'data': query},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao buscar oficinas no OpenStreetMap '
        '(HTTP ${response.statusCode}). Tente novamente em instantes.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? const [];
    return elements
        .whereType<Map<String, dynamic>>()
        .map(Workshop.fromOverpassJson)
        .where((workshop) =>
            workshop.latitude != null && workshop.longitude != null)
        .toList();
  }

  void dispose() => _client.close();
}
