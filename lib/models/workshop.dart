import 'package:flutter/material.dart';

import 'automotive_service.dart';
import 'vehicle.dart';

enum WorkshopCategory {
  mechanic,
  carWash,
  autoCenter,
  tireShop,
  oilChange,
  detailing,
  bodyPaint,
  specialist,
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.percentage,
    required this.label,
    required this.reasons,
    required this.isHighMatch,
    required this.accentColor,
  });

  final int percentage;
  final String label;
  final List<String> reasons;
  final bool isHighMatch;
  final Color accentColor;
}

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
    this.category = 'Oficina Mecânica',
    this.categoryType = WorkshopCategory.mechanic,
    this.supportedBrands = const [],
    this.specialties = const [],
    this.services = const [],
    this.isOpenNow = false,
    this.openingHours = 'Horário não informado',
    this.isVerified = false,
    this.priceLevel = 'R\$ \$\$',
    this.distanceKm,
    this.imageUrl,
    this.reviews = const [],
    this.isCustomRegistered = false,
    this.whatsappPhone,
    this.description,
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
  final String category;
  final WorkshopCategory categoryType;
  final List<String> supportedBrands;
  final List<String> specialties;
  final List<AutomotiveService> services;
  final bool isOpenNow;
  final String openingHours;
  final bool isVerified;
  final String priceLevel;
  final double? distanceKm;
  final String? imageUrl;
  final List<WorkshopReview> reviews;
  final bool isCustomRegistered;
  final String? whatsappPhone;
  final String? description;

  IconData get iconData {
    switch (categoryType) {
      case WorkshopCategory.carWash:
        return Icons.local_car_wash_rounded;
      case WorkshopCategory.oilChange:
        return Icons.opacity_rounded;
      case WorkshopCategory.tireShop:
        return Icons.radio_button_checked_rounded;
      case WorkshopCategory.autoCenter:
        return Icons.garage_rounded;
      case WorkshopCategory.detailing:
        return Icons.auto_awesome_rounded;
      case WorkshopCategory.bodyPaint:
        return Icons.format_paint_rounded;
      case WorkshopCategory.specialist:
        return Icons.verified_user_rounded;
      case WorkshopCategory.mechanic:
        return Icons.build_rounded;
    }
  }

  Color get categoryColor {
    switch (categoryType) {
      case WorkshopCategory.carWash:
        return const Color(0xFF007AFF); // Azul piscina
      case WorkshopCategory.oilChange:
        return const Color(0xFFFF9500); // Laranja âmbar
      case WorkshopCategory.tireShop:
        return const Color(0xFF5856D6); // Roxo índigo
      case WorkshopCategory.autoCenter:
        return const Color(0xFF107C41); // Verde floresta
      case WorkshopCategory.detailing:
        return const Color(0xFFAF52DE); // Púrpura brilhante
      case WorkshopCategory.bodyPaint:
        return const Color(0xFFFF2D55); // Vermelho rubi
      case WorkshopCategory.specialist:
        return const Color(0xFF0288D1); // Azul cerúleo
      case WorkshopCategory.mechanic:
        return const Color(0xFF174D43); // Forest Deep
    }
  }

  String get googleMapsUrl {
    final query = (address.isNotEmpty && address != 'Endereço não informado')
        ? '$name, $address'
        : (latitude != null && longitude != null)
            ? '$latitude,$longitude'
            : name;
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
  }

  String? get googleMapsDirectionsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    }
    return null;
  }

  CompatibilityResult calculateCompatibility(Vehicle? vehicle) {
    if (vehicle == null) {
      return const CompatibilityResult(
        percentage: 95,
        label: 'Compatível com serviços gerais',
        reasons: [
          'Oficina qualificada para manutenções preventivas e periódicas'
        ],
        isHighMatch: false,
        accentColor: Color(0xFF174D43),
      );
    }

    final brandLower = vehicle.brand.toLowerCase().trim();
    final modelLower = vehicle.model.toLowerCase().trim();

    final matchesBrand = supportedBrands.any((b) {
      final bLower = b.toLowerCase();
      return bLower == 'todas as marcas' ||
          bLower.contains(brandLower) ||
          brandLower.contains(bLower) ||
          bLower.contains(modelLower);
    });

    final isBrandSpecialist = supportedBrands.any((b) =>
        b.toLowerCase().contains(brandLower) &&
        b.toLowerCase() != 'todas as marcas');

    final transmissionSpecialist =
        vehicle.transmission.toLowerCase().contains('auto') &&
            specialties.any((s) =>
                s.toLowerCase().contains('câmbio') ||
                s.toLowerCase().contains('transmissão'));

    final turboSpecialist = (vehicle.engine.toLowerCase().contains('tsi') ||
            vehicle.engine.toLowerCase().contains('turbo') ||
            vehicle.engine.toLowerCase().contains('thp')) &&
        specialties.any((s) =>
            s.toLowerCase().contains('turbo') ||
            s.toLowerCase().contains('injeção'));

    final reasons = <String>[];
    int score = 80;

    if (isBrandSpecialist) {
      score += 20;
      reasons.add('Especialista dedicado na marca ${vehicle.brand}');
    } else if (matchesBrand) {
      score += 10;
      reasons.add('Atende a montadora ${vehicle.brand}');
    }

    if (transmissionSpecialist) {
      score += 5;
      reasons.add('Equipe especializada em câmbio ${vehicle.transmission}');
    }

    if (turboSpecialist) {
      score += 5;
      reasons.add('Ferramentas de precisão para motorização ${vehicle.engine}');
    }

    if (reasons.isEmpty) {
      reasons
          .add('Atendimento e peças compatíveis com seu ${vehicle.shortName}');
    }

    final finalScore = score.clamp(70, 100);
    final isHigh = finalScore >= 95;

    return CompatibilityResult(
      percentage: finalScore,
      label: isHigh
          ? '100% Especialista no seu ${vehicle.shortName}'
          : '$finalScore% Compatível com seu ${vehicle.shortName}',
      reasons: reasons,
      isHighMatch: isHigh,
      accentColor: isHigh ? const Color(0xFF0F9D58) : const Color(0xFF174D43),
    );
  }

  Workshop copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    int? ratingCount,
    String? phone,
    String? openStreetMapUrl,
    String? category,
    WorkshopCategory? categoryType,
    List<String>? supportedBrands,
    List<String>? specialties,
    List<AutomotiveService>? services,
    bool? isOpenNow,
    String? openingHours,
    bool? isVerified,
    String? priceLevel,
    double? distanceKm,
    String? imageUrl,
    List<WorkshopReview>? reviews,
    bool? isCustomRegistered,
    String? whatsappPhone,
    String? description,
  }) {
    return Workshop(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      phone: phone ?? this.phone,
      openStreetMapUrl: openStreetMapUrl ?? this.openStreetMapUrl,
      category: category ?? this.category,
      categoryType: categoryType ?? this.categoryType,
      supportedBrands: supportedBrands ?? this.supportedBrands,
      specialties: specialties ?? this.specialties,
      services: services ?? this.services,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      openingHours: openingHours ?? this.openingHours,
      isVerified: isVerified ?? this.isVerified,
      priceLevel: priceLevel ?? this.priceLevel,
      distanceKm: distanceKm ?? this.distanceKm,
      imageUrl: imageUrl ?? this.imageUrl,
      reviews: reviews ?? this.reviews,
      isCustomRegistered: isCustomRegistered ?? this.isCustomRegistered,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'ratingCount': ratingCount,
        'phone': phone,
        'openStreetMapUrl': openStreetMapUrl,
        'category': category,
        'categoryType': categoryType.name,
        'supportedBrands': supportedBrands,
        'specialties': specialties,
        'isOpenNow': isOpenNow,
        'openingHours': openingHours,
        'isVerified': isVerified,
        'priceLevel': priceLevel,
        'distanceKm': distanceKm,
        'imageUrl': imageUrl,
        'isCustomRegistered': isCustomRegistered,
        'whatsappPhone': whatsappPhone,
        'description': description,
      };

  factory Workshop.fromJson(Map<String, dynamic> json) {
    WorkshopCategory catType;
    try {
      catType = WorkshopCategory.values.byName(json['categoryType'] as String? ?? 'mechanic');
    } catch (_) {
      catType = WorkshopCategory.mechanic;
    }

    return Workshop(
      id: json['id'] as String? ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Oficina',
      address: json['address'] as String? ?? 'Endereço não informado',
      latitude: _number(json['latitude']),
      longitude: _number(json['longitude']),
      rating: _number(json['rating']) ?? 5.0,
      ratingCount: json['ratingCount'] as int? ?? 1,
      phone: json['phone'] as String?,
      openStreetMapUrl: json['openStreetMapUrl'] as String?,
      category: json['category'] as String? ?? 'Oficina mecânica',
      categoryType: catType,
      supportedBrands: (json['supportedBrands'] as List<dynamic>?)?.cast<String>() ?? const ['Todas as marcas'],
      specialties: (json['specialties'] as List<dynamic>?)?.cast<String>() ?? const [],
      isOpenNow: json['isOpenNow'] as bool? ?? true,
      openingHours: json['openingHours'] as String? ?? 'Segunda a Sexta, 08:00 - 18:00',
      isVerified: json['isVerified'] as bool? ?? true,
      priceLevel: json['priceLevel'] as String? ?? 'R\$ \$\$',
      distanceKm: _number(json['distanceKm']),
      imageUrl: json['imageUrl'] as String?,
      isCustomRegistered: json['isCustomRegistered'] as bool? ?? true,
      whatsappPhone: json['whatsappPhone'] as String?,
      description: json['description'] as String?,
    );
  }

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

    final rawName = tags['name'] as String? ?? 'Oficina mecânica';
    final parsedCategory = _detectCategory(tags, rawName);

    return Workshop(
      id: 'osm:$type:$id',
      name: rawName,
      address: address.isEmpty ? 'Endereço não informado' : address,
      latitude: latitude,
      longitude: longitude,
      phone: tags['contact:phone'] as String? ?? tags['phone'] as String?,
      openStreetMapUrl:
          id == null ? null : 'https://www.openstreetmap.org/$type/$id',
      rating: _number(tags['rating']) ?? _number(tags['stars']),
      ratingCount: int.tryParse(tags['rating:count']?.toString() ?? ''),
      category: parsedCategory.$2,
      categoryType: parsedCategory.$1,
      openingHours: tags['opening_hours'] as String? ?? 'Horário não informado',
    );
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static (WorkshopCategory, String) _detectCategory(
      Map<String, dynamic> tags, String name) {
    if (tags['amenity'] == 'car_wash') {
      return (WorkshopCategory.carWash, 'Lava-jato');
    }
    if (tags['shop'] == 'tyres') return (WorkshopCategory.tireShop, 'Pneus');
    return (WorkshopCategory.mechanic, 'Oficina mecânica');
  }
}

class WorkshopReview {
  const WorkshopReview({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
    this.carModel,
  });

  final String authorName;
  final double rating;
  final String comment;
  final String date;
  final String? carModel;
}
