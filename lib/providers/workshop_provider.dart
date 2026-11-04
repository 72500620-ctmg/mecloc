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
  static const _recentSearchesKey = 'recent_search_terms';

  final OpenStreetMapService _openStreetMapService;
  final LocationService _locationService;

  List<Workshop> _workshops = [];
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

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _favoriteIds = preferences.getStringList(_favoritesKey)?.toSet() ?? {};
    _recentSearches = preferences.getStringList(_recentSearchesKey) ?? [
      'Troca de óleo para Honda Civic',
      'Oficina especializada em Volkswagen',
      'Lava-jato com lavagem detalhada',
      'Mecânico especializado em câmbio automático',
      'Troca de pneus perto de mim',
    ];
    notifyListeners();

    // Se ainda não buscou, busca automaticamente perto do usuário para carregar o mapa
    if (!_hasSearched) {
      await searchWorkshops();
    }
  }

  Future<void> searchWorkshops({
    String city = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _hasSearched = true;
    _selectedWorkshop = null;
    notifyListeners();

    try {
      _searchCenter = city.trim().isEmpty
          ? await _locationService.getCurrentLocation()
          : await _openStreetMapService.geocodeCity(city);
      _workshops =
          await _openStreetMapService.searchNearbyWorkshops(_searchCenter!);
    } catch (error) {
      _workshops = [];
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
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
    if (!_favoriteIds.add(workshopId)) {
      _favoriteIds.remove(workshopId);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_favoritesKey, _favoriteIds.toList());
    notifyListeners();
  }

  List<Workshop> getFilteredWorkshops(Vehicle? activeVehicle) {
    return _workshops.where((w) {
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
    _openStreetMapService.dispose();
    super.dispose();
  }
}
