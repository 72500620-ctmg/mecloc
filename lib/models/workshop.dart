import 'package:flutter/material.dart';

import 'automotive_service.dart';
import 'vehicle.dart';
import '../utils/search_text.dart';

enum WorkshopCategory {
  mechanic,
  carWash,
  autoCenter,
  tireShop,
  oilChange,
  detailing,
  bodyPaint,
  specialist;

  String get label {
    switch (this) {
      case WorkshopCategory.mechanic:
        return 'Mecânica';
      case WorkshopCategory.carWash:
        return 'Lava-Jato';
      case WorkshopCategory.autoCenter:
        return 'Auto Center';
      case WorkshopCategory.tireShop:
        return 'Pneus';
      case WorkshopCategory.oilChange:
        return 'Troca de Óleo';
      case WorkshopCategory.detailing:
        return 'Estética';
      case WorkshopCategory.bodyPaint:
        return 'Funilaria';
      case WorkshopCategory.specialist:
        return 'Especializada';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkshopCategory.mechanic:
        return Icons.build_rounded;
      case WorkshopCategory.carWash:
        return Icons.local_car_wash_rounded;
      case WorkshopCategory.autoCenter:
        return Icons.garage_rounded;
      case WorkshopCategory.tireShop:
        return Icons.tire_repair_rounded;
      case WorkshopCategory.oilChange:
        return Icons.opacity_rounded;
      case WorkshopCategory.detailing:
        return Icons.auto_awesome_rounded;
      case WorkshopCategory.bodyPaint:
        return Icons.format_paint_rounded;
      case WorkshopCategory.specialist:
        return Icons.verified_rounded;
    }
  }
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
    this.additionalCategories = const [],
    this.supportedBrands = const [],
    this.specialties = const [],
    this.services = const [],
    this.isOpenNow = false,
    this.openingHours = 'Horário não informado',
    this.isVerified = false,
    this.priceLevel = 'R\$ \$\$',
    this.distanceKm,
    this.imageUrl,
    this.imageUrls = const [],
    this.reviews = const [],
    this.isCustomRegistered = false,
    this.whatsappPhone,
    this.description,
    this.ownerId,
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
  final List<WorkshopCategory> additionalCategories;
  final List<String> supportedBrands;
  final List<String> specialties;
  final List<AutomotiveService> services;
  final bool isOpenNow;
  final String openingHours;
  final bool isVerified;
  final String priceLevel;
  final double? distanceKm;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<WorkshopReview> reviews;
  final bool isCustomRegistered;
  final String? whatsappPhone;
  final String? description;
  final String? ownerId;

