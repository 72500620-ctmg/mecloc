import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';

class VehicleProvider extends ChangeNotifier {
  static const _vehiclesKey = 'saved_vehicles_v2';
  static const _legacyKey = 'saved_vehicles';

  List<Vehicle> _vehicles = [];
  bool _isLoaded = false;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  bool get isLoaded => _isLoaded;

  Vehicle? get activeVehicle {
    if (_vehicles.isEmpty) return null;
    final found = _vehicles.where((v) => v.isSelected).toList();
    return found.isNotEmpty ? found.first : _vehicles.first;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_vehiclesKey);

    if (jsonList != null && jsonList.isNotEmpty) {
      _vehicles = jsonList
          .map((item) => Vehicle.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } else {
      // Tenta migrar do formato legado
      final legacy = prefs.getStringList(_legacyKey);
      if (legacy != null && legacy.isNotEmpty) {
        _vehicles = legacy
            .asMap()
            .entries
            .map((e) => Vehicle.fromLegacyString(e.value, isSelected: e.key == 0))
            .toList();
      } else {
        // Inicializa com um veículo demonstrativo de exemplo para já demonstrar a compatibilidade
        _vehicles = [
          const Vehicle(
            id: 'demo_1',
            brand: 'Volkswagen',
            model: 'Golf',
            year: 2021,
            engine: '1.4 TSI Turbo 150cv',
            fuel: 'Flex',
            transmission: 'Automático Tiptronic',
            version: 'Highline',
            plate: 'BRA2E19',
            isSelected: true,
          ),
          const Vehicle(
            id: 'demo_2',
            brand: 'Honda',
            model: 'Civic',
            year: 2022,
            engine: '2.0 i-VTEC 155cv',
            fuel: 'Flex',
            transmission: 'Automático CVT',
            version: 'Touring',
            plate: 'MEC2026',
            isSelected: false,
          ),
        ];
        await _save();
      }
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    final wasEmpty = _vehicles.isEmpty;
    final toAdd = vehicle.copyWith(
      isSelected: wasEmpty || vehicle.isSelected,
    );

    if (toAdd.isSelected) {
      _vehicles = _vehicles.map((v) => v.copyWith(isSelected: false)).toList();
    }

    _vehicles = [..._vehicles, toAdd];
    await _save();
    notifyListeners();
  }

  Future<void> removeVehicle(String id) async {
    final vehicleToRemove = _vehicles.firstWhere((v) => v.id == id, orElse: () => _vehicles.first);
    final wasSelected = vehicleToRemove.isSelected;

    _vehicles = _vehicles.where((v) => v.id != id).toList();

    if (wasSelected && _vehicles.isNotEmpty) {
      _vehicles[0] = _vehicles[0].copyWith(isSelected: true);
    }

    await _save();
    notifyListeners();
  }

  Future<void> selectVehicle(String id) async {
    _vehicles = _vehicles.map((v) {
      return v.copyWith(isSelected: v.id == id);
    }).toList();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _vehicles.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_vehiclesKey, jsonList);
  }
}

