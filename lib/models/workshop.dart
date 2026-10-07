class Workshop {
  const Workshop({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
    this.phone,
    this.openStreetMapUrl,
  });

  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? ratingCount;
  final String? phone;
  final String? openStreetMapUrl;

  factory Workshop.fromOverpassJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? const {};
    final center = json['center'] as Map<String, dynamic>? ?? const {};
    final latitude = _number(json['lat']) ?? _number(center['lat']);
    final longitude = _number(json['lon']) ?? _number(center['lon']);
    final address = [
      [
        tags['addr:street'],
        tags['addr:housenumber'],
      ].whereType<String>().where((part) => part.isNotEmpty).join(', '),
      tags['addr:suburb'],
      tags['addr:city'],
    ].whereType<String>().where((part) => part.isNotEmpty).join(' - ');
    final type = json['type'] as String? ?? 'node';
    final id = json['id'];

    return Workshop(
      id: 'osm:$type:$id',
      name: tags['name'] as String? ?? 'Oficina mecânica',
      address: address.isEmpty ? 'Endereço não informado' : address,
      latitude: latitude,
      longitude: longitude,
      phone: tags['contact:phone'] as String? ?? tags['phone'] as String?,
      openStreetMapUrl:
          id == null ? null : 'https://www.openstreetmap.org/$type/$id',
    );
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
