import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_area.dart';
import '../models/workshop.dart';
import '../models/workshop_search_result.dart';

class DiscoveryCache {
  DiscoveryCache({required this.now});
  final DateTime Function() now;
  static const storageKey = 'discovery_areas_v1';
  final _entries = <String, _Entry>{};
  // A cobertura de uma consulta e os locais já conhecidos são dados distintos.
  // Respostas parciais não demonstram que um local deixou de existir.
  final _places = <String, _KnownPlace>{};
  Future<void>? _restoring;
  Future<void> restore() => _restoring ??= _restore();
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      final areas = decoded is List
          ? decoded
          : (decoded as Map<String, dynamic>)['areas'] as List<dynamic>? ?? [];
      final places = decoded is Map<String, dynamic>
          ? decoded['places'] as List<dynamic>?
          : null;
      for (final item in areas.whereType<Map<String, dynamic>>()) {
        try {
          final area =
              SearchArea.fromJson(item['area'] as Map<String, dynamic>);
          final time = DateTime.parse(item['at'] as String);
          if (now().difference(time) > const Duration(days: 7)) continue;
          final result = WorkshopSearchResult(
              (item['items'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(Workshop.fromJson)
                  .where((w) => !w.isExcludedFromDiscovery),
              isComplete: item['complete'] == true,
              fetchedAt: time);
          _entries[area.key] = _Entry(area, result, time);
          // Migração do cache anterior, que guardava locais somente por área.
          if (places == null) {
            for (final w in result) {
              _remember(w, time);
            }
          }
        } catch (_) {/* Uma entrada inválida não descarta as demais. */}
      }
      for (final item in (places ?? []).whereType<Map<String, dynamic>>()) {
        try {
          _remember(Workshop.fromJson(item['workshop'] as Map<String, dynamic>),
              DateTime.parse(item['at'] as String));
        } catch (_) {/* Ignora somente o cadastro inválido. */}
      }
      _trim();
    } catch (_) {/* O cache em memória continua disponível. */}
  }

  WorkshopSearchResult? lookup(SearchArea area) {
    // Prefere cobertura completa ainda válida; uma parcial não a substitui.
    final candidates = _entries.values.toList().reversed.toList()
      ..sort((a, b) {
        final completeness =
            (b.result.isComplete ? 1 : 0) - (a.result.isComplete ? 1 : 0);
        return completeness != 0 ? completeness : b.at.compareTo(a.at);
      });
    for (final entry in candidates) {
      final ttl = entry.result.isComplete
          ? const Duration(hours: 6)
          : const Duration(minutes: 15);
      if (now().difference(entry.at) < ttl && entry.area.covers(area)) {
        return withKnown(
            WorkshopSearchResult(const [],
                isComplete: entry.result.isComplete,
                fromCache: true,
                fetchedAt: entry.at),
            area);
      }
    }
    return null;
  }

  WorkshopSearchResult? preview(SearchArea area) {
    final items = <String, Workshop>{};
    DateTime? newest;
    for (final place in _places.values) {
      if (!_retained(place) || !_inside(place.workshop, area)) continue;
      items[place.workshop.id] = place.workshop;
      if (newest == null || place.at.isAfter(newest)) newest = place.at;
    }
    if (items.isEmpty) return null;
    return WorkshopSearchResult(items.values,
        isComplete: false, isStale: true, fromCache: true, fetchedAt: newest);
  }

  Future<void> put(SearchArea area, WorkshopSearchResult result) async {
    final time = now();
    if (result.isComplete && !result.isStale) {
      final currentIds = result.map((w) => w.id).toSet();
      // Somente uma resposta completa pode substituir o conjunto de sua área.
      _places.removeWhere((id, place) =>
          _inside(place.workshop, area) && !currentIds.contains(id));
    }
    for (final workshop in result) {
      _remember(workshop, time);
    }
    _entries.remove(area.key);
    _entries[area.key] = _Entry(
        area,
        WorkshopSearchResult(result,
            isComplete: result.isComplete, fetchedAt: time),
        time);
    _trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          storageKey,
          jsonEncode({
            'version': 2,
            'areas': _entries.values
                .map((e) => {
                      'area': e.area.toJson(),
                      'at': e.at.toIso8601String(),
                      'complete': e.result.isComplete,
                      'items': e.result.map((w) => w.toJson()).toList(),
                    })
                .toList(),
            'places': _places.values
                .map((place) => {
                      'at': place.at.toIso8601String(),
                      'workshop': place.workshop.toJson(),
                    })
                .toList()
          }));
    } catch (_) {/* Falta de espaço não interrompe a busca. */}
  }

  void _trim() {
    while (_entries.length > 12 ||
        (_entries.length > 1 &&
            _entries.values.fold<int>(0, (sum, e) => sum + e.result.length) >
                1500)) {
      _entries.remove(_entries.keys.first);
    }
    _places.removeWhere((_, place) => !_retained(place));
    if (_places.length > 1500) {
      // Não perde dados das coberturas mantidas, inclusive uma resposta grande.
      final coveredIds = _entries.values
          .expand((entry) => entry.result)
          .map((w) => w.id)
          .toSet();
      final excess = _places.length -
          (coveredIds.length > 1500 ? coveredIds.length : 1500);
      final oldest = _places.values.toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      for (final place in oldest
          .where((place) => !coveredIds.contains(place.workshop.id))
          .take(excess)) {
        _places.remove(place.workshop.id);
      }
    }
  }

  void _remember(Workshop workshop, DateTime time) {
    if (workshop.isExcludedFromDiscovery ||
        workshop.latitude == null ||
        workshop.longitude == null ||
        now().difference(time) > const Duration(days: 7)) {
      return;
    }
    final previous = _places[workshop.id];
    if (previous == null || !time.isBefore(previous.at)) {
      _places[workshop.id] = _KnownPlace(workshop, time);
    }
  }

  bool _retained(_KnownPlace place) =>
      now().difference(place.at) <= const Duration(days: 7);
  bool _inside(Workshop workshop, SearchArea area) =>
      workshop.latitude != null &&
      workshop.longitude != null &&
      area.contains(workshop.latitude!, workshop.longitude!);

  WorkshopSearchResult withKnown(WorkshopSearchResult result, SearchArea area) {
    final items = <String, Workshop>{
      for (final place in _places.values)
        if (_retained(place) && _inside(place.workshop, area))
          place.workshop.id: place.workshop,
      for (final w in crop(result, area))
        if (!w.isExcludedFromDiscovery) w.id: w,
    };
    return WorkshopSearchResult(items.values,
        isComplete: result.isComplete,
        isStale: result.isStale,
        fromCache: result.fromCache,
        fetchedAt: result.fetchedAt);
  }

  static WorkshopSearchResult crop(WorkshopSearchResult result, SearchArea area,
          {bool? fromCache}) =>
      WorkshopSearchResult(
          result.where((w) =>
              w.latitude != null &&
              w.longitude != null &&
              area.contains(w.latitude!, w.longitude!)),
          isComplete: result.isComplete,
          isStale: result.isStale,
          fromCache: fromCache ?? result.fromCache,
          fetchedAt: result.fetchedAt);
}

class _KnownPlace {
  const _KnownPlace(this.workshop, this.at);
  final Workshop workshop;
  final DateTime at;
}

class _Entry {
  const _Entry(this.area, this.result, this.at);
  final SearchArea area;
  final WorkshopSearchResult result;
  final DateTime at;
}
