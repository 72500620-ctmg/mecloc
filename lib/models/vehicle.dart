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

  String get displayName => '$brand $model $version ($year)';
  String get shortName => '$brand $model';
  String get specsSummary => '$engine • $fuel • $transmission';

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
    );
  }
}

class UniqueKey {
  @override
  String toString() => DateTime.now().microsecondsSinceEpoch.toString();
}

