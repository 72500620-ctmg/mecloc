import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';
import '../models/workshop.dart';
import '../services/location_service.dart';
import '../services/open_street_map_service.dart';

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
  bool _hasSearched = false;
  LatLng? _searchCenter;

  String _searchQuery = '';
  WorkshopCategory? _selectedCategory;
  Workshop? _selectedWorkshop;
  bool _onlyCompatibleWithVehicle = false;

  List<Workshop> get workshops => List.unmodifiable(_workshops);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSearched => _hasSearched;
  LatLng? get searchCenter => _searchCenter;
  Set<String> get favoriteIds => _favoriteIds;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  String get searchQuery => _searchQuery;
  WorkshopCategory? get selectedCategory => _selectedCategory;
  Workshop? get selectedWorkshop => _selectedWorkshop;
  bool get onlyCompatibleWithVehicle => _onlyCompatibleWithVehicle;

  List<Workshop> get favoriteWorkshops => _savedWorkshops.values.toList();
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
        final workshop = Workshop.fromOverpassJson(data);
        if (_favoriteIds.contains(workshop.id)) {
          _savedWorkshops[workshop.id] = workshop;
        }
      } catch (_) {/* Ignore an invalid saved entry. */}
    }

    final customRaw = preferences.getStringList(_customWorkshopsKey) ?? <String>[];
    _customWorkshops = [];
    for (final raw in customRaw) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _customWorkshops.add(Workshop.fromJson(data));
      } catch (_) {/* Ignore an invalid entry. */}
    }

    // Tenta sincronizar com o Cloud Firestore da nuvem
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('workshops').get();
      if (snapshot.docs.isNotEmpty) {
        final cloudList = <Workshop>[];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            cloudList.add(Workshop.fromJson(data));
          } catch (_) {}
        }
        if (cloudList.isNotEmpty) {
          _customWorkshops = cloudList;
          final jsonList =
              _customWorkshops.map((w) => jsonEncode(w.toJson())).toList();
          await preferences.setStringList(_customWorkshopsKey, jsonList);
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch workshops fallback: $e');
    }

    if (!_disposed) notifyListeners();
    if (searchOnStart && !_disposed && !_hasSearched) {
      await searchWorkshops();
    }
  }

  Future<void> searchWorkshops({
    String city = '',
    LatLng? customCenter,
  }) async {
    final searchKey = customCenter != null
        ? '${customCenter.latitude.toStringAsFixed(4)},${customCenter.longitude.toStringAsFixed(4)}'
        : city.trim().toLowerCase();
    if (_isLoading && _pendingSearch == searchKey) return;
    _pendingSearch = searchKey;
    final generation = ++_searchGeneration;
    _isLoading = true;
    _errorMessage = null;
    _hasSearched = true;
    _selectedWorkshop = null;
    notifyListeners();

    try {
      final center = customCenter ??
          (city.trim().isEmpty
              ? await _locationService.getCurrentLocation()
              : await _openStreetMapService.geocodeCity(city));
      if (_disposed || generation != _searchGeneration) return;
      // Recentrar assim que a localização for resolvida. A consulta de oficinas
      // pode falhar separadamente, e não deve fazer a busca de cidade parecer
      // ignorada nem manter o mapa na região anterior.
      _searchCenter = center;
      notifyListeners();
      final results = await _openStreetMapService.searchNearbyWorkshops(center);
      if (_disposed || generation != _searchGeneration) return;
      _workshops = results;

      // Auto-heal: caso alguma oficina customizada esteja salva sem coordenadas,
      // recupera as coordenadas exatas a partir dos resultados do OpenStreetMap
      var hasHealed = false;
      for (var i = 0; i < _customWorkshops.length; i++) {
        final cw = _customWorkshops[i];
        if (cw.latitude == null || cw.longitude == null) {
          final match = results.where((osm) =>
              osm.latitude != null &&
              osm.longitude != null &&
              osm.name.toLowerCase().trim() == cw.name.toLowerCase().trim()).firstOrNull;
          if (match != null) {
            _customWorkshops[i] = cw.copyWith(
              latitude: match.latitude,
              longitude: match.longitude,
            );
            hasHealed = true;
          }
        }
      }
      if (hasHealed) {
        final preferences = await SharedPreferences.getInstance();
        final jsonList = _customWorkshops.map((w) => jsonEncode(w.toJson())).toList();
        await preferences.setStringList(_customWorkshopsKey, jsonList);
      }
    } catch (error) {
      if (_disposed || generation != _searchGeneration) return;
      _workshops = [];
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!_disposed && generation == _searchGeneration) {
        _isLoading = false;
        _pendingSearch = null;
        notifyListeners();
      }
    }
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
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_recentSearchesKey);
    notifyListeners();
  }

  Future<void> toggleFavorite(String workshopId) async {
    if (_favoriteIds.remove(workshopId)) {
      _savedWorkshops.remove(workshopId);
    } else {
      final matches = _workshops.where((w) => w.id == workshopId);
      if (matches.isEmpty) return;
      _favoriteIds.add(workshopId);
      _savedWorkshops[workshopId] = matches.first;
    }
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_favoritesKey, _favoriteIds.toList());
    await preferences.setStringList(
        _favoriteDataKey,
        _savedWorkshops.values.map((w) {
          final parts = w.id.split(':');
          return jsonEncode({
            'type': parts.length > 1 ? parts[1] : 'node',
            'id': parts.length > 2 ? int.tryParse(parts[2]) : null,
            'lat': w.latitude,
            'lon': w.longitude,
            'tags': {
              'name': w.name,
              'addr:street': w.address,
              if (w.phone != null) 'phone': w.phone,
              if (w.openingHours != 'Horário não informado')
                'opening_hours': w.openingHours,
              if (w.categoryType == WorkshopCategory.tireShop) 'shop': 'tyres',
              if (w.categoryType == WorkshopCategory.carWash)
                'amenity': 'car_wash'
            },
          });
        }).toList());
  }

  Future<void> registerCustomWorkshop(Workshop workshop) async {
    _customWorkshops.removeWhere((w) => w.id == workshop.id);
    _customWorkshops.insert(0, workshop);
    final preferences = await SharedPreferences.getInstance();
    final jsonList = _customWorkshops.map((w) => jsonEncode(w.toJson())).toList();
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
    final jsonList = _customWorkshops.map((w) => jsonEncode(w.toJson())).toList();
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

  List<Workshop> getFilteredWorkshops(Vehicle? activeVehicle) {
    // Unifica oficinas cadastradas personalizadas (no topo com destaque) e oficinas do OpenStreetMap
    final allList = <Workshop>[
      ..._customWorkshops,
      ..._workshops.where((osm) => !_customWorkshops.any((c) =>
          c.id == osm.id ||
          c.name.toLowerCase().trim() == osm.name.toLowerCase().trim())),
    ];

    return allList.where((w) {
      // Filtro de categoria
      if (_selectedCategory != null && w.categoryType != _selectedCategory) {
        return false;
      }

      // Filtro de busca textual (nome, serviços, marcas atendidas, especialidades, endereço)
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchesName = w.name.toLowerCase().contains(q);
        final matchesCategory = w.category.toLowerCase().contains(q);
        final matchesAddress = w.address.toLowerCase().contains(q);
        final matchesBrands =
            w.supportedBrands.any((b) => b.toLowerCase().contains(q));
        final matchesSpecialties =
            w.specialties.any((s) => s.toLowerCase().contains(q));
        final matchesServices =
            w.services.any((s) => s.name.toLowerCase().contains(q));

        if (!matchesName &&
            !matchesCategory &&
            !matchesAddress &&
            !matchesBrands &&
            !matchesSpecialties &&
            !matchesServices) {
          return false;
        }
      }

      // Filtro de compatibilidade alta
      if (_onlyCompatibleWithVehicle && activeVehicle != null) {
        final comp = w.calculateCompatibility(activeVehicle);
        if (comp.percentage < 90) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchGeneration++;
    _openStreetMapService.dispose();
    super.dispose();
  }
}
