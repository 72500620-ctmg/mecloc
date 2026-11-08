import 'package:flutter/material.dart';

enum MaintenanceStatus {
  ok,
  warning,
  expired,
}

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.intervalKm,
    required this.lastDoneKm,
    required this.recommendedService,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final int intervalKm;
  final int lastDoneKm;
  final String recommendedService;
  final IconData icon;

  int nextDueKm() => lastDoneKm + intervalKm;
  int kmRemaining(int currentKm) => nextDueKm() - currentKm;

  MaintenanceStatus getStatus(int currentKm) {
    final diff = kmRemaining(currentKm);
    if (diff <= 0) return MaintenanceStatus.expired;
    if (diff <= 1500) return MaintenanceStatus.warning;
    return MaintenanceStatus.ok;
  }

  String statusText(int currentKm) {
    final diff = kmRemaining(currentKm);
    if (diff < 0) {
      final formatted = (-diff).toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
      return 'Vencido há $formatted km';
    }
    if (diff == 0) {
      return 'Revisão necessária agora!';
    }
    final formatted = diff.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Faltam $formatted km';
  }

  Color statusColor(int currentKm) {
    switch (getStatus(currentKm)) {
      case MaintenanceStatus.ok:
        return const Color(0xFF107C41); // Verde
      case MaintenanceStatus.warning:
        return const Color(0xFFFF9500); // Laranja
      case MaintenanceStatus.expired:
        return const Color(0xFFE53935); // Vermelho
    }
  }

  String statusBadgeLabel(int currentKm) {
    switch (getStatus(currentKm)) {
      case MaintenanceStatus.ok:
        return 'Em dia';
      case MaintenanceStatus.warning:
        return 'Próximo';
      case MaintenanceStatus.expired:
        return 'Revisar Já';
    }
  }
}

