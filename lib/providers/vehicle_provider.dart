import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';

class VehicleProvider extends ChangeNotifier {
  VehicleProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _customAuth = auth,
        _customFirestore = firestore;

  static const _legacyV2Key = 'saved_vehicles_v2';
  static const _legacyKey = 'saved_vehicles';

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;
  List<Vehicle> _vehicles = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  Vehicle? get activeVehicle {
    if (_vehicles.isEmpty) return null;
    final found = _vehicles.where((v) => v.isSelected).toList();
    return found.isNotEmpty ? found.first : _vehicles.first;
  }

  String _vehiclesKeyForUser(String userId) => 'saved_vehicles_$userId';

  void initialize() {
    try {
      _authSubscription = _auth.authStateChanges().listen((User? user) async {
        await syncUser(user?.uid);
      });
      // Verifica se o usuário já está logado na inicialização
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        syncUser(currentUser.uid);
      } else {
        _vehicles = [];
        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('VehicleProvider init fallback: $e');
      _vehicles = [];
      _isLoaded = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> syncUser(String? userId) async {
    if (userId == null) {
      clearSession();
      return;
    }

    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    // 1. Carrega do cache local primeiro para resposta instantânea
    final prefs = await SharedPreferences.getInstance();
    final localKey = _vehiclesKeyForUser(userId);
    final cachedList = prefs.getStringList(localKey);

    if (cachedList != null && cachedList.isNotEmpty) {
      try {
        _vehicles = cachedList
            .map((item) => Vehicle.fromJson(jsonDecode(item) as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Erro ao decodificar cache local de veículos: $e');
      }
    }

    _isLoaded = true;
    _isLoading = false;
    notifyListeners();

    // 2. Sincroniza com Cloud Firestore
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .get();

      if (snapshot.docs.isNotEmpty) {
        _vehicles = snapshot.docs
            .map((doc) => Vehicle.fromJson(doc.data()))
            .toList();
        await _saveToLocal(userId);
      } else if (_vehicles.isEmpty) {
        // Se a coleção na nuvem e o cache do usuário estão vazios,
        // migra dados que existiam na chave legada não-autenticada
        final legacyJson = prefs.getStringList(_legacyV2Key);
        if (legacyJson != null && legacyJson.isNotEmpty) {
          final migrated = legacyJson
              .map((item) => Vehicle.fromJson(jsonDecode(item) as Map<String, dynamic>))
              .toList();
          _vehicles = migrated;

          for (final v in _vehicles) {
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('vehicles')
                .doc(v.id)
                .set(v.toJson());
          }
          await _saveToLocal(userId);
          // Limpa chave legada após migração
          await prefs.remove(_legacyV2Key);
        } else {
          final legacyOld = prefs.getStringList(_legacyKey);
          if (legacyOld != null && legacyOld.isNotEmpty) {
            final migrated = legacyOld
                .asMap()
                .entries
                .map((e) => Vehicle.fromLegacyString(e.value, isSelected: e.key == 0))
                .toList();
            _vehicles = migrated;

            for (final v in _vehicles) {
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('vehicles')
                  .doc(v.id)
                  .set(v.toJson());
            }
            await _saveToLocal(userId);
            await prefs.remove(_legacyKey);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Aviso ao sincronizar veículos do Firestore: $e');
    }
  }

  void clearSession() {
    _currentUserId = null;
    _vehicles = [];
    _isLoaded = true;
    _isLoading = false;
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

    if (_currentUserId != null) {
      try {
        final batch = _firestore.batch();
        final userVehiclesCol = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('vehicles');

        if (toAdd.isSelected) {
          for (final v in _vehicles) {
            if (v.id != toAdd.id) {
              batch.update(userVehiclesCol.doc(v.id), {'isSelected': false});
            }
          }
        }
        batch.set(userVehiclesCol.doc(toAdd.id), toAdd.toJson());
        await batch.commit();
      } catch (e) {
        debugPrint('Erro ao salvar veículo no Firestore: $e');
      }
    }
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

    if (_currentUserId != null) {
      try {
        final userVehiclesCol = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('vehicles');
        await userVehiclesCol.doc(id).delete();
        if (wasSelected && _vehicles.isNotEmpty) {
          await userVehiclesCol.doc(_vehicles[0].id).update({'isSelected': true});
        }
      } catch (e) {
        debugPrint('Erro ao remover veículo do Firestore: $e');
      }
    }
  }

  Future<void> selectVehicle(String id) async {
    _vehicles = _vehicles.map((v) {
      return v.copyWith(isSelected: v.id == id);
    }).toList();
    await _save();
    notifyListeners();

    if (_currentUserId != null) {
      try {
        final batch = _firestore.batch();
        final userVehiclesCol = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('vehicles');
        for (final v in _vehicles) {
          batch.update(userVehiclesCol.doc(v.id), {'isSelected': v.id == id});
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Erro ao atualizar veículo ativo no Firestore: $e');
      }
    }
  }

  Future<void> updateMileage(String id, int newMileageKm) async {
    _vehicles = _vehicles.map((v) {
      if (v.id == id) {
        return v.copyWith(mileageKm: newMileageKm);
      }
      return v;
    }).toList();
    await _save();
    notifyListeners();

    if (_currentUserId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('vehicles')
            .doc(id)
            .update({'mileageKm': newMileageKm});
      } catch (e) {
        debugPrint('Erro ao atualizar quilometragem no Firestore: $e');
      }
    }
  }

  Future<void> recordMaintenanceDone(String vehicleId, String maintenanceId, int doneAtKm) async {
    Vehicle? updatedVehicle;
    _vehicles = _vehicles.map((v) {
      if (v.id == vehicleId) {
        final currentKm = doneAtKm > v.mileageKm ? doneAtKm : v.mileageKm;
        switch (maintenanceId) {
          case 'oil_filter':
            updatedVehicle = v.copyWith(lastOilChangeKm: doneAtKm, mileageKm: currentKm);
            return updatedVehicle!;
          case 'brakes':
            updatedVehicle = v.copyWith(lastBrakesKm: doneAtKm, mileageKm: currentKm);
            return updatedVehicle!;
          case 'filters_air':
            updatedVehicle = v.copyWith(lastFiltersKm: doneAtKm, mileageKm: currentKm);
            return updatedVehicle!;
          case 'timing_belt':
            updatedVehicle = v.copyWith(lastTimingBeltKm: doneAtKm, mileageKm: currentKm);
            return updatedVehicle!;
        }
      }
      return v;
    }).toList();
    await _save();
    notifyListeners();

    if (_currentUserId != null && updatedVehicle != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('vehicles')
            .doc(vehicleId)
            .set(updatedVehicle!.toJson());
      } catch (e) {
        debugPrint('Erro ao atualizar revisão no Firestore: $e');
      }
    }
  }

  Future<void> _save() async {
    if (_currentUserId != null) {
      await _saveToLocal(_currentUserId!);
    }
  }

  Future<void> _saveToLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _vehicles.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_vehiclesKeyForUser(userId), jsonList);
  }
}
