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
    this.supportedBrands = const ['Todas as marcas'],
    this.specialties = const ['Mecânica Geral', 'Injeção Eletrônica', 'Freios'],
    this.services = const [],
    this.isOpenNow = true,
    this.openingHours = 'Seg - Sex: 08:00 - 18:00 | Sáb: 08:00 - 12:00',
    this.isVerified = true,
    this.priceLevel = 'R\$ \$\$',
    this.distanceKm,
    this.imageUrl,
    this.reviews = const [],
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

  CompatibilityResult calculateCompatibility(Vehicle? vehicle) {
    if (vehicle == null) {
      return const CompatibilityResult(
        percentage: 95,
        label: 'Compatível com serviços gerais',
        reasons: ['Oficina qualificada para manutenções preventivas e periódicas'],
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
        b.toLowerCase().contains(brandLower) && b.toLowerCase() != 'todas as marcas');

    final transmissionSpecialist = vehicle.transmission.toLowerCase().contains('auto') &&
        specialties.any((s) => s.toLowerCase().contains('câmbio') || s.toLowerCase().contains('transmissão'));

    final turboSpecialist = (vehicle.engine.toLowerCase().contains('tsi') ||
            vehicle.engine.toLowerCase().contains('turbo') ||
            vehicle.engine.toLowerCase().contains('thp')) &&
        specialties.any((s) => s.toLowerCase().contains('turbo') || s.toLowerCase().contains('injeção'));

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
      reasons.add('Atendimento e peças compatíveis com seu ${vehicle.shortName}');
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

    // Gera lista inteligente de serviços e dados enriquecidos
    final defaultServices = _generateServicesForCategory(parsedCategory.$1);

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
      supportedBrands: _detectSupportedBrands(rawName),
      specialties: _detectSpecialties(parsedCategory.$1, rawName),
      services: defaultServices,
      isOpenNow: true,
      openingHours: tags['opening_hours'] as String? ?? 'Seg - Sex: 08:00 - 18:00',
      isVerified: true,
      priceLevel: 'R\$ \$\$',
    );
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static (WorkshopCategory, String) _detectCategory(
      Map<String, dynamic> tags, String name) {
    final lower = name.toLowerCase();
    final shopTag = tags['shop'] as String? ?? '';
    final amenityTag = tags['amenity'] as String? ?? '';

    if (amenityTag == 'car_wash' ||
        lower.contains('lava') ||
        lower.contains('lavagem') ||
        lower.contains('estética') ||
        lower.contains('detailing')) {
      if (lower.contains('estética') || lower.contains('detailing') || lower.contains('polimento')) {
        return (WorkshopCategory.detailing, 'Estética Automotiva');
      }
      return (WorkshopCategory.carWash, 'Lava-Jato');
    }

    if (shopTag == 'tyres' ||
        lower.contains('pneu') ||
        lower.contains('borracharia')) {
      return (WorkshopCategory.tireShop, 'Borracharia & Pneus');
    }

    if (lower.contains('óleo') || lower.contains('oleo') || lower.contains('lubrificante')) {
      return (WorkshopCategory.oilChange, 'Troca de Óleo');
    }

    if (lower.contains('funilaria') || lower.contains('pintura') || lower.contains('martelinho')) {
      return (WorkshopCategory.bodyPaint, 'Funilaria e Pintura');
    }

    if (lower.contains('auto center') || lower.contains('autocenter') || lower.contains('centro automotivo')) {
      return (WorkshopCategory.autoCenter, 'Centro Automotivo');
    }

    if (lower.contains('especializada') ||
        lower.contains('volkswagen') ||
        lower.contains('honda') ||
        lower.contains('toyota') ||
        lower.contains('bmw')) {
      return (WorkshopCategory.specialist, 'Especializada em Marcas');
    }

    return (WorkshopCategory.mechanic, 'Oficina Mecânica');
  }

  static List<String> _detectSupportedBrands(String name) {
    final lower = name.toLowerCase();
    final brands = <String>[];
    if (lower.contains('volkswagen') || lower.contains('vw') || lower.contains('audi')) {
      brands.addAll(['Volkswagen', 'Audi', 'Porsche']);
    }
    if (lower.contains('honda') || lower.contains('toyota') || lower.contains('japones')) {
      brands.addAll(['Honda', 'Toyota', 'Nissan', 'Mitsubishi']);
    }
    if (lower.contains('bmw') || lower.contains('mercedes') || lower.contains('alema')) {
      brands.addAll(['BMW', 'Mercedes-Benz', 'Mini']);
    }
    if (lower.contains('fiat') || lower.contains('jeep')) {
      brands.addAll(['Fiat', 'Jeep', 'Ram']);
    }
    if (lower.contains('chevrolet') || lower.contains('gm')) {
      brands.addAll(['Chevrolet']);
    }

    if (brands.isEmpty) {
      brands.addAll(['Todas as marcas', 'Nacionais e Importados']);
    }
    return brands;
  }

  static List<String> _detectSpecialties(WorkshopCategory cat, String name) {
    switch (cat) {
      case WorkshopCategory.carWash:
        return ['Lavagem Ecológica', 'Higienização de Bancos', 'Cera de Carnaúba'];
      case WorkshopCategory.detailing:
        return ['Polimento Técnico', 'Vitrificação Cerâmica', 'Revitalização de Faróis'];
      case WorkshopCategory.oilChange:
        return ['Troca de Óleo a Vácuo', 'Filtros Originais', 'Flushing de Motor'];
      case WorkshopCategory.tireShop:
        return ['Alinhamento 3D', 'Balanceamento Computadorizado', 'Vulcanização'];
      case WorkshopCategory.bodyPaint:
        return ['Martelinho de Ouro', 'Pintura em Estufa', 'Reparos Rápidos'];
      case WorkshopCategory.autoCenter:
        return ['Revisão Preventiva', 'Freios ABS', 'Suspensão e Amortecedores', 'Ar-condicionado'];
      case WorkshopCategory.specialist:
        return ['Diagnóstico por Scanner Original', 'Câmbio Automático', 'Injeção Direta TSI/TFSI'];
      case WorkshopCategory.mechanic:
        return ['Mecânica Geral', 'Injeção Eletrônica', 'Freios e Discos', 'Embreagem'];
    }
  }

  static List<AutomotiveService> _generateServicesForCategory(WorkshopCategory cat) {
    switch (cat) {
      case WorkshopCategory.carWash:
        return const [
          AutomotiveService(
            id: 'cw_1',
            name: 'Lavagem Completa com Cera',
            category: 'Lavagem',
            estimatedPrice: 70.0,
            estimatedDuration: '45 min',
            description: 'Limpeza de lataria, aspiração interna, silicone e aplicação de cera protetora.',
            popular: true,
          ),
          AutomotiveService(
            id: 'cw_2',
            name: 'Higienização Interna e Bancos',
            category: 'Higienização',
            estimatedPrice: 220.0,
            estimatedDuration: '2h 30min',
            description: 'Lavagem e sanitização profunda de estofados, forro e carpetes.',
          ),
        ];
      case WorkshopCategory.detailing:
        return const [
          AutomotiveService(
            id: 'dt_1',
            name: 'Polimento Técnico Comercial',
            category: 'Estética',
            estimatedPrice: 450.0,
            estimatedDuration: '4 horas',
            description: 'Remoção de micro-riscos, swirls e aplicação de selante sintético de alto brilho.',
            popular: true,
          ),
          AutomotiveService(
            id: 'dt_2',
            name: 'Vitrificação de Pintura (Graphene Coating)',
            category: 'Proteção',
            estimatedPrice: 1200.0,
            estimatedDuration: '1 dia',
            description: 'Proteção cerâmica de alta dureza com garantia e repelência hídrica de 3 anos.',
          ),
        ];
      case WorkshopCategory.oilChange:
        return const [
          AutomotiveService(
            id: 'oc_1',
            name: 'Troca de Óleo 100% Sintético + Filtro',
            category: 'Lubrificação',
            estimatedPrice: 180.0,
            estimatedDuration: '30 min',
            description: 'Substituição de óleo sintético especificado e troca de filtro de óleo novo.',
            popular: true,
          ),
          AutomotiveService(
            id: 'oc_2',
            name: 'Pacote de 4 Filtros (Óleo, Ar, Combustível e Cabine)',
            category: 'Filtros',
            estimatedPrice: 140.0,
            estimatedDuration: '40 min',
            description: 'Troca preventiva de todos os filtros vitais do veículo.',
          ),
        ];
      case WorkshopCategory.tireShop:
        return const [
          AutomotiveService(
            id: 'ts_1',
            name: 'Alinhamento 3D + Balanceamento 4 Rodas',
            category: 'Geometria',
            estimatedPrice: 120.0,
            estimatedDuration: '45 min',
            description: 'Medição a laser dos ângulos de suspensão e balanceamento de precisão.',
            popular: true,
          ),
          AutomotiveService(
            id: 'ts_2',
            name: 'Conserto de Pneu / Reparo a Frio',
            category: 'Pneus',
            estimatedPrice: 40.0,
            estimatedDuration: '20 min',
            description: 'Conserto interno com plugue reforçado e teste de estanqueidade.',
          ),
        ];
      case WorkshopCategory.bodyPaint:
        return const [
          AutomotiveService(
            id: 'bp_1',
            name: 'Martelinho de Ouro (por peça)',
            category: 'Funilaria',
            estimatedPrice: 150.0,
            estimatedDuration: '1 hora',
            description: 'Remoção de amassados sem danificar a pintura original de fábrica.',
            popular: true,
          ),
          AutomotiveService(
            id: 'bp_2',
            name: 'Pintura de Para-choque em Estufa',
            category: 'Pintura',
            estimatedPrice: 480.0,
            estimatedDuration: '1 dia',
            description: 'Preparação, acerto de cor computadorizado e verniz bicomponente premium.',
          ),
        ];
      case WorkshopCategory.autoCenter:
      case WorkshopCategory.specialist:
      case WorkshopCategory.mechanic:
        return const [
          AutomotiveService(
            id: 'mc_1',
            name: 'Revisão Preventiva Completa',
            category: 'Mecânica',
            estimatedPrice: 280.0,
            estimatedDuration: '2 horas',
            description: 'Checkup de 40 itens essenciais: suspensão, freios, fluidos, correias e bateria.',
            popular: true,
          ),
          AutomotiveService(
            id: 'mc_2',
            name: 'Troca de Pastilhas e Discos de Freio',
            category: 'Freios',
            estimatedPrice: 250.0,
            estimatedDuration: '1h 30min',
            description: 'Substituição das pastilhas dianteiras e sangria do fluido de freio DOT 4.',
            popular: true,
          ),
          AutomotiveService(
            id: 'mc_3',
            name: 'Diagnóstico Eletrônico com Scanner',
            category: 'Injeção',
            estimatedPrice: 120.0,
            estimatedDuration: '40 min',
            description: 'Varredura de códigos de falha em todas as ECUs, sensores e atuadores.',
          ),
          AutomotiveService(
            id: 'mc_4',
            name: 'Higienização de Ar-Condicionado + Filtro de Cabine',
            category: 'Climatização',
            estimatedPrice: 130.0,
            estimatedDuration: '30 min',
            description: 'Oxi-sanitização com gerador de ozônio para eliminação de fungos e odores.',
          ),
        ];
    }
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
