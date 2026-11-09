import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../screens/workshop_detail_screen.dart';
import '../theme/app_theme.dart';
import 'whatsapp_quote_modal.dart';

class WorkshopListTile extends StatelessWidget {
  const WorkshopListTile({super.key, required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final isFavorite = provider.isFavorite(workshop.id);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => WorkshopDetailScreen(workshop: workshop),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.slateBorder,
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Icon Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: workshop.categoryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                workshop.iconData,
                color: workshop.categoryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Information Column
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (workshop.isCustomRegistered) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? const Color(0xFF34D399)
                                    : AppColors.emeraldDeep)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PARCEIRA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : AppColors.emeraldDeep,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          workshop.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      if (workshop.distanceKm != null) ...[
                        const Text(' • ',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.slateMuted)),
                        Text(
                          '${workshop.distanceKm} km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slateMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    workshop.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slateMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Actions: Quick Quote & Favorite
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (workshop.isCustomRegistered)
                  IconButton(
                    tooltip: 'Cotar via WhatsApp',
                    icon: Icon(
                      Icons.chat_outlined,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : AppColors.emeraldDeep,
                      size: 20,
                    ),
                    onPressed: () {
                      WhatsAppQuoteModal.show(context, workshop: workshop);
                    },
                  ),
                IconButton(
                  tooltip:
                      isFavorite ? 'Remover dos favoritos' : 'Salvar nos favoritos',
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.crimsonSos : AppColors.slateMuted,
                    size: 20,
                  ),
                  onPressed: () => provider.toggleFavorite(workshop.id, workshop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
