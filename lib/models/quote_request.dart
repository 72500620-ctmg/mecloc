import 'package:flutter/material.dart';

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
    this.workshopPhone,
    this.workshopAddress,
    this.vehicleDetails,
  });

  final String id;
  final String workshopId;
  final String workshopName;
  final String serviceName;
  final String estimatedPrice;
  final String estimatedDeadline;
  final String vehicleName;
  String status; // 'pending', 'sent_whatsapp', 'scheduled', 'completed', 'cancelled'
  final DateTime createdAt;
  final String? notes;
  final String? workshopPhone;
  final String? workshopAddress;
  final String? vehicleDetails;

  String get statusLabel {
    switch (status) {
      case 'sent_whatsapp':
      case 'pending':
        return 'Enviado via WhatsApp';
      case 'scheduled':
        return 'Agendado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Em andamento';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'sent_whatsapp':
      case 'pending':
        return const Color(0xFF25D366); // WhatsApp green
      case 'scheduled':
        return const Color(0xFF007AFF); // Blue
      case 'completed':
        return const Color(0xFF107C41); // Forest green
      case 'cancelled':
        return const Color(0xFF8E8E93); // Grey
      default:
        return const Color(0xFFFF9500); // Amber
    }
  }

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
        'workshopPhone': workshopPhone,
        'workshopAddress': workshopAddress,
        'vehicleDetails': vehicleDetails,
      };

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    return QuoteRequest(
      id: json['id'] as String? ?? '',
      workshopId: json['workshopId'] as String? ?? '',
      workshopName: json['workshopName'] as String? ?? 'Oficina',
      serviceName: json['serviceName'] as String? ?? 'Revisão',
      estimatedPrice: json['estimatedPrice'] as String? ?? 'Sob consulta',
      estimatedDeadline: json['estimatedDeadline'] as String? ?? '1 a 2 dias úteis',
      vehicleName: json['vehicleName'] as String? ?? 'Meu veículo',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
      workshopPhone: json['workshopPhone'] as String?,
      workshopAddress: json['workshopAddress'] as String?,
      vehicleDetails: json['vehicleDetails'] as String?,
    );
  }
}
