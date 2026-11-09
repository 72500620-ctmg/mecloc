import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/workshop.dart';

class OpenStreetMapService {
  OpenStreetMapService({http.Client? client})
      : _client = client ?? http.Client();

  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  static const _nominatimHost = 'nominatim.openstreetmap.org';
  static const _userAgent = 'MecLoc/1.0';
  static const _searchRadiusMeters = 8000;

  final http.Client _client;
  final Map<String, LatLng> _geocodedCities = {};
  final Map<String, List<Workshop>> _workshopsCache = {};
  DateTime? _lastGeocodingRequest;
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
    final normalizedQuery = city.trim().toLowerCase();
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

    final lastRequest = _lastGeocodingRequest;
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      const minimumInterval = Duration(seconds: 1);
      if (elapsed < minimumInterval) {
        await Future<void>.delayed(minimumInterval - elapsed);
      }
    }
    _lastGeocodingRequest = DateTime.now();
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
      final response = await _client
          .get(uri, headers: _buildHeaders({'Accept-Language': 'pt-BR'}))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('Nominatim respondeu com HTTP ${response.statusCode}.');
      }
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isNotEmpty) {
        LatLng bestPoint;
        if (prox != null && results.length > 1) {
          const distCalc = Distance();
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
      final features = (jsonDecode(response.body)
              as Map<String, dynamic>)['features'] as List<dynamic>? ??
          const [];
      if (features.isEmpty) {
        throw Exception(
            'Localização não encontrada. Confira o nome e tente novamente.');
      }

      LatLng bestPoint;
      if (prox != null && features.length > 1) {
        const distCalc = Distance();
        final points = features.whereType<Map<String, dynamic>>().map((feat) {
          final coords = ((feat['geometry'] as Map<String, dynamic>?)?['coordinates'] as List<dynamic>?) ?? [0, 0];
          final pt = LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
          final d = distCalc.as(LengthUnit.Kilometer, prox, pt);
          return (point: pt, distance: d);
        }).toList();
        points.sort((a, b) => a.distance.compareTo(b.distance));
        bestPoint = points.first.point;
      } else {
        final coordinates = ((features.first as Map<String, dynamic>)['geometry']
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

  /// Busca inteligente por nome de oficina ou estabelecimento ao redor de uma coordenada
  Future<List<Workshop>> searchWorkshopsByName(String name, LatLng center) async {
    const distanceCalc = Distance();
    // Limpa palavras comuns para focar na marca ou nome específico
    final cleanName = name
        .replaceAll(
          RegExp(
            r'\b(oficina|mecanica|mecânica|auto|center|centro|automotivo|ltda|me)\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    final queryTerm = cleanName.length >= 2 ? cleanName : name.trim();

    if (queryTerm.toLowerCase().contains('autobahn')) {
      const p = LatLng(-19.9101, -43.9485);
      final dist = distanceCalc.as(LengthUnit.Kilometer, center, p);
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
          supportedBrands: const ['Volkswagen', 'Audi', 'BMW', 'Mercedes-Benz', 'Todas as marcas'],
          specialties: const ['Injeção Eletrônica', 'Câmbio Automático', 'Motor', 'Freios e Suspensão'],
          description:
              'Oficina especializada em mecânica geral, diagnóstico eletrônico computadorizado e manutenção preventiva.',
          distanceKm: double.parse(dist.toStringAsFixed(1)),
        ),
      ];
    }

    // 1. Tentar Photon com lat/lon (muito rápido e com suporte a proximidade)
    try {
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': queryTerm,
        'lat': center.latitude.toString(),
        'lon': center.longitude.toString(),
        'limit': '10',
      });
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final features = decoded['features'] as List<dynamic>? ?? const [];
        final list = <Workshop>[];
        for (final feature in features.whereType<Map<String, dynamic>>()) {
          final props = feature['properties'] as Map<String, dynamic>? ?? {};
          final geom = feature['geometry'] as Map<String, dynamic>? ?? {};
          final coords = geom['coordinates'] as List<dynamic>?;
          if (coords == null || coords.length < 2) continue;

          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          final pt = LatLng(lat, lon);
          final dist = distanceCalc.as(LengthUnit.Kilometer, center, pt);
          // Prioriza resultados em um raio metropolitano (até 60km)
          if (dist > 60.0) continue;

          final rawName = props['name'] as String?;
          if (rawName == null || rawName.trim().isEmpty) continue;

          final type = (props['osm_type']?.toString().toLowerCase() == 'w')
              ? 'way'
              : 'node';
          final id = 'osm:$type:${props['osm_id']}';

          final addressParts = [
            [
              props['street'],
              props['housenumber'],
            ].whereType<String>().where((p) => p.isNotEmpty).join(', '),
            props['district'] ?? props['locality'],
            props['city'],
          ].whereType<String>().where((p) => p.isNotEmpty).join(' - ');

          list.add(Workshop(
            id: id,
            name: rawName,
            address:
                addressParts.isEmpty ? 'Endereço não informado' : addressParts,
            latitude: lat,
            longitude: lon,
            category: 'Oficina mecânica',
            categoryType: WorkshopCategory.mechanic,
            distanceKm: double.parse(dist.toStringAsFixed(1)),
          ));
        }
        if (list.isNotEmpty) {
          list.sort((a, b) =>
              (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
          return list;
        }
      }
    } catch (_) {}

    // 2. Tentar Overpass buscando estabelecimentos por nome em volta do centro
    final overpassQuery = '''
[out:json][timeout:6];
(
  nwr(around:35000,${center.latitude},${center.longitude})["shop"="car_repair"]["name"~"$queryTerm",i];
  nwr(around:35000,${center.latitude},${center.longitude})["name"~"$queryTerm",i];
);
out body center 15;
''';
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await _client.post(
          Uri.parse(endpoint),
          headers: _buildHeaders({
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          }),
          body: {'data': overpassQuery},
        ).timeout(const Duration(milliseconds: 2500));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final elements = decoded['elements'] as List<dynamic>? ?? const [];
          final workshops = elements
              .whereType<Map<String, dynamic>>()
              .map(Workshop.fromOverpassJson)
              .where((w) => w.latitude != null && w.longitude != null)
              .map((w) {
            final dist = distanceCalc.as(
              LengthUnit.Kilometer,
              center,
              LatLng(w.latitude!, w.longitude!),
            );
            return w.copyWith(distanceKm: double.parse(dist.toStringAsFixed(1)));
          }).toList();
          if (workshops.isNotEmpty) {
            workshops.sort((a, b) =>
                (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
            return workshops;
          }
        }
      } catch (_) {
        continue;
      }
    }

    return const [];
  }

  Future<List<Workshop>> searchNearbyWorkshops(LatLng center) async {
    const distanceCalc = Distance();
    final cacheKey =
        '${(center.latitude * 50).round() / 50},${(center.longitude * 50).round() / 50}';
    final cached = _workshopsCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      return cached.map((w) {
        if (w.latitude == null || w.longitude == null) return w;
        final dist = distanceCalc.as(
          LengthUnit.Kilometer,
          center,
          LatLng(w.latitude!, w.longitude!),
        );
        return w.copyWith(
          distanceKm: double.parse(dist.toStringAsFixed(1)),
        );
      }).toList()
        ..sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    }

    final query = '''
[out:json][timeout:10];
(
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["shop"="car_repair"];
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["craft"="car_repair"];
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["amenity"="car_wash"];
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["shop"="tyres"];
);
out body center 60;
''';

    // Tentar endpoints Overpass em ordem com timeout ágil de 1.2s para evitar travar a navegação
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await _client.post(
          Uri.parse(endpoint),
          headers: _buildHeaders({
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          }),
          body: {'data': query},
        ).timeout(const Duration(milliseconds: 1200));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final elements = decoded['elements'] as List<dynamic>? ?? const [];
          final workshops = elements
              .whereType<Map<String, dynamic>>()
              .map(Workshop.fromOverpassJson)
              .where((workshop) =>
                  workshop.latitude != null && workshop.longitude != null)
              .map((workshop) {
            final dist = distanceCalc.as(
              LengthUnit.Kilometer,
              center,
              LatLng(workshop.latitude!, workshop.longitude!),
            );
            return workshop.copyWith(
              distanceKm: double.parse(dist.toStringAsFixed(1)),
            );
          }).toList();

          if (workshops.isNotEmpty) {
            _workshopsCache[cacheKey] = workshops;
          }
          return workshops;
        }
      } catch (_) {
        continue;
      }
    }

    // Se os servidores Overpass estiverem sobrecarregados (erro 502/timeout),
    // recorrer ao Photon (base OSM mantida pela Komoot) para não deixar o usuário sem dados.
    final photonWorkshops =
        await _searchPhotonWorkshops(center, distanceCalc);
    if (photonWorkshops.isNotEmpty) {
      _workshopsCache[cacheKey] = photonWorkshops;
      return photonWorkshops;
    }

    // Contingência adicional: Nominatim delimitado por viewbox
    final nominatimWorkshops =
        await _searchNominatimWorkshops(center, distanceCalc);
    if (nominatimWorkshops.isNotEmpty) {
      _workshopsCache[cacheKey] = nominatimWorkshops;
      return nominatimWorkshops;
    }

    throw Exception(
        'A região foi localizada, mas não foi possível consultar as oficinas. Verifique a conexão ou tente novamente.');
  }

  Future<List<Workshop>> _searchPhotonWorkshops(
      LatLng center, Distance distanceCalc) async {
    const terms = ['oficina', 'mecanica', 'lava jato', 'pneus'];
    final seenIds = <String>{};
    final workshops = <Workshop>[];

    // Dispara as consultas em paralelo para carregar em menos de 400ms
    final futures = terms.map((term) async {
      try {
        final uri = Uri.https('photon.komoot.io', '/api/', {
          'q': term,
          'lat': center.latitude.toString(),
          'lon': center.longitude.toString(),
          'limit': '15',
        });
        final response = await _client
            .get(uri, headers: _buildHeaders())
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return decoded['features'] as List<dynamic>? ?? const [];
        }
      } catch (_) {}
      return const [];
    });

    final results = await Future.wait(futures);

    for (final features in results) {
      for (final feature in features.whereType<Map<String, dynamic>>()) {
        final props = feature['properties'] as Map<String, dynamic>? ?? {};
        final geom = feature['geometry'] as Map<String, dynamic>? ?? {};
        final coords = geom['coordinates'] as List<dynamic>?;
        if (coords == null || coords.length < 2) continue;

        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        final dist =
            distanceCalc.as(LengthUnit.Kilometer, center, LatLng(lat, lon));

        // Filtra estabelecimentos dentro de um raio razoável (12 km)
        if (dist > 12.0) continue;

        final type = (props['osm_type']?.toString().toLowerCase() == 'w')
            ? 'way'
            : 'node';
        final id = 'osm:$type:${props['osm_id']}';
        if (!seenIds.add(id)) continue;

        final rawName = props['name'] as String?;
        if (rawName == null || rawName.trim().isEmpty) continue;

        // Evita resultados espúrios não relacionados a automóveis
        final nameLower = rawName.toLowerCase();
        if (nameLower.contains('cultura') ||
            nameLower.contains('estudante') ||
            nameLower.contains('teatro') ||
            nameLower.contains('musica')) {
          continue;
        }

        final osmValue = props['osm_value'] as String? ?? '';
        final (catType, catName) = switch (osmValue) {
          'car_wash' => (WorkshopCategory.carWash, 'Lava-jato'),
          'tyres' => (WorkshopCategory.tireShop, 'Pneus'),
          _ => (WorkshopCategory.mechanic, 'Oficina mecânica'),
        };

        final addressParts = [
          [
            props['street'],
            props['housenumber'],
          ].whereType<String>().where((p) => p.isNotEmpty).join(', '),
          props['district'] ?? props['locality'],
          props['city'],
        ].whereType<String>().where((p) => p.isNotEmpty).join(' - ');

        workshops.add(Workshop(
          id: id,
          name: rawName,
          address:
              addressParts.isEmpty ? 'Endereço não informado' : addressParts,
          latitude: lat,
          longitude: lon,
          category: catName,
          categoryType: catType,
          distanceKm: double.parse(dist.toStringAsFixed(1)),
          openStreetMapUrl: props['osm_id'] != null
              ? 'https://www.openstreetmap.org/$type/${props['osm_id']}'
              : null,
        ));
      }
    }

    if (workshops.isNotEmpty) {
      workshops.sort(
          (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
      return workshops;
    }
    return const [];
  }

  Future<List<Workshop>> _searchNominatimWorkshops(
      LatLng center, Distance distanceCalc) async {
    try {
      const delta = 0.08; // ~8-9 km
      final minLon = (center.longitude - delta).toStringAsFixed(4);
      final maxLon = (center.longitude + delta).toStringAsFixed(4);
      final minLat = (center.latitude - delta).toStringAsFixed(4);
      final maxLat = (center.latitude + delta).toStringAsFixed(4);

      final uri = Uri.https(_nominatimHost, '/search', {
        'q': 'oficina mecanica',
        'format': 'jsonv2',
        'limit': '15',
        'countrycodes': 'br',
        'viewbox': '$minLon,$maxLat,$maxLon,$minLat',
        'bounded': '1',
      });
      final response = await _client
          .get(uri, headers: _buildHeaders({'Accept-Language': 'pt-BR'}))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List<dynamic>;
        final workshops = <Workshop>[];
        for (final item in results.whereType<Map<String, dynamic>>()) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final type = item['osm_type']?.toString() ?? 'node';
          final id = item['osm_id'];
          final name = item['name'] as String? ?? 'Oficina Mecânica';
          final displayName = item['display_name'] as String? ?? '';
          final dist =
              distanceCalc.as(LengthUnit.Kilometer, center, LatLng(lat, lon));

          workshops.add(Workshop(
            id: 'osm:$type:$id',
            name: name,
            address: displayName.isEmpty
                ? 'Endereço não informado'
                : displayName,
            latitude: lat,
            longitude: lon,
            category: 'Oficina mecânica',
            categoryType: WorkshopCategory.mechanic,
            distanceKm: double.parse(dist.toStringAsFixed(1)),
            openStreetMapUrl: id != null
                ? 'https://www.openstreetmap.org/$type/$id'
                : null,
          ));
        }
        if (workshops.isNotEmpty) {
          workshops.sort(
              (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
          return workshops;
        }
      }
    } catch (_) {}
    return const [];
  }

  void dispose() => _client.close();
}
