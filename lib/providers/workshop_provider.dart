import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';
import '../models/workshop.dart';
import '../models/workshop_search_result.dart';
import '../utils/search_text.dart';
import '../services/location_service.dart';
import '../services/open_street_map_service.dart';
import '../services/workshop_discovery_service.dart';

class WorkshopProvider extends ChangeNotifier {
  WorkshopProvider({
    OpenStreetMapService? openStreetMapService,
    LocationService? locationService,
  })  : _openStreetMapService = openStreetMapService ?? OpenStreetMapService(),
        _locationService = locationService ?? LocationService();

  static const _favoritesKey = 'favorite_workshop_ids';
  static const _favoriteDataKey = 'favorite_workshop_data';
  static const _recentSearchesKey = 'recent_search_terms';
  static const _customWorkshopsKey = 'custom_registered_workshops_v1';
  static const _reviewsKey = 'workshop_reviews_cache_v1';
  static const _lastKnownLatKey = 'last_known_device_lat';
  static const _lastKnownLngKey = 'last_known_device_lng';

  final Map<String, List<WorkshopReview>> _reviewsByWorkshop = {};

  static const autobahnPartner = Workshop(
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
    supportedBrands: [
      'Volkswagen',
      'Audi',
      'BMW',
      'Mercedes-Benz',
      'Todas as marcas'
    ],
    specialties: [
      'Injeção Eletrônica',
      'Câmbio Automático',
      'Motor',
      'Freios e Suspensão'
    ],
    description:
        'Oficina especializada em mecânica geral, diagnóstico eletrônico computadorizado e manutenção preventiva.',
  );

  final OpenStreetMapService _openStreetMapService;
  final LocationService _locationService;

  List<Workshop> _workshops = [];
  List<Workshop> _customWorkshops = [];
  final Map<String, Workshop> _savedWorkshops = {};
  int _searchGeneration = 0;
  String? _pendingSearch;
  bool _disposed = false;
  Set<String> _favoriteIds = {};
  List<String> _recentSearches = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchNotice;
  bool _resultsStale = false;
  DateTime? _automaticRetryAt;
  bool _lastSearchAutomatic = false;
  Future<void> Function()? _retryAction;
  int _activeRadiusMeters = 8000;
  ({double south, double west, double north, double east})? _activeBounds;
  bool _hasSearched = false;
  LatLng? _searchCenter;
  LatLng? _deviceLocation;

  String _searchQuery = '';
  WorkshopCategory? _selectedCategory;
  Workshop? _selectedWorkshop;
  bool _onlyCompatibleWithVehicle = false;

  List<Workshop> get workshops => List.unmodifiable(_workshops);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get searchNotice => _searchNotice;
  bool get resultsStale => _resultsStale;
  DateTime? get automaticRetryAt => _automaticRetryAt;
  bool get lastSearchAutomatic => _lastSearchAutomatic;
  void cancelAutomaticSearch() {
    if (!_isLoading || !_lastSearchAutomatic) return;
    _searchGeneration++;
    _openStreetMapService.cancelDiscoverySearches();
    _isLoading = false;
    _pendingSearch = null;
    notifyListeners();
  }

  bool get hasSearched => _hasSearched;
  LatLng? get searchCenter => _searchCenter;
  LatLng? get deviceLocation => _deviceLocation;
  Set<String> get favoriteIds => _favoriteIds;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  String get searchQuery => _searchQuery;
  WorkshopCategory? get selectedCategory => _selectedCategory;
  Workshop? get selectedWorkshop => _selectedWorkshop;
  bool get onlyCompatibleWithVehicle => _onlyCompatibleWithVehicle;

  List<Workshop> get favoriteWorkshops {
    final list = <Workshop>[];
    for (final id in _favoriteIds) {
      final w = _savedWorkshops[id] ??
          _customWorkshops.where((cw) => cw.id == id).firstOrNull ??
          _workshops.where((osm) => osm.id == id).firstOrNull ??
          (autobahnPartner.id == id ? autobahnPartner : null);
      if (w != null) {
        list.add(w);
      }
    }
    return list;
  }

