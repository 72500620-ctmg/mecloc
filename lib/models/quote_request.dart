class QuoteRequest {
  QuoteRequest({
    required this.id,
    required this.workshopId,
    required this.workshopName,
    required this.serviceName,
    required this.estimatedPrice,
    required this.estimatedDeadline,
    required this.vehicleName,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String workshopId;
  final String workshopName;
  final String serviceName;
  final String estimatedPrice;
  final String estimatedDeadline;
  final String vehicleName;
  String status; // 'pending', 'approved', 'completed', 'scheduled'
  final DateTime createdAt;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'workshopId': workshopId,
        'workshopName': workshopName,
        'serviceName': serviceName,
        'estimatedPrice': estimatedPrice,
        'estimatedDeadline': estimatedDeadline,
        'vehicleName': vehicleName,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    return QuoteRequest(
      id: json['id'] as String? ?? '',
      workshopId: json['workshopId'] as String? ?? '',
      workshopName: json['workshopName'] as String? ?? 'Oficina',
      serviceName: json['serviceName'] as String? ?? 'Revisão',
      estimatedPrice: json['estimatedPrice'] as String? ?? 'Sob consulta',
      estimatedDeadline: json['estimatedDeadline'] as String? ?? '1 dia útil',
      vehicleName: json['vehicleName'] as String? ?? 'Meu veículo',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}

