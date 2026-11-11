import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import 'whatsapp_quote_modal.dart';
import 'workshop_detail_sheet.dart';

/// Dados de decisão primeiro; ações de salvar e cotar têm alvos independentes.
class WorkshopListTile extends StatefulWidget {
  const WorkshopListTile({super.key, required this.workshop});
  final Workshop workshop;

  @override
  State<WorkshopListTile> createState() => _WorkshopListTileState();
}

class _WorkshopListTileState extends State<WorkshopListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final workshop = widget.workshop;
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<WorkshopProvider>();
    final isFavorite = provider.isFavorite(workshop.id);
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 150),
          transform:
              Matrix4.translationValues(0, _hovered && !reduced ? -2 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border:
                Border.all(color: _hovered ? colors.primary : colors.outline),
          ),
          child: Material(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadii.card),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => WorkshopDetailSheet.show(context, workshop),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(workshop.iconData,
                                  color: colors.primary, size: 21),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(workshop.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.3,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3)),
                                  const SizedBox(height: 4),
                                  Text(workshop.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: colors.onSurfaceVariant)),
                                ])),
                            IconButton(
                              tooltip: isFavorite
                                  ? 'Remover dos favoritos'
                                  : 'Salvar nos favoritos',
                              isSelected: isFavorite,
                              selectedIcon: const Icon(Icons.favorite_rounded,
                                  color: AppColors.crimsonSos),
                              icon: const Icon(Icons.favorite_border_rounded),
                              iconSize: 21,
                              constraints: const BoxConstraints(
                                  minWidth: 48, minHeight: 48),
                              onPressed: () => provider.toggleFavorite(
                                  workshop.id, workshop),
                            ),
                          ]),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(children: [
                          Icon(Icons.location_on_outlined,
                              size: 15, color: colors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(workshop.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant))),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (workshop.distanceKm != null)
                                Text(workshop.formattedDistance,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary)),
                              if (workshop.rating != null)
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.star_rounded,
                                      size: 15, color: AppColors.amberGold),
                                  const SizedBox(width: 3),
                                  Text(workshop.rating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ]),
                              if (workshop.isCustomRegistered)
                                Text('OFICINA PARCEIRA',
                                    style: TextStyle(
                                        fontSize: 9,
                                        letterSpacing: 0.7,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary)),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('Ver oficina',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.onSurface)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 14),
                              ]),
                            ]),
                      ),
                      if (workshop.isCustomRegistered) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => WhatsAppQuoteModal.show(context,
                              workshop: workshop),
                          icon: const Icon(Icons.chat_outlined, size: 17),
                          label: const Text('Cotar via WhatsApp'),
                        ),
                      ],
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
