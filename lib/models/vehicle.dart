import 'package:flutter/material.dart';
import 'maintenance_item.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.engine,
    required this.fuel,
    required this.transmission,
    required this.version,
    this.plate = '',
    this.isSelected = false,
    this.mileageKm = 48500,
    this.lastOilChangeKm = 40000,
    this.lastBrakesKm = 30000,
    this.lastTimingBeltKm = 0,
    this.lastFiltersKm = 40000,
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final String engine;
  final String fuel;
  final String transmission;
  final String version;
  final String plate;
  final bool isSelected;
  final int mileageKm;
  final int lastOilChangeKm;
  final int lastBrakesKm;
  final int lastTimingBeltKm;
  final int lastFiltersKm;

  String get displayName => '$brand $model $version ($year)';
  String get shortName => '$brand $model';
  String get specsSummary => '$engine • $fuel • $transmission';

  List<MaintenanceItem> getMaintenanceList() {
    return [
      MaintenanceItem(
        id: 'oil_filter',
        title: 'Troca de Óleo e Filtros',
        description: 'Lubrificante do motor, filtro de óleo e anel do bujão',
        intervalKm: 10000,
        lastDoneKm: lastOilChangeKm,
        recommendedService: 'Troca de Óleo e Filtros',
        icon: Icons.opacity_rounded,
      ),
      MaintenanceItem(
        id: 'brakes',
        title: 'Pastilhas e Discos de Freio',
        description: 'Verificação da espessura das pastilhas e fluido de freio',
        intervalKm: 20000,
        lastDoneKm: lastBrakesKm,
        recommendedService: 'Pastilhas e Discos de Freio',
        icon: Icons.disc_full_rounded,
      ),
      MaintenanceItem(
        id: 'filters_air',
        title: 'Filtro de Ar e Cabine',
        description: 'Filtro de ar do motor e higienização do ar-condicionado',
        intervalKm: 10000,
        lastDoneKm: lastFiltersKm,
        recommendedService: 'Ar Condicionado / Higienização',
        icon: Icons.air_rounded,
      ),
      MaintenanceItem(
        id: 'timing_belt',
        title: 'Correia Dentada e Tensor',
        description: 'Correia de sincronismo do motor e rolamentos tensores',
        intervalKm: 50000,
        lastDoneKm: lastTimingBeltKm,
        recommendedService: 'Troca de Correia Dentada',
        icon: Icons.settings_rounded,
      ),
    ];
  }

  Vehicle copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    String? engine,
    String? fuel,
    String? transmission,
    String? version,
    String? plate,
    bool? isSelected,
    int? mileageKm,
    int? lastOilChangeKm,
    int? lastBrakesKm,
    int? lastTimingBeltKm,
    int? lastFiltersKm,
  }) {
    return Vehicle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      engine: engine ?? this.engine,
      fuel: fuel ?? this.fuel,
      transmission: transmission ?? this.transmission,
      version: version ?? this.version,
      plate: plate ?? this.plate,
      isSelected: isSelected ?? this.isSelected,
      mileageKm: mileageKm ?? this.mileageKm,
      lastOilChangeKm: lastOilChangeKm ?? this.lastOilChangeKm,
      lastBrakesKm: lastBrakesKm ?? this.lastBrakesKm,
      lastTimingBeltKm: lastTimingBeltKm ?? this.lastTimingBeltKm,
      lastFiltersKm: lastFiltersKm ?? this.lastFiltersKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'engine': engine,
        'fuel': fuel,
        'transmission': transmission,
        'version': version,
        'plate': plate,
        'isSelected': isSelected,
        'mileageKm': mileageKm,
        'lastOilChangeKm': lastOilChangeKm,
        'lastBrakesKm': lastBrakesKm,
        'lastTimingBeltKm': lastTimingBeltKm,
        'lastFiltersKm': lastFiltersKm,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String? ?? UniqueKey().toString(),
      brand: json['brand'] as String? ?? 'Desconhecida',
      model: json['model'] as String? ?? 'Veículo',
      year: json['year'] as int? ?? DateTime.now().year,
      engine: json['engine'] as String? ?? '1.0 Flex',
      fuel: json['fuel'] as String? ?? 'Flex',
      transmission: json['transmission'] as String? ?? 'Manual',
      version: json['version'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      isSelected: json['isSelected'] as bool? ?? false,
      mileageKm: json['mileageKm'] as int? ?? 48500,
      lastOilChangeKm: json['lastOilChangeKm'] as int? ?? 40000,
      lastBrakesKm: json['lastBrakesKm'] as int? ?? 30000,
      lastTimingBeltKm: json['lastTimingBeltKm'] as int? ?? 0,
      lastFiltersKm: json['lastFiltersKm'] as int? ?? 40000,
    );
  }

  /// Converte formato legado "Modelo e ano|Placa" caso exista no SharedPreferences
  factory Vehicle.fromLegacyString(String raw, {bool isSelected = false}) {
    final parts = raw.split('|');
    final nameAndYear = parts.first.trim();
    final plate = parts.length > 1 ? parts[1].trim() : '';

    // Tenta extrair ano se houver 4 dígitos no final
    final yearMatch = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(nameAndYear);
    final year = yearMatch != null ? int.tryParse(yearMatch.group(0)!) ?? 2021 : 2021;
    final cleanName = nameAndYear.replaceAll(RegExp(r'\b(19\d\d|20\d\d)\b'), '').trim();

    final words = cleanName.split(' ');
    final brand = words.isNotEmpty ? words.first : 'Geral';
    final model = words.length > 1 ? words.sublist(1).join(' ') : 'Carro';

    return Vehicle(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      brand: brand,
      model: model,
      year: year,
      engine: '1.6 16V',
      fuel: 'Flex',
      transmission: 'Automático',
      version: 'Comfortline',
      plate: plate,
      isSelected: isSelected,
      mileageKm: 48500,
      lastOilChangeKm: 40000,
      lastBrakesKm: 30000,
      lastTimingBeltKm: 0,
      lastFiltersKm: 40000,
    );
  }
}

class UniqueKey {
  @override
  String toString() => DateTime.now().microsecondsSinceEpoch.toString();
}
