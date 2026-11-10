import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/workshop.dart';
import '../models/workshop_search_result.dart';
import 'nominatim_request_queue.dart';
import 'discovery_cache.dart';
import '../models/search_area.dart';

class DiscoveryCancelled implements Exception {
  const DiscoveryCancelled();
}

class AutomaticSearchDeferred implements Exception {
  const AutomaticSearchDeferred(this.until);
  final DateTime until;
}

/// Consulta, validação geográfica e cache de estabelecimentos automotivos.
class WorkshopDiscoveryService {
  WorkshopDiscoveryService(
      {required this.client,
      required this.now,
      required this.requestTimeout,
      required this.headers,
      this.minimumRequestInterval = const Duration(seconds: 1)});

  final http.Client client;
  final DateTime Function() now;
  final Duration requestTimeout;
  final Map<String, String> headers;
  final Duration minimumRequestInterval;
  static const endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter'
  ];
  late final _cache = DiscoveryCache(now: now);
  final _pending = <String, Future<WorkshopSearchResult>>{};
  final _activeRequests = <Completer<void>>{};
  final _unavailableUntil = <String, DateTime>{};
  bool _disposed = false;
  int _epoch = 0;
  DateTime? _nextAutomaticAt;
  DateTime? get nextAutomaticAt => _nextAutomaticAt;
  static Future<void> _networkTail = Future.value();
  static DateTime? _lastRequestStart;
  final _failures = <String, int>{};

  void cancelPending() {
    _epoch++;
    for (final abort in _activeRequests.toList()) {
      if (!abort.isCompleted) abort.complete();
    }
  }

  void _ensureCurrent(int epoch) {
    if (_disposed || epoch != _epoch) throw const DiscoveryCancelled();
  }

  Future<List<Workshop>> searchByName(String name, LatLng center) async {
    final epoch = _epoch;
    if (name.isEmpty) return const [];
    final byId = <String, Workshop>{};
    var completeNameQuery = false;
    // Aspas e operadores do nome não podem alterar a consulta Overpass.
    final nameFilter = '["name"~${jsonEncode(RegExp.escape(name))},i]';
    final query = _buildQuery(
        'around:35000,${center.latitude},${center.longitude}',
        nameFilter: nameFilter);
    for (final endpoint in endpoints) {
      if (!_endpointReady(endpoint)) continue;
      try {
        final response = await _overpassRequest(endpoint, query, epoch);
        final result = _parseOverpass(response, center, 35000);
        for (final w in result) {
          byId[w.id] = w;
        }
        if (result.isComplete) {
          completeNameQuery = true;
          break;
        }
      } catch (_) {
        _ensureCurrent(epoch);
        if (_endpointReady(endpoint)) _markUnavailable(endpoint);
        if (_disposed) rethrow;
      }
    }
    // Uma fonte que respondeu sem correspondências é um resultado vazio
    // legítimo (nome inexistente), não uma falha de consulta.
    var fallbackAnswered = false;
    void answered() => fallbackAnswered = true;
    void add(Iterable<Workshop> items) {
      for (final w in items) {
        byId.putIfAbsent(w.id, () => w);
      }
    }

    // 1) Arredores (35 km). O Overpass com filtro de nome frequentemente
    // estoura o tempo e não tolera acentos ausentes; Photon e Nominatim
    // restritos à região garantem os resultados mais próximos. A busca
    // global abaixo ordena por relevância e não pode substituir esta etapa.
    if (!completeNameQuery || byId.isEmpty) {
      add(await _searchPhoton(center, 35000,
          terms: [name], epoch: epoch, onAnswered: answered));
    }
    if (!completeNameQuery && byId.isEmpty) {
      add(await _searchNominatimMatches(center, 35000,
          name: name, epoch: epoch, onAnswered: answered));
    }
    // 2) Restante do Brasil, sem depender da região já exibida no mapa.
    // lat/lon apenas priorizam a proximidade; os resultados acima permanecem.
    add(await _searchPhoton(center, 0,
        terms: [name], epoch: epoch, onAnswered: answered, global: true));
    if (byId.isEmpty) {
      add(await _searchNominatimMatches(center, 0,
          name: name, epoch: epoch, onAnswered: answered, global: true));
    }
    _ensureCurrent(epoch);
    if (byId.isEmpty) {
      if (completeNameQuery) return WorkshopSearchResult(const []);
      if (fallbackAnswered) {
        return WorkshopSearchResult(const [], isComplete: false);
      }
      throw Exception(
          'Não foi possível consultar os estabelecimentos por nome. Tente novamente.');
    }
    // Fora do raio do Overpass a lista vem de buscas por relevância e nunca
    // é considerada completa.
    return _sorted(byId.values, center, isComplete: false);
  }

  Future<List<Workshop>> searchNearby(LatLng center,
      {int? radiusMeters,
      SearchBounds? boundingBox,
      bool automatic = false,
      bool forceRefresh = false,
      void Function(List<Workshop>)? onProgress}) async {
    final epoch = _epoch;
    final radius = radiusMeters ?? 8000;
    if (radius <= 0 || radius > 50000) {
      throw ArgumentError('Raio de busca inválido.');
    }
    if (boundingBox != null) {
      final b = boundingBox;
      if (![b.south, b.west, b.north, b.east].every((n) => n.isFinite) ||
          b.south >= b.north ||
          b.west >= b.east ||
          b.south < -90 ||
          b.north > 90 ||
          b.west < -180 ||
          b.east > 180) {
        throw ArgumentError('Área de busca inválida.');
      }
      if (const Distance(roundResult: false)(
              LatLng(b.south, b.west), LatLng(b.north, b.east)) >
          80000) {
        throw Exception(
            'Aproxime o mapa para buscar estabelecimentos nesta área.');
      }
    }
    final requested = SearchArea(center, radius: radius, bounds: boundingBox);
    await _cache.restore();
    _ensureCurrent(epoch);
    final cached = _cache.lookup(requested);
    if (cached != null && !forceRefresh) {
      return _sorted(cached, center,
          isComplete: cached.isComplete,
          isStale: cached.isStale,
          fromCache: true,
          fetchedAt: cached.fetchedAt);
    }
    final preview = cached ?? _cache.preview(requested);
    if (preview != null) onProgress?.call(preview);
    final area = requested.padded();
    final key = '${area.key}:$automatic';
    final pending = _pending[key];
    if (pending != null) {
      final result = await pending;
      _ensureCurrent(epoch);
      return _cache.withKnown(result, requested);
    }
    if (automatic &&
        _nextAutomaticAt != null &&
        now().isBefore(_nextAutomaticAt!)) {
      throw AutomaticSearchDeferred(_nextAutomaticAt!);
    }
    _nextAutomaticAt = now().add(const Duration(seconds: 8));
    void emit(List<Workshop> items) {
      _ensureCurrent(epoch);
      final result = items is WorkshopSearchResult
          ? items
          : WorkshopSearchResult(items, isComplete: false);
      onProgress?.call(_cache.withKnown(result, requested));
    }

    final future = _searchArea(area.center, area.radius, area.bounds,
        automatic: automatic, epoch: epoch, onProgress: emit);
    _pending[key] = future;
    try {
      final result = await future;
      _ensureCurrent(epoch);
      await _cache.put(area, result);
      return _cache.withKnown(result, requested);
    } on DiscoveryCancelled {
      rethrow;
    } catch (_) {
      _ensureCurrent(epoch);
      if (preview != null && preview.isNotEmpty) {
        return WorkshopSearchResult(preview,
            isComplete: preview.isComplete,
            isStale: true,
            fromCache: true,
            fetchedAt: preview.fetchedAt);
      }
      rethrow;
    } finally {
      if (identical(_pending[key], future)) _pending.remove(key);
    }
  }

  Future<WorkshopSearchResult> _searchArea(
      LatLng center, int radius, SearchBounds? box,
      {required bool automatic,
      required int epoch,
      required void Function(List<Workshop>) onProgress}) async {
    final area = box == null
        ? 'around:$radius,${center.latitude},${center.longitude}'
        : '${box.south},${box.west},${box.north},${box.east}';
    final query = _buildQuery(area);
    final partial = <String, Workshop>{};
    for (final endpoint in endpoints) {
      _ensureCurrent(epoch);
      if (!_endpointReady(endpoint)) continue;
      try {
        final response = await _overpassRequest(endpoint, query, epoch);
        final result = _parseOverpass(response, center, radius, box: box);
        if (result.isComplete) return result;
        for (final w in result) {
          partial[w.id] = w;
        }
        if (partial.isNotEmpty) {
          onProgress(_sorted(partial.values, center, isComplete: false));
        }
      } catch (_) {
        _ensureCurrent(epoch);
        if (_endpointReady(endpoint)) _markUnavailable(endpoint);
      }
    }
    void update(List<Workshop> items) {
      for (final w in items) {
        partial[w.id] = w;
      }
      if (partial.isNotEmpty) {
        onProgress(_sorted(partial.values, center, isComplete: false));
      }
    }

    // Navegação automática nunca usa o Nominatim para percorrer áreas.
    if (!automatic) {
      update(await _searchNominatimMatches(center, radius,
          box: box, epoch: epoch, onProgress: update));
    }
    if (automatic || partial.isEmpty) {
      update(await _searchPhoton(center, radius,
          box: box, epoch: epoch, onProgress: update));
    }
    _ensureCurrent(epoch);
    if (partial.isNotEmpty) {
      return _sorted(partial.values, center, isComplete: false);
    }
    throw Exception(
        'Não foi possível atualizar esta área. Os resultados já carregados foram mantidos.');
  }

  String _buildQuery(String area, {String nameFilter = ''}) {
    const selectors = [
      '["shop"="car_repair"]',
      '["craft"="car_repair"]',
      '["amenity"="car_wash"]',
      '["shop"="tyres"]',
      '["shop"="car_parts"]',
      '["shop"="car_accessories"]'
    ];
    final serviceKeys = Workshop.vehicleServices.keys.join('|');
    final allSelectors = [
      ...selectors,
      '[~"^service:vehicle:($serviceKeys)\$"~"^(yes|only)\$"]'
    ];
    final statements = allSelectors
        .map((selector) =>
            'nwr($area)$selector["shop"!~"^(car|motorcycle|motorcycle_repair|truck|truck_repair)\$"]$nameFilter;')
        .join('\n');
    // Sem corte de objetos: resposta completa cobre a área solicitada no OSM.
    return '[out:json][timeout:5];\n(\n$statements\n);\nout center tags;';
  }

  WorkshopSearchResult _parseOverpass(
      http.Response response, LatLng center, int radius,
      {SearchBounds? box}) {
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'];
    if (elements is! List) {
      throw const FormatException('Resposta sem elementos');
    }
    final workshops = <String, Workshop>{};
    for (final item in elements.whereType<Map<String, dynamic>>()) {
      final tags = item['tags'];
      if (tags is! Map<String, dynamic> || !Workshop.acceptsOsmTags(tags)) {
        continue;
      }
      try {
        final w = Workshop.fromOverpassJson(item);
        if (_inside(w, center, radius, box)) workshops[w.id] = w;
      } on TypeError {/* Um item inválido não descarta os demais. */}
    }
    return _sorted(workshops.values, center,
        isComplete: (decoded['remark']?.toString().trim() ?? '').isEmpty);
  }

  static const _photonTags = [
    'shop:car_repair',
    'craft:car_repair',
    'shop:tyres',
    'shop:car_parts',
    'shop:car_accessories',
    'amenity:car_wash'
  ];

  bool _endpointReady(String endpoint) =>
      !_unavailableUntil.containsKey(endpoint) ||
      !now().isBefore(_unavailableUntil[endpoint]!);

  void _markUnavailable(String endpoint, {http.Response? response}) {
    final failures = (_failures[endpoint] ?? 0) + 1;
    _failures[endpoint] = failures;
    var delay =
        Duration(seconds: math.min(600, 30 * (1 << math.min(5, failures))));
    final retry = response?.headers['retry-after'];
    final seconds = int.tryParse(retry ?? '');
    if (seconds != null && seconds > delay.inSeconds) {
      delay = Duration(seconds: seconds);
    }
    if (retry != null && seconds == null) {
      final match =
          RegExp(r'\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT')
              .firstMatch(retry);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      if (match != null && months.contains(match[2])) {
        final date = DateTime.utc(
            int.parse(match[3]!),
            months.indexOf(match[2]!) + 1,
            int.parse(match[1]!),
            int.parse(match[4]!),
            int.parse(match[5]!),
            int.parse(match[6]!));
        if (date.difference(now()) > delay) delay = date.difference(now());
      }
    }
    final until = now().add(delay);
    if (_unavailableUntil[endpoint] == null ||
        until.isAfter(_unavailableUntil[endpoint]!)) {
      _unavailableUntil[endpoint] = until;
    }
  }

  Future<http.Response> _overpassRequest(
      String endpoint, String query, int epoch) async {
    final response =
        await _request('POST', Uri.parse(endpoint), data: query, epoch: epoch);
    if (response.statusCode != 200) {
      _markUnavailable(endpoint, response: response);
    }
    return response;
  }

  /// Contingência de busca textual por relevância, limitada a dez correspondências
  /// por termo. Não enumera todos os POIs, não pagina e nunca é considerada completa.
  Future<List<Workshop>> _searchNominatimMatches(LatLng center, int radius,
      {SearchBounds? box,
      String? name,
      required int epoch,
      void Function(List<Workshop>)? onProgress,
      void Function()? onAnswered,
      bool global = false}) async {
    const endpoint = 'https://nominatim.openstreetmap.org/search';
    if (!_endpointReady(endpoint)) return [];
    // Na busca global o viewbox (35 km) só prioriza resultados próximos.
    final latDelta = (global ? 35000 : radius) / 111320;
    final lonDelta =
        latDelta / math.max(0.01, math.cos(center.latitude * math.pi / 180));
    final bounds = box ??
        (
          south: center.latitude - latDelta,
          north: center.latitude + latDelta,
          west: center.longitude - lonDelta,
          east: center.longitude + lonDelta
        );
    final terms = name == null
        ? const ['[shop=car_repair]', '[shop=tyres]', '[amenity=car_wash]']
        : [name];
    final found = <String, Workshop>{};
    for (final term in terms) {
      try {
        _ensureCurrent(epoch);
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': term,
          'format': 'jsonv2',
          'limit': '10',
          'extratags': '1',
          'addressdetails': '1',
          'countrycodes': 'br',
          if (!global) 'bounded': '1',
          'viewbox':
              '${bounds.west},${bounds.north},${bounds.east},${bounds.south}',
        });
        final response = await NominatimRequestQueue.run(() => _request(
            'GET', uri,
            timeout: const Duration(seconds: 8), epoch: epoch));
        if (response.statusCode != 200) {
          _markUnavailable(endpoint, response: response);
          break;
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) break;
        onAnswered?.call();
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          try {
            final category = (item['category'] ?? item['class'])?.toString();
            final extra = item['extratags'] as Map<String, dynamic>? ?? {};
            final address = item['address'] as Map<String, dynamic>? ?? {};
            final tags = <String, dynamic>{
              ...extra,
              if (category != null) category: item['type'],
              'name': item['name'],
              'addr:street': address['road'],
              'addr:housenumber': address['house_number'],
              'addr:suburb': address['suburb'],
              'addr:city': address['city'] ?? address['town'],
            };
            if (!Workshop.acceptsOsmTags(tags) || item['osm_id'] == null) {
              continue;
            }
            final type = item['osm_type'];
            if (!const ['node', 'way', 'relation'].contains(type)) continue;
            final w = Workshop.fromOverpassJson({
              'type': type,
              'id': item['osm_id'],
              'lat': item['lat'],
              'lon': item['lon'],
              'tags': tags
            });
            if (global ? _validPoint(w) : _inside(w, center, radius, box)) {
              found[w.id] = w;
            }
          } on TypeError {/* Um cadastro inválido não descarta os demais. */}
        }
        if (found.isNotEmpty) {
          onProgress?.call(_sorted(found.values, center, isComplete: false));
        }
      } catch (_) {
        _ensureCurrent(epoch);
        if (_endpointReady(endpoint)) _markUnavailable(endpoint);
        break;
      }
    }
    return found.values.toList();
  }

  Future<List<Workshop>> _searchPhoton(
    LatLng center,
    int radius, {
    List<String> terms = const [
      'oficina',
      'pneus',
      'lava jato',
    ],
    SearchBounds? box,
    required int epoch,
    void Function(List<Workshop>)? onProgress,
    void Function()? onAnswered,
    bool global = false,
  }) async {
    final latDelta = radius / 111320;
    final lonDelta =
        latDelta / math.max(0.01, math.cos(center.latitude * math.pi / 180));
    final bounds = box ??
        (
          south: math.max(-90.0, center.latitude - latDelta),
          north: math.min(90.0, center.latitude + latDelta),
          west: math.max(-180.0, center.longitude - lonDelta),
          east: math.min(180.0, center.longitude + lonDelta)
        );
    const endpoint = 'https://photon.komoot.io/api/';
    final lists = <List<Workshop>>[];
    for (final term in terms) {
      _ensureCurrent(epoch);
      if (!_endpointReady(endpoint)) break;
      try {
        final uri = Uri.https('photon.komoot.io', '/api/', <String, dynamic>{
          'q': term,
          'lat': '${center.latitude}',
          'lon': '${center.longitude}',
          'limit': '50',
          'osm_tag': _photonTags,
          // Sem bbox na busca global: lat/lon apenas priorizam a proximidade.
          if (!global)
            'bbox':
                '${bounds.west},${bounds.south},${bounds.east},${bounds.north}',
        });
        final response = await _request('GET', uri,
            timeout: const Duration(seconds: 4), epoch: epoch);
        if (response.statusCode != 200) {
          _markUnavailable(endpoint, response: response);
          break;
        }
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        onAnswered?.call();
        final workshops = <Workshop>[];
        for (final feature in (decoded['features'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()) {
          try {
            final w = _fromPhoton(feature, brazilOnly: global);
            if (w != null &&
                (global ? _validPoint(w) : _inside(w, center, radius, box))) {
              workshops.add(w);
            }
          } on TypeError {/* Ignora somente o item inválido. */}
        }
        lists.add(workshops);
        if (workshops.isNotEmpty) {
          onProgress?.call(lists.expand((l) => l).toList());
        }
      } catch (_) {
        _ensureCurrent(epoch);
        if (_endpointReady(endpoint)) _markUnavailable(endpoint);
        break;
      }
    }
    return {for (final w in lists.expand((list) => list)) w.id: w}
        .values
        .toList();
  }

  Workshop? _fromPhoton(Map<String, dynamic> feature,
      {bool brazilOnly = false}) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    // O Photon não filtra por país; sem bbox, descarta resultados de fora.
    final country = props['countrycode']?.toString().toUpperCase();
    if (brazilOnly && country != null && country != 'BR') return null;
    final key = props['osm_key']?.toString();
    final extra = props['extra'] as Map<String, dynamic>? ?? {};
    final tags = <String, dynamic>{
      ...extra,
      if (key != null) key: props['osm_value'],
      'name': props['name'],
      'addr:street': props['street'],
      'addr:housenumber': props['housenumber'],
      'addr:suburb': props['district'] ?? props['locality'],
      'addr:city': props['city']
    };
    if (!Workshop.acceptsOsmTags(tags)) return null;
    final coords =
        (feature['geometry'] as Map<String, dynamic>?)?['coordinates'];
    if (coords is! List ||
        coords.length < 2 ||
        coords[0] is! num ||
        coords[1] is! num) {
      return null;
    }
    final type = switch (props['osm_type']?.toString().toLowerCase()) {
      'n' || 'node' => 'node',
      'w' || 'way' => 'way',
      'r' || 'relation' => 'relation',
      _ => null,
    };
    if (type == null || props['osm_id'] == null) return null;
    return Workshop.fromOverpassJson({
      'type': type,
      'id': props['osm_id'],
      'lat': coords[1],
      'lon': coords[0],
      'tags': tags
    });
  }

  bool _validPoint(Workshop w) {
    final lat = w.latitude, lon = w.longitude;
    return lat != null &&
        lon != null &&
        lat.isFinite &&
        lon.isFinite &&
        lat.abs() <= 90 &&
        lon.abs() <= 180 &&
        !w.isExcludedFromDiscovery;
  }

  bool _inside(Workshop w, LatLng center, int radius, SearchBounds? box) {
    if (!_validPoint(w)) return false;
    final lat = w.latitude!, lon = w.longitude!;
    if (box != null) {
      return lat >= box.south &&
          lat <= box.north &&
          lon >= box.west &&
          lon <= box.east;
    }
    return const Distance(roundResult: false)
            .as(LengthUnit.Meter, center, LatLng(lat, lon)) <=
        radius;
  }

  WorkshopSearchResult _sorted(Iterable<Workshop> workshops, LatLng center,
      {bool isComplete = true,
      bool isStale = false,
      bool fromCache = false,
      DateTime? fetchedAt}) {
    final result = workshops
        .map((w) => w.copyWith(
            distanceKm: const Distance(roundResult: false).as(
                LengthUnit.Kilometer,
                center,
                LatLng(w.latitude!, w.longitude!))))
        .toList()
      ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return WorkshopSearchResult(result,
        isComplete: isComplete,
        isStale: isStale,
        fromCache: fromCache,
        fetchedAt: fetchedAt);
  }

  Future<http.Response> _request(String method, Uri uri,
      {String? data, Duration? timeout, required int epoch}) async {
    final previous = _networkTail;
    final released = Completer<void>();
    _networkTail = released.future;
    await previous;
    try {
      _ensureCurrent(epoch);
      final last = _lastRequestStart;
      if (last != null) {
        final remaining =
            minimumRequestInterval - DateTime.now().difference(last);
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      _ensureCurrent(epoch);
      _lastRequestStart = DateTime.now();
      final abort = Completer<void>();
      _activeRequests.add(abort);
      final request =
          http.AbortableRequest(method, uri, abortTrigger: abort.future)
            ..headers.addAll(headers);
      if (data != null) request.bodyFields = {'data': data};
      try {
        final response = await Future.any<http.Response>([
          client.send(request).then(http.Response.fromStream),
          abort.future
              .then<http.Response>((_) => throw const DiscoveryCancelled()),
        ]).timeout(timeout ?? requestTimeout, onTimeout: () {
          if (!abort.isCompleted) abort.complete();
          throw TimeoutException('Tempo de consulta excedido');
        });
        _ensureCurrent(epoch);
        return response;
      } finally {
        _activeRequests.remove(abort);
      }
    } finally {
      released.complete();
    }
  }

  void dispose() {
    cancelPending();
    _disposed = true;
    for (final abort in _activeRequests) {
      if (!abort.isCompleted) abort.complete();
    }
    _activeRequests.clear();
    client.close();
  }
}
