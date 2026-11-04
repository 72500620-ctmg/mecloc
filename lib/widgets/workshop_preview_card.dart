import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vehicle.dart';
import '../models/workshop.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

class WorkshopPreviewCard extends StatelessWidget {
  const WorkshopPreviewCard({
    super.key,
    required this.workshop,
    required this.activeVehicle,
    required this.onTapDetail,
    required this.onClose,
  });

  final Workshop workshop;
  final Vehicle? activeVehicle;
  final VoidCallback onTapDetail;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final comp = workshop.calculateCompatibility(activeVehicle);

    return LiquidGlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: workshop.categoryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: workshop.categoryColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  workshop.iconData,
                  color: workshop.categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            workshop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (workshop.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: AppColors.forest),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          workshop.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        if (workshop.distanceKm != null) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.muted)),
                          Text(
                            '${workshop.distanceKm} km',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                        if (workshop.rating != null) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.muted)),
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.amberGold),
                          Text(
                            ' ${workshop.rating!.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),

          // Badge de compatibilidade do veículo
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: comp.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: comp.accentColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comp.isHighMatch ? Icons.verified_user_rounded : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: comp.accentColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    comp.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: comp.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final lat = workshop.latitude;
                    final lon = workshop.longitude;
                    if (lat != null && lon != null) {
                      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Rotas'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onTapDetail,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ver detalhes'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