  List<String> get allImageUrls {
    final list = <String>[];
    for (final u in imageUrls) {
      if (u.trim().isNotEmpty && !list.contains(u.trim())) {
        list.add(u.trim());
      }
    }
    if (imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        !list.contains(imageUrl!.trim())) {
      list.insert(0, imageUrl!.trim());
    }
    return list;
  }

  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1.0) {
      final meters = (distanceKm! * 1000).round();
      return '$meters m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  bool matchesCategory(WorkshopCategory value) =>
      categoryType == value || additionalCategories.contains(value);

  bool get isExcludedFromDiscovery => isExcludedBusiness('$name $category');

  static bool isExcludedBusiness(String text) => RegExp(
        r'\b(concessionaria[s]?|concessionario[s]?|revenda de (carros|veiculos)|venda de (carros|veiculos)|seminovos)\b',
      ).hasMatch(normalizeSearchText(text));

  /// Apenas atividades automotivas confirmadas pelas tags entram na descoberta.
  static bool acceptsOsmTags(Map<String, dynamic> tags) {
    final shop = tags['shop'];
    if (const [
          'car',
          'motorcycle',
          'motorcycle_repair',
          'truck',
          'truck_repair'
        ].contains(shop) ||
        isExcludedBusiness(tags['name']?.toString() ?? '')) {
      return false;
    }
    if (tags['disused'] == 'yes' ||
        tags['abandoned'] == 'yes' ||
        tags['access'] == 'private') {
      return false;
    }
    return const ['car_repair', 'tyres', 'car_parts', 'car_accessories']
            .contains(shop) ||
        tags['craft'] == 'car_repair' ||
        tags['amenity'] == 'car_wash' ||
        vehicleServices.keys
            .any((key) => _positive(tags['service:vehicle:$key']));
  }

  static bool _positive(Object? value) => const ['yes', 'only'].contains(value);

  static const vehicleServices = <String, (WorkshopCategory, String)>{
    'car_repair': (WorkshopCategory.mechanic, 'Mecânica geral'),
    'oil_change': (WorkshopCategory.oilChange, 'Troca de óleo'),
    'body_repair': (WorkshopCategory.bodyPaint, 'Funilaria'),
    'painting': (WorkshopCategory.bodyPaint, 'Pintura automotiva'),
    'tyres': (WorkshopCategory.tireShop, 'Pneus e borracharia'),
    'car_wash': (WorkshopCategory.carWash, 'Lava-jato'),
    'cleaning': (WorkshopCategory.detailing, 'Estética automotiva'),
    'electrical': (WorkshopCategory.specialist, 'Auto elétrica'),
    'glass': (WorkshopCategory.specialist, 'Vidros automotivos'),
    'air_conditioning': (WorkshopCategory.specialist, 'Ar condicionado'),
    'brakes': (WorkshopCategory.specialist, 'Freios'),
    'transmission': (WorkshopCategory.specialist, 'Câmbio'),
    'diagnostics': (WorkshopCategory.specialist, 'Diagnóstico eletrônico'),
    'alignment': (WorkshopCategory.tireShop, 'Alinhamento e balanceamento'),
    'batteries': (WorkshopCategory.specialist, 'Baterias'),
  };

  static WorkshopCategory? categoryForSearch(String query) =>
      switch (normalizeSearchText(query)) {
        'oficina' ||
        'oficinas' ||
        'mecanica' ||
        'mecanico' ||
        'oficina mecanica' ||
        'oficinas mecanicas' =>
          WorkshopCategory.mechanic,
        'pneu' ||
        'pneus' ||
        'borracharia' ||
        'borracharias' ||
        'alinhamento' ||
        'balanceamento' =>
          WorkshopCategory.tireShop,
        'lava jato' ||
        'lavajato' ||
        'lava jatos' ||
        'lavagem' ||
        'lavagem automotiva' =>
          WorkshopCategory.carWash,
        'oleo' ||
        'troca de oleo' ||
        'troca oleo' ||
        'lubrificacao' =>
          WorkshopCategory.oilChange,
        'funilaria' ||
        'pintura' ||
        'funilaria e pintura' ||
        'martelinho de ouro' =>
          WorkshopCategory.bodyPaint,
        'estetica' ||
        'estetica automotiva' ||
        'detalhamento' ||
        'polimento' ||
        'higienizacao' =>
          WorkshopCategory.detailing,
        'auto center' ||
        'centro automotivo' ||
        'autopecas' ||
        'auto pecas' =>
          WorkshopCategory.autoCenter,
        _ => null,
      };

  IconData get iconData {
    switch (categoryType) {
      case WorkshopCategory.carWash:
        return Icons.local_car_wash_rounded;
      case WorkshopCategory.oilChange:
        return Icons.opacity_rounded;
      case WorkshopCategory.tireShop:
        return Icons.tire_repair_rounded;
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
    List<WorkshopCategory>? additionalCategories,
    List<String>? supportedBrands,
    List<String>? specialties,
    List<AutomotiveService>? services,
    bool? isOpenNow,
    String? openingHours,
    bool? isVerified,
    String? priceLevel,
    double? distanceKm,
    String? imageUrl,
    List<String>? imageUrls,
    List<WorkshopReview>? reviews,
    bool? isCustomRegistered,
    String? whatsappPhone,
    String? description,
    String? ownerId,
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
      additionalCategories: additionalCategories ?? this.additionalCategories,
      supportedBrands: supportedBrands ?? this.supportedBrands,
      specialties: specialties ?? this.specialties,
      services: services ?? this.services,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      openingHours: openingHours ?? this.openingHours,
      isVerified: isVerified ?? this.isVerified,
      priceLevel: priceLevel ?? this.priceLevel,
      distanceKm: distanceKm ?? this.distanceKm,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      reviews: reviews ?? this.reviews,
      isCustomRegistered: isCustomRegistered ?? this.isCustomRegistered,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
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
        'additionalCategories':
            additionalCategories.map((c) => c.name).toList(),
        'supportedBrands': supportedBrands,
        'specialties': specialties,
        'isOpenNow': isOpenNow,
        'openingHours': openingHours,
        'isVerified': isVerified,
        'priceLevel': priceLevel,
        'distanceKm': distanceKm,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'isCustomRegistered': isCustomRegistered,
        'whatsappPhone': whatsappPhone,
        'description': description,
        'ownerId': ownerId,
      };

  factory Workshop.fromJson(Map<String, dynamic> json) {
    WorkshopCategory catType;
    try {
      catType = WorkshopCategory.values
          .byName(json['categoryType'] as String? ?? 'mechanic');
    } catch (_) {
      catType = WorkshopCategory.mechanic;
    }

    return Workshop(
      id: json['id'] as String? ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Oficina',
      address: json['address'] as String? ?? 'Endereço não informado',
      latitude: _number(json['latitude']),
      longitude: _number(json['longitude']),
      rating: _number(json['rating']) ??
          (json['isCustomRegistered'] == false ? null : 5.0),
      ratingCount: json['ratingCount'] as int? ??
          (json['isCustomRegistered'] == false ? null : 1),
      phone: json['phone'] as String?,
      openStreetMapUrl: json['openStreetMapUrl'] as String?,
      category: json['category'] as String? ?? 'Oficina mecânica',
      categoryType: catType,
      additionalCategories: (json['additionalCategories'] as List<dynamic>? ??
              [])
          .whereType<String>()
          .map((name) =>
              WorkshopCategory.values.where((c) => c.name == name).firstOrNull)
          .whereType<WorkshopCategory>()
          .toList(),
      supportedBrands:
          (json['supportedBrands'] as List<dynamic>?)?.cast<String>() ??
              const ['Todas as marcas'],
      specialties:
          (json['specialties'] as List<dynamic>?)?.cast<String>() ?? const [],
      isOpenNow: json['isOpenNow'] as bool? ?? true,
      openingHours:
          json['openingHours'] as String? ?? 'Segunda a Sexta, 08:00 - 18:00',
      isVerified: json['isVerified'] as bool? ?? true,
      priceLevel: json['priceLevel'] as String? ?? 'R\$ \$\$',
      distanceKm: _number(json['distanceKm']),
      imageUrl: json['imageUrl'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => WorkshopReview.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
      isCustomRegistered: json['isCustomRegistered'] as bool? ?? true,
      whatsappPhone: json['whatsappPhone'] as String?,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String?,
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

    final rawName = (tags['name'] as String?)?.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : _deriveDefaultName(tags);
    final parsedCategory = _detectCategory(tags, name);
    final activities = _activities(tags, name);

    return Workshop(
      id: 'osm:$type:$id',
      name: name,
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
      additionalCategories:
          activities.where((c) => c != parsedCategory.$1).toList(),
      specialties: vehicleServices.entries
          .where((e) => _positive(tags['service:vehicle:${e.key}']))
          .map((e) => e.value.$2)
          .toList(),
      openingHours: tags['opening_hours'] as String? ?? 'Horário não informado',
    );
  }

  static String _deriveDefaultName(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'car_wash') return 'Lava-Jato';
    if (tags['shop'] == 'tyres') return 'Borracharia / Pneus';
    if (tags['shop'] == 'car_parts') return 'Auto Peças & Acessórios';
    if (tags['shop'] == 'car') return 'Centro Automotivo / Concessionária';
    if (tags['shop'] == 'motorcycle_repair') return 'Mecânica de Motos';
    return 'Oficina mecânica';
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
    if (tags['shop'] == 'car_parts') {
      return (WorkshopCategory.autoCenter, 'Auto Peças & Serviços');
    }
    if (tags['shop'] == 'car') {
      return (
        WorkshopCategory.autoCenter,
        'Centro Automotivo / Concessionária'
      );
    }
    if (tags['shop'] == 'motorcycle_repair') {
      return (WorkshopCategory.mechanic, 'Mecânica de Motos');
    }
    final activities = _activities(tags, name);
    for (final category in [
      WorkshopCategory.bodyPaint,
      WorkshopCategory.oilChange,
      WorkshopCategory.detailing,
      WorkshopCategory.specialist,
      WorkshopCategory.autoCenter
    ]) {
      if (activities.contains(category)) return (category, category.label);
    }
    return (WorkshopCategory.mechanic, 'Oficina mecânica');
  }

  static Set<WorkshopCategory> _activities(
      Map<String, dynamic> tags, String name) {
    final categories = <WorkshopCategory>{};
    if (tags['shop'] == 'car_repair' || tags['craft'] == 'car_repair') {
      categories.add(WorkshopCategory.mechanic);
    }
    if (tags['shop'] == 'tyres') categories.add(WorkshopCategory.tireShop);
    if (tags['amenity'] == 'car_wash') categories.add(WorkshopCategory.carWash);
    if (const ['car_parts', 'car_accessories'].contains(tags['shop'])) {
      categories.add(WorkshopCategory.autoCenter);
    }
    for (final entry in vehicleServices.entries) {
      if (_positive(tags['service:vehicle:${entry.key}'])) {
        categories.add(entry.value.$1);
      }
    }
    final repairTypes = (tags['car_repair']?.toString() ?? '').split(';');
    for (final type in repairTypes) {
      final activity = vehicleServices[type.trim()];
      if (activity != null) categories.add(activity.$1);
      if (const ['bodywork', 'paint', 'body_repair'].contains(type.trim())) {
        categories.add(WorkshopCategory.bodyPaint);
      }
    }
    // Nomes refinam somente estabelecimentos previamente validados por atividade.
    if (acceptsOsmTags(tags)) {
      final text = normalizeSearchText(name);
      final hints = <String, (WorkshopCategory, String?)>{
        r'\b(troca de oleo|lubrificacao)\b': (
          WorkshopCategory.oilChange,
          'oil_change'
        ),
        r'\b(funilaria|pintura|martelinho)\b': (
          WorkshopCategory.bodyPaint,
          'body_repair'
        ),
        r'\b(estetica|polimento|detalhamento|higienizacao)\b': (
          WorkshopCategory.detailing,
          'cleaning'
        ),
        r'\b(pneus?|borracharia|alinhamento)\b': (
          WorkshopCategory.tireShop,
          'tyres'
        ),
        r'\b(lava jato|lavajato|lavagem)\b': (
          WorkshopCategory.carWash,
          'car_wash'
        ),
        r'\b(auto eletrica|vidros|ar condicionado|baterias)\b': (
          WorkshopCategory.specialist,
          null
        ),
        r'\b(auto center|centro automotivo)\b': (
          WorkshopCategory.autoCenter,
          null
        ),
      };
      for (final hint in hints.entries) {
        final key = hint.value.$2;
        if ((key == null || tags['service:vehicle:$key'] != 'no') &&
            RegExp(hint.key).hasMatch(text)) {
          categories.add(hint.value.$1);
        }
      }
    }
    return categories;
  }
}

class WorkshopReview {
  const WorkshopReview({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
    this.carModel,
    this.authorId,
  });

  final String authorName;
  final double rating;
  final String comment;
  final String date;
  final String? carModel;
  final String? authorId;

  Map<String, dynamic> toJson() => {
        'authorName': authorName,
        'rating': rating,
        'comment': comment,
        'date': date,
        'carModel': carModel,
        'authorId': authorId,
      };

  factory WorkshopReview.fromJson(Map<String, dynamic> json) => WorkshopReview(
        authorName: json['authorName'] as String? ?? 'Motorista',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        comment: json['comment'] as String? ?? '',
        date: json['date'] as String? ?? '',
        carModel: json['carModel'] as String?,
        authorId: json['authorId'] as String?,
      );
}