  List<Workshop> get customWorkshops => List.unmodifiable(_customWorkshops);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> initialize({bool searchOnStart = true}) async {
    final preferences = await SharedPreferences.getInstance();
    _favoriteIds = preferences.getStringList(_favoritesKey)?.toSet() ?? {};
    _recentSearches = preferences.getStringList(_recentSearchesKey) ?? [];
    for (final raw
        in preferences.getStringList(_favoriteDataKey) ?? <String>[]) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        Workshop? workshop;
        if (data.containsKey('tags')) {
          workshop = Workshop.fromOverpassJson(data);
        } else {
          workshop = Workshop.fromJson(data);
        }
        if (_favoriteIds.contains(workshop.id)) {
          _savedWorkshops[workshop.id] = workshop;
        }
      } catch (_) {/* Ignore an invalid saved entry. */}
    }

    final customRaw =
        preferences.getStringList(_customWorkshopsKey) ?? <String>[];
    _customWorkshops = [];
    for (final raw in customRaw) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _customWorkshops.add(Workshop.fromJson(data));
      } catch (_) {/* Ignore an invalid entry. */}
    }

    final reviewsRaw = preferences.getString(_reviewsKey);
    if (reviewsRaw != null) {
      try {
        final decoded = jsonDecode(reviewsRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final listJson = entry.value as List<dynamic>;
          _reviewsByWorkshop[entry.key] = listJson
              .map((j) => WorkshopReview.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {/* Ignore corrupted reviews cache */}
    }

    // Garante que oficinas favoritas customizadas ou parceiras estejam disponíveis
    for (final id in _favoriteIds) {
      if (!_savedWorkshops.containsKey(id)) {
        final match = _customWorkshops.where((w) => w.id == id).firstOrNull ??
            (autobahnPartner.id == id ? autobahnPartner : null);
        if (match != null) {
          _savedWorkshops[id] = match;
        }
      }
    }

    // Carrega instantaneamente a última localização conhecida do usuário (elimina o salto de Brasília)
    final savedLat = preferences.getDouble(_lastKnownLatKey);
    final savedLng = preferences.getDouble(_lastKnownLngKey);
    if (savedLat != null && savedLng != null) {
      _deviceLocation = LatLng(savedLat, savedLng);
      _searchCenter = _deviceLocation;
      _openStreetMapService.proximityCenter = _deviceLocation;
    }

    if (!_disposed) notifyListeners();
    unawaited(_syncCloudWorkshops());
    if (searchOnStart && !_disposed && !_hasSearched) {
      await searchWorkshops();
    }
  }

  Future<void> _syncCloudWorkshops() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('workshops')
          .get()
          .timeout(const Duration(seconds: 8));
      if (_disposed || snapshot.docs.isEmpty) return;
      final cloudList = <Workshop>[];
      for (final doc in snapshot.docs) {
        try {
          cloudList.add(Workshop.fromJson({...doc.data(), 'id': doc.id}));
        } catch (_) {/* Ignora somente o cadastro inválido. */}
      }
      if (cloudList.isEmpty) return;
      _customWorkshops = cloudList;
      notifyListeners();
      final preferences = await SharedPreferences.getInstance();
      if (_disposed) return;
      await preferences.setStringList(_customWorkshopsKey,
          cloudList.map((w) => jsonEncode(w.toJson())).toList());
    } catch (error) {
      debugPrint('Firestore fetch workshops fallback: $error');
    }
  }

  Future<void> searchWorkshops({
    String city = '',
    String query = '',
    LatLng? customCenter,
    int? radiusMeters,
    ({double south, double west, double north, double east})? boundingBox,
    bool automatic = false,
    bool forceRefresh = false,
  }) async {
    final term = (query.isNotEmpty ? query : city).trim();
    final key = '$term|$customCenter|$radiusMeters|$boundingBox';
    if (_isLoading && _pendingSearch == key) return;
    _retryAction = () => searchWorkshops(
        city: city,
        query: query,
        customCenter: customCenter,
        radiusMeters: radiusMeters,
        boundingBox: boundingBox,
        forceRefresh: true);
    final generation = ++_searchGeneration;
    _lastSearchAutomatic = automatic;
    _openStreetMapService.cancelDiscoverySearches();
    _pendingSearch = key;
    _isLoading = true;
    _errorMessage = null;
    _searchNotice = null;
    _automaticRetryAt = null;
    _hasSearched = true;
    _selectedWorkshop = null;
    if (term.isNotEmpty) {
      _searchQuery = term;
      unawaited(addRecentSearch(term));
    } else if (customCenter == null) {
      _searchQuery = '';
    }
    notifyListeners();
    bool stale() => _disposed || generation != _searchGeneration;
    Future<List<Workshop>> nearby(LatLng center,
            {int? radius,
            ({
              double south,
              double west,
              double north,
              double east
            })? bounds}) =>
        _openStreetMapService.searchNearbyWorkshops(center,
            radiusMeters: radius,
            boundingBox: bounds,
            automatic: automatic,
            forceRefresh: forceRefresh, onProgress: (items) {
          if (!stale()) {
            _acceptResults(items);
            notifyListeners();
          }
        });
    try {
      if (customCenter != null) {
        _setSearchArea(customCenter,
            radius: radiusMeters ?? 8000, bounds: boundingBox);
        final results = await nearby(customCenter,
            radius: radiusMeters, bounds: boundingBox);
        if (!stale()) _acceptResults(results);
        return;
      }
      if (city.trim().isNotEmpty) {
        final center = await _openStreetMapService.geocodeCity(city.trim());
        if (stale()) return;
        _searchQuery = ''; // A cidade define a área, não um filtro de endereço.
        _setSearchArea(center);
        final results = await nearby(center);
        if (!stale()) _acceptResults(results);
        return;
      }
      if (term.isEmpty) {
        final center = await _locationService.getCurrentLocation();
        if (stale()) return;
        _deviceLocation = center;
        _setSearchArea(center);
        final preferences = await SharedPreferences.getInstance();
        if (stale()) return;
        await preferences.setDouble(_lastKnownLatKey, center.latitude);
        await preferences.setDouble(_lastKnownLngKey, center.longitude);
        if (stale()) return;
        final results = await nearby(center);
        if (!stale()) _acceptResults(results);
        return;
      }
      final category = Workshop.categoryForSearch(term);
      final localMatches = getFilteredWorkshops(null);
      final localPoint = localMatches
          .where((w) => w.latitude != null && w.longitude != null)
          .firstOrNull;
      final reference = _searchCenter ??
          _deviceLocation ??
          (localPoint == null
              ? null
              : LatLng(localPoint.latitude!, localPoint.longitude!));
      if (category != null) {
        _selectedCategory = category;
        final center = reference ?? await _locationService.getCurrentLocation();
        if (stale()) return;
        _setSearchArea(center);
        final results = await nearby(center);
        if (!stale()) _acceptResults(results);
        return;
      }
      // Oficinas cadastradas no app respondem pelo nome em qualquer região,
      // não só na área que o mapa já exibiu.
      final knownMatches = {
        for (final w in [
          ...localMatches,
          ..._customWorkshops.where((w) =>
              !w.isExcludedFromDiscovery &&
              w.latitude != null &&
              w.longitude != null &&
              _matchesText(w, term)),
        ])
          w.id: w
      }.values.toList();
      Object? nameFailure;
      var nameSearchAnswered = false;
      if (reference != null) {
        try {
          final results = await _openStreetMapService.searchWorkshopsByName(
              term, reference);
          if (stale()) return;
          nameSearchAnswered = true;
          // A consulta remota foi executada mesmo quando já havia correspondência local.
          if (results.isNotEmpty || knownMatches.isNotEmpty) {
            _showNameResults(reference, results, knownMatches);
            return;
          }
        } on DiscoveryCancelled {
          rethrow;
        } catch (error) {
          nameFailure = error;
          if (stale()) return;
          if (knownMatches.isNotEmpty) {
            _showNameResults(reference, const [], knownMatches);
            return;
          }
        }
      }
      LatLng center;
      if (stale()) return;
      try {
        _openStreetMapService.proximityCenter = reference;
        center = await _openStreetMapService.geocodeCity(term);
      } catch (error) {
        if (stale()) return;
        // O nome foi consultado com sucesso e o termo também não é um local:
        // a busca terminou sem correspondências, o que não é um erro.
        if (nameSearchAnswered && reference != null) {
          _setSearchArea(reference, radius: 35000);
          _workshops = [];
          _searchNotice = null;
          _resultsStale = false;
          _selectedWorkshop = null;
          return;
        }
        throw nameFailure ?? error;
      }
      if (stale()) return;
      _searchQuery = '';
      _setSearchArea(center);
      final results = await nearby(center);
      if (!stale()) _acceptResults(results);
    } on AutomaticSearchDeferred catch (deferred) {
      if (!stale()) _automaticRetryAt = deferred.until;
    } on DiscoveryCancelled {
      // Uma busca mais recente assumiu o controle da tela.
    } catch (error) {
      if (!stale()) {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (!stale()) {
        _isLoading = false;
        _pendingSearch = null;
        notifyListeners();
      }
    }
  }

  /// Exibe o resultado da busca por nome. A área ativa é ampliada até a
  /// correspondência mais distante; caso contrário, oficinas encontradas fora
  /// da região já exibida no mapa seriam descartadas pelo filtro de área.
  void _showNameResults(
      LatLng reference, List<Workshop> remote, List<Workshop> known) {
    const distance = Distance(roundResult: false);
    var radius = 35000.0;
    for (final w in [...remote, ...known]) {
      if (w.latitude == null || w.longitude == null) continue;
      radius = math.max(
          radius,
          distance.as(LengthUnit.Meter, reference,
                  LatLng(w.latitude!, w.longitude!)) +
              500);
    }
    _setSearchArea(reference, radius: radius.ceil());
    _acceptResults(remote.isNotEmpty ? remote : known);
    _selectedWorkshop = getFilteredWorkshops(null).firstOrNull;
  }

  void _setSearchArea(LatLng center,
      {int radius = 8000,
      ({double south, double west, double north, double east})? bounds}) {
    _searchCenter = center;
    _activeRadiusMeters = radius;
    _activeBounds = bounds;
    _openStreetMapService.proximityCenter = center;
    notifyListeners();
  }

  void _acceptResults(List<Workshop> results) {
    _searchNotice = results is WorkshopSearchResult ? results.notice : null;
    _resultsStale = results is WorkshopSearchResult && results.isStale;
    _workshops = {
      if (results is WorkshopSearchResult &&
          (!results.isComplete || results.isStale))
        for (final w in _workshops)
          if (!w.isExcludedFromDiscovery && _withinCurrentArea(w)) w.id: w,
      for (final w in results)
        if (!w.isExcludedFromDiscovery) w.id: w
    }.values.toList();
    _sortByDistance(_workshops);
    // Preserva a recuperação de coordenadas de cadastros antigos sem posição.
    var changed = false;
    for (var i = 0; i < _customWorkshops.length; i++) {
      final custom = _customWorkshops[i];
      if (custom.latitude != null && custom.longitude != null) continue;
      final match = _workshops
          .where((w) =>
              w.latitude != null &&
              w.longitude != null &&
              normalizeSearchText(w.name) == normalizeSearchText(custom.name))
          .firstOrNull;
      if (match != null) {
        _customWorkshops[i] = custom.copyWith(
            latitude: match.latitude, longitude: match.longitude);
        changed = true;
      }
    }
    if (changed) unawaited(_persistCustomCoordinates());
  }

  Future<void> _persistCustomCoordinates() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_customWorkshopsKey,
        _customWorkshops.map((w) => jsonEncode(w.toJson())).toList());
  }

  Future<void> retrySearch() {
    return _retryAction?.call() ?? searchWorkshops();
  }

  void _sortByDistance(List<Workshop> list) {
    final center = _searchCenter;
    if (center == null) return;
    for (var i = 0; i < list.length; i++) {
      final w = list[i];
      if (w.latitude != null && w.longitude != null) {
        list[i] = w.copyWith(
            distanceKm: const Distance(roundResult: false).as(
                LengthUnit.Kilometer,
                center,
                LatLng(w.latitude!, w.longitude!)));
      }
    }
    list.sort((a, b) => (a.distanceKm ?? double.infinity)
        .compareTo(b.distanceKm ?? double.infinity));
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(WorkshopCategory? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void setSelectedWorkshop(Workshop? workshop) {
    _selectedWorkshop = workshop;
    notifyListeners();
  }

  void selectWorkshop(Workshop? workshop) => setSelectedWorkshop(workshop);

  void toggleOnlyCompatible() {
    _onlyCompatibleWithVehicle = !_onlyCompatibleWithVehicle;
    notifyListeners();
  }

  Future<void> addRecentSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 8) {
      _recentSearches = _recentSearches.sublist(0, 8);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_recentSearchesKey, _recentSearches);
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_recentSearchesKey);
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> toggleFavorite(String workshopId, [Workshop? workshop]) async {
    if (_favoriteIds.remove(workshopId)) {
      _savedWorkshops.remove(workshopId);
    } else {
      final found = workshop ??
          _savedWorkshops[workshopId] ??
          _customWorkshops.where((w) => w.id == workshopId).firstOrNull ??
          _workshops.where((w) => w.id == workshopId).firstOrNull ??
          (_selectedWorkshop?.id == workshopId ? _selectedWorkshop : null) ??
          (autobahnPartner.id == workshopId ? autobahnPartner : null);

      if (found == null) return;
      _favoriteIds.add(workshopId);
      _savedWorkshops[workshopId] = found;
    }
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_favoritesKey, _favoriteIds.toList());
    await preferences.setStringList(
      _favoriteDataKey,
      _savedWorkshops.values.map((w) => jsonEncode(w.toJson())).toList(),
    );
  }

  Future<void> registerCustomWorkshop(Workshop workshop) async {
    _customWorkshops.removeWhere((w) => w.id == workshop.id);
    _customWorkshops.insert(0, workshop);
    final preferences = await SharedPreferences.getInstance();
    final jsonList =
        _customWorkshops.map((w) => jsonEncode(w.toJson())).toList();
    await preferences.setStringList(_customWorkshopsKey, jsonList);
    if (!_disposed) notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('workshops')
          .doc(workshop.id)
          .set(workshop.toJson());
    } catch (e) {
      debugPrint('Firestore register workshop error: $e');
    }
  }

  Future<void> removeCustomWorkshop(String workshopId) async {
    _customWorkshops.removeWhere((w) => w.id == workshopId);
    final preferences = await SharedPreferences.getInstance();
    final jsonList =
        _customWorkshops.map((w) => jsonEncode(w.toJson())).toList();
    await preferences.setStringList(_customWorkshopsKey, jsonList);
    if (!_disposed) notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('workshops')
          .doc(workshopId)
          .delete();
    } catch (e) {
      debugPrint('Firestore delete workshop error: $e');
    }
  }

  List<WorkshopReview> getReviewsForWorkshop(String workshopId) {
    return _reviewsByWorkshop[workshopId] ?? const [];
  }

  Future<void> addReview({
    required String workshopId,
    required WorkshopReview review,
  }) async {
    final list = List<WorkshopReview>.from(_reviewsByWorkshop[workshopId] ?? []);
    list.insert(0, review);
    _reviewsByWorkshop[workshopId] = list;

    final totalScore = list.fold<double>(0, (acc, r) => acc + r.rating);
    final avgRating = double.parse((totalScore / list.length).toStringAsFixed(1));
    final ratingCount = list.length;

    // Atualiza em _workshops se presente
    final osmIndex = _workshops.indexWhere((w) => w.id == workshopId);
    if (osmIndex != -1) {
      _workshops[osmIndex] = _workshops[osmIndex].copyWith(
        reviews: list,
        rating: avgRating,
        ratingCount: ratingCount,
      );
    }

    // Atualiza em _customWorkshops se presente
    final customIndex = _customWorkshops.indexWhere((w) => w.id == workshopId);
    if (customIndex != -1) {
      _customWorkshops[customIndex] = _customWorkshops[customIndex].copyWith(
        reviews: list,
        rating: avgRating,
        ratingCount: ratingCount,
      );
      final preferences = await SharedPreferences.getInstance();
      final jsonList =
          _customWorkshops.map((w) => jsonEncode(w.toJson())).toList();
      await preferences.setStringList(_customWorkshopsKey, jsonList);
    }

    // Atualiza em _savedWorkshops
    if (_savedWorkshops.containsKey(workshopId)) {
      _savedWorkshops[workshopId] = _savedWorkshops[workshopId]!.copyWith(
        reviews: list,
        rating: avgRating,
        ratingCount: ratingCount,
      );
    }

    if (_selectedWorkshop?.id == workshopId) {
      _selectedWorkshop = _selectedWorkshop!.copyWith(
        reviews: list,
        rating: avgRating,
        ratingCount: ratingCount,
      );
    }

    // Salva no SharedPreferences
    final preferences = await SharedPreferences.getInstance();
    final serialized = <String, dynamic>{};
    _reviewsByWorkshop.forEach((key, revs) {
      serialized[key] = revs.map((r) => r.toJson()).toList();
    });
    await preferences.setString(_reviewsKey, jsonEncode(serialized));

    if (!_disposed) notifyListeners();

    // Sincroniza em background com Cloud Firestore
    try {
      await FirebaseFirestore.instance
          .collection('workshop_reviews')
          .doc(workshopId)
          .collection('reviews')
          .add(review.toJson());

      await FirebaseFirestore.instance
          .collection('workshops')
          .doc(workshopId)
          .set({
        'rating': avgRating,
        'ratingCount': ratingCount,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore addReview sync: $e');
    }
  }

  List<Workshop> getFilteredWorkshops(Vehicle? activeVehicle) {
    final custom = _customWorkshops
        .where((w) => !w.isExcludedFromDiscovery && _withinCurrentArea(w))
        .toList();
    final all = <Workshop>[
      if (normalizeSearchText(_searchQuery).contains('autobahn') &&
          !custom.any((w) => normalizeSearchText(w.name).contains('autobahn')))
        autobahnPartner,
      ...custom,
      ..._workshops.where((osm) => !custom.any((w) {
            if (w.id == osm.id) return true;
            if (normalizeSearchText(w.name) != normalizeSearchText(osm.name) ||
                w.latitude == null ||
                w.longitude == null ||
                osm.latitude == null ||
                osm.longitude == null) {
              return false;
            }
            return const Distance(roundResult: false).as(
                    LengthUnit.Meter,
                    LatLng(w.latitude!, w.longitude!),
                    LatLng(osm.latitude!, osm.longitude!)) <
                100;
          })),
    ].map((w) {
      final reviews = _reviewsByWorkshop[w.id];
      if (reviews != null && reviews.isNotEmpty) {
        final totalScore = reviews.fold<double>(0, (acc, r) => acc + r.rating);
        final avgRating =
            double.parse((totalScore / reviews.length).toStringAsFixed(1));
        return w.copyWith(
          reviews: reviews,
          rating: avgRating,
          ratingCount: reviews.length,
        );
      }
      return w;
    }).toList();
    final categoryQuery = Workshop.categoryForSearch(_searchQuery);
    final result = all.where((w) {
      if (w.isExcludedFromDiscovery || !_withinCurrentArea(w)) return false;
      if (_selectedCategory != null && !w.matchesCategory(_selectedCategory!)) {
        return false;
      }
      if (categoryQuery != null) {
        if (!w.matchesCategory(categoryQuery)) return false;
      } else if (!_matchesText(w, _searchQuery)) {
        return false;
      }
      if (_onlyCompatibleWithVehicle &&
          activeVehicle != null &&
          w.calculateCompatibility(activeVehicle).percentage < 90) {
        return false;
      }
      return true;
    }).toList();
    // Cadastros da região e OSM usam a mesma ordenação por proximidade.
    _sortByDistance(result);
    return result;
  }

  bool _withinCurrentArea(Workshop w) {
    if (_searchCenter == null) return true;
    final lat = w.latitude, lon = w.longitude;
    if (lat == null || lon == null) return false;
    final box = _activeBounds;
    if (box != null) {
      return lat >= box.south &&
          lat <= box.north &&
          lon >= box.west &&
          lon <= box.east;
    }
    return const Distance(roundResult: false)
            .as(LengthUnit.Meter, _searchCenter!, LatLng(lat, lon)) <=
        _activeRadiusMeters;
  }

  bool _matchesText(Workshop w, String query) {
    final q = normalizeSearchText(query);
    if (q.isEmpty) return true;
    final text = normalizeSearchText([
      w.name,
      w.address,
      w.category,
      w.categoryType.label,
      ...w.additionalCategories.map((c) => c.label),
      ...w.supportedBrands,
      ...w.specialties,
      ...w.services.map((s) => s.name)
    ].join(' '));
    if (text.contains(q)) return true;
    const stopWords = {'de', 'da', 'do', 'das', 'dos', 'e', 'em', 'na', 'no'};
    final tokens =
        q.split(' ').where((token) => !stopWords.contains(token)).toList();
    return tokens.isNotEmpty && tokens.every(text.contains);
  }

  @override
  void dispose() {
    _disposed = true;
    _searchGeneration++;
    _openStreetMapService.dispose();
    super.dispose();
  }
}
