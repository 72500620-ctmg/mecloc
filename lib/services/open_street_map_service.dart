import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/workshop.dart';
import 'workshop_discovery_service.dart';
import 'nominatim_request_queue.dart';

class OpenStreetMapService {
  OpenStreetMapService(
      {http.Client? client,
      DateTime Function()? now,
      this.minimumRequestInterval = const Duration(seconds: 1),
      this.requestTimeout = const Duration(seconds: 7)})
      : _client = client ?? http.Client(),
        _now = now ?? DateTime.now;

  static const _nominatimHost = 'nominatim.openstreetmap.org';
  static const _userAgent = 'MecLoc/1.0';

  final http.Client _client;
  final Map<String, LatLng> _geocodedCities = {};
  final DateTime Function() _now;
  final Duration requestTimeout;
  final Duration minimumRequestInterval;
  LatLng? proximityCenter;

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      if (!kIsWeb) 'User-Agent': _userAgent,
    };
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<LatLng> geocodeCity(String city) async {
    final normalizedQuery =
        '${city.trim().toLowerCase()}@${proximityCenter?.latitude.toStringAsFixed(2)},${proximityCenter?.longitude.toStringAsFixed(2)}';
    final cached = _geocodedCities[normalizedQuery];
    if (cached != null) return cached;

    // Resolução de CEP brasileiro (8 dígitos) via ViaCEP para maior precisão
    String searchTarget = city.trim();
    final isCep = RegExp(r'^\d{5}-?\d{3}$').hasMatch(searchTarget);
    if (isCep) {
      try {
        final cleanCep = searchTarget.replaceAll(RegExp(r'\D'), '');
        final viacepUri = Uri.https('viacep.com.br', '/ws/$cleanCep/json/');
        final viacepResponse =
            await _client.get(viacepUri).timeout(const Duration(seconds: 4));
        if (viacepResponse.statusCode == 200) {
          final data = jsonDecode(viacepResponse.body) as Map<String, dynamic>;
          if (data['erro'] != true && data['erro'] != 'true') {
            final parts = [
              data['logradouro'],
              data['bairro'],
              data['localidade'],
              data['uf'],
            ]
                .whereType<String>()
                .where((part) => part.trim().isNotEmpty)
                .join(', ');
            if (parts.isNotEmpty) {
              searchTarget = parts;
            }
          }
        }
      } catch (_) {
        // Segue com a busca padrão caso o ViaCEP oscile
      }
    }

    final prox = proximityCenter;

    try {
      final queryParams = <String, String>{
        'q': searchTarget,
        'format': 'jsonv2',
        'limit': prox != null ? '5' : '1',
        'countrycodes': 'br',
      };

      // Priorização geográfica local estilo Uber: delimita viewbox ao redor do usuário
      if (prox != null) {
        const delta = 0.65; // ~70 km ao redor da posição de referência
        final minLon = (prox.longitude - delta).toStringAsFixed(4);
        final maxLon = (prox.longitude + delta).toStringAsFixed(4);
        final minLat = (prox.latitude - delta).toStringAsFixed(4);
        final maxLat = (prox.latitude + delta).toStringAsFixed(4);
        queryParams['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
        // bounded=0 (omitido) dá preferência aos resultados locais sem ignorar o resto
      }

      final uri = Uri.https(_nominatimHost, '/search', queryParams);
      final response = await NominatimRequestQueue.run(() => _client
          .get(uri, headers: _buildHeaders({'Accept-Language': 'pt-BR'}))
          .timeout(const Duration(seconds: 8)));
      if (response.statusCode != 200) {
        throw Exception('Nominatim respondeu com HTTP ${response.statusCode}.');
      }
      final results =
          (jsonDecode(response.body) as List<dynamic>).where((item) {
        if (item is! Map<String, dynamic>) return false;
        final kind = item['class'] ?? item['category'];
        return kind == null ||
            const ['place', 'boundary', 'highway', 'building', 'landuse']
                .contains(kind);
      }).toList();
      if (results.isNotEmpty) {
        LatLng bestPoint;
        if (prox != null && results.length > 1) {
          const distCalc = Distance(roundResult: false);
          // Ordena pelo resultado mais próximo da localização atual do usuário
          final parsed = results.whereType<Map<String, dynamic>>().map((res) {
            final lat = double.parse(res['lat'] as String);
            final lon = double.parse(res['lon'] as String);
            final pt = LatLng(lat, lon);
            final d = distCalc.as(LengthUnit.Kilometer, prox, pt);
            return (point: pt, distance: d);
          }).toList();
          parsed.sort((a, b) => a.distance.compareTo(b.distance));
          bestPoint = parsed.first.point;
        } else {
          final result = results.first as Map<String, dynamic>;
          bestPoint = LatLng(
            double.parse(result['lat'] as String),
            double.parse(result['lon'] as String),
          );
        }
        _geocodedCities[normalizedQuery] = bestPoint;
        return bestPoint;
      }
    } catch (_) {}

    // Photon é uma segunda fonte OSM para que uma falha do Nominatim não
    // interrompa a busca de cidade. Ambas as consultas só ocorrem após envio.
    try {
      final photonParams = <String, String>{
        'q': searchTarget,
        'limit': prox != null ? '5' : '1',
        'countrycode': 'BR',
      };
      if (prox != null) {
        photonParams['lat'] = prox.latitude.toString();
        photonParams['lon'] = prox.longitude.toString();
      }

      final uri = Uri.https('photon.komoot.io', '/api/', photonParams);
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('Photon respondeu com HTTP ${response.statusCode}.');
      }
      final rawFeatures = (jsonDecode(response.body)
              as Map<String, dynamic>)['features'] as List<dynamic>? ??
          const [];
      final features =
          rawFeatures.whereType<Map<String, dynamic>>().where((item) {
        final props = item['properties'] as Map<String, dynamic>? ?? {};
        final key = props['osm_key'];
        return key == null ||
            const ['place', 'boundary', 'highway', 'building', 'landuse']
                .contains(key);
      }).toList();
      if (features.isEmpty) {
        throw Exception(
            'Localização não encontrada. Confira o nome e tente novamente.');
      }

      LatLng bestPoint;
      if (prox != null && features.length > 1) {
        const distCalc = Distance(roundResult: false);
        final points = features.whereType<Map<String, dynamic>>().map((feat) {
          final coords =
              ((feat['geometry'] as Map<String, dynamic>?)?['coordinates']
                      as List<dynamic>?) ??
                  [0, 0];
          final pt = LatLng(
              (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
          final d = distCalc.as(LengthUnit.Kilometer, prox, pt);
          return (point: pt, distance: d);
        }).toList();
        points.sort((a, b) => a.distance.compareTo(b.distance));
        bestPoint = points.first.point;
      } else {
        final coordinates = (features.first['geometry']
            as Map<String, dynamic>)['coordinates'] as List<dynamic>;
        bestPoint = LatLng(
          (coordinates[1] as num).toDouble(),
          (coordinates[0] as num).toDouble(),
        );
      }

      _geocodedCities[normalizedQuery] = bestPoint;
      return bestPoint;
    } catch (_) {
      throw Exception(
        'Não foi possível localizar este endereço. Verifique a conexão ou informe bairro e cidade.',
      );
    }
  }

  late final _discovery = WorkshopDiscoveryService(
      client: _client,
      now: _now,
      requestTimeout: requestTimeout,
      minimumRequestInterval: minimumRequestInterval,
      headers: _buildHeaders());

  Future<List<Workshop>> searchWorkshopsByName(
      String name, LatLng center) async {
    final queryTerm = name.trim();
    const distanceCalc = Distance(roundResult: false);
    if (queryTerm.toLowerCase().contains('autobahn')) {
      const p = LatLng(-19.9101, -43.9485);
      final dist = distanceCalc.as(LengthUnit.Kilometer, center, p);
      if (dist > 35) return const [];
      return [
        Workshop(
          id: 'partner:autobahn:001',
          name: 'Centro Automotivo Autobahn',
          address: 'Rua Bonfim, 374 - Bonfim, Belo Horizonte - MG',
          phone: '(31) 3567-0148',
          whatsappPhone: '3135670148',
          openingHours: 'Segunda a Sexta: 08:00 - 18:00',
          latitude: -19.9101,
          longitude: -43.9485,
          category: 'Oficina mecânica',
          categoryType: WorkshopCategory.mechanic,
          isCustomRegistered: true,
          supportedBrands: const [
            'Volkswagen',
            'Audi',
            'BMW',
            'Mercedes-Benz',
            'Todas as marcas'
          ],
          specialties: const [
            'Injeção Eletrônica',
            'Câmbio Automático',
            'Motor',
            'Freios e Suspensão'
          ],
          description:
              'Oficina especializada em mecânica geral, diagnóstico eletrônico computadorizado e manutenção preventiva.',
          distanceKm: double.parse(dist.toStringAsFixed(1)),
        ),
      ];
    }

    return _discovery.searchByName(queryTerm, center);
  }

  Future<List<Workshop>> searchNearbyWorkshops(
    LatLng center, {
    int? radiusMeters,
    ({double south, double west, double north, double east})? boundingBox,
    bool automatic = false,
    bool forceRefresh = false,
    void Function(List<Workshop>)? onProgress,
  }) =>
      _discovery.searchNearby(center,
          radiusMeters: radiusMeters,
          boundingBox: boundingBox,
          automatic: automatic,
          forceRefresh: forceRefresh,
          onProgress: onProgress);

  void cancelDiscoverySearches() => _discovery.cancelPending();
  DateTime? get nextAutomaticSearchAt => _discovery.nextAutomaticAt;

  void dispose() => _discovery.dispose();
}
