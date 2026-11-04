class AutomotiveService {
  const AutomotiveService({
    required this.id,
    required this.name,
    required this.category,
    required this.estimatedPrice,
    required this.estimatedDuration,
    required this.description,
    this.popular = false,
  });

  final String id;
  final String name;
  final String category;
  final double estimatedPrice;
  final String estimatedDuration;
  final String description;
  final bool popular;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'estimatedPrice': estimatedPrice,
        'estimatedDuration': estimatedDuration,
        'description': description,
        'popular': popular,
      };

  factory AutomotiveService.fromJson(Map<String, dynamic> json) {
    return AutomotiveService(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Geral',
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: json['estimatedDuration'] as String? ?? '1 hora',
      description: json['description'] as String? ?? '',
      popular: json['popular'] as bool? ?? false,
    );
  }
}

