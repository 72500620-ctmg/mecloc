import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final OpenStreetMapService _openStreetMapService;
  final LocationService _locationService;
  List<Workshop> _workshops = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;
  LatLng? _searchCenter;

  List<Workshop> get workshops => List.unmodifiable(_workshops);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSearched => _hasSearched;
  LatLng? get searchCenter => _searchCenter;
  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _favoriteIds = preferences.getStringList(_favoritesKey)?.toSet() ?? {};
    notifyListeners();
  }

  Future<void> searchWorkshops({
    String city = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _hasSearched = true;
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

  Future<void> toggleFavorite(String workshopId) async {
    if (!_favoriteIds.add(workshopId)) {
      _favoriteIds.remove(workshopId);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_favoritesKey, _favoriteIds.toList());
    notifyListeners();
  }

  @override
  void dispose() {
    _openStreetMapService.dispose();
    super.dispose();
  }
}
