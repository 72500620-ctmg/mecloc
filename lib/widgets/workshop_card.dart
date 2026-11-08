import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../screens/workshop_detail_screen.dart';
import '../theme/app_theme.dart';

class WorkshopCard extends StatelessWidget {
  const WorkshopCard({
    super.key,
    required this.workshop,
    required this.activeVehicle,
  });

  final Workshop workshop;
  final Vehicle? activeVehicle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final isFavorite = provider.isFavorite(workshop.id);
    final comp = workshop.calculateCompatibility(activeVehicle);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.darkLine : AppColors.line,
          width: 1.2,
        ),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => WorkshopDetailScreen(workshop: workshop),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Category icon, Name, Category, Favorite button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: workshop.categoryColor.withValues(alpha: 0.16),
                      child: (workshop.imageUrl != null && workshop.imageUrl!.isNotEmpty)
                          ? Image.network(
                              workshop.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                workshop.iconData,
                                color: workshop.categoryColor,
                                size: 24,
                              ),
                            )
                          : Icon(
                              workshop.iconData,
                              color: workshop.categoryColor,
                              size: 24,
                            ),
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (workshop.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: AppColors.forest,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          workshop.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? AppColors.coralRed : AppColors.muted,
                      size: 22,
                    ),
                    onPressed: () => provider.toggleFavorite(workshop.id),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Badges row: Category, Distance, Rating, Compatibility
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (workshop.isCustomRegistered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: Color(0xFF107C41)),
                          SizedBox(width: 4),
                          Text(
                            'PARCEIRA',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF107C41),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public_rounded, size: 12, color: AppColors.muted),
                          SizedBox(width: 4),
                          Text(
                            'MAPA ABERTO',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Categoria
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: workshop.categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      workshop.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: workshop.categoryColor,
                      ),
                    ),
                  ),

                  // Distância
                  if (workshop.distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(
                            '${workshop.distanceKm} km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Avaliação
                  if (workshop.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.amberGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppColors.amberGold),
                          const SizedBox(width: 3),
                          Text(
                            workshop.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber,
                            ),
                          ),
                          if (workshop.ratingCount != null)
                            Text(
                              ' (${workshop.ratingCount})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Compatibilidade com veículo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: comp.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: comp.accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comp.isHighMatch ? Icons.verified_user : Icons.check_circle_rounded,
                          size: 12,
                          color: comp.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comp.isHighMatch
                              ? '100% Especialista'
                              : '${comp.percentage}% Compatível',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: comp.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Principais serviços oferecidos
              if (workshop.services.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.8),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        workshop.services.take(2).map((s) => s.name).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'A partir de R\$ ${workshop.services.first.estimatedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
