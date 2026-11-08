import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../screens/workshop_detail_screen.dart';
import '../theme/app_theme.dart';

class WorkshopListTile extends StatelessWidget {
  const WorkshopListTile({super.key, required this.workshop});
  final Workshop workshop;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final saved = provider.isFavorite(workshop.id);
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Flexible(
              child: Text(
                workshop.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: workshop.isCustomRegistered
                    ? const Color(0xFF107C41).withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                workshop.isCustomRegistered ? 'PARCEIRA' : 'MAPA',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: workshop.isCustomRegistered ? const Color(0xFF107C41) : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text([
          workshop.isCustomRegistered ? 'WhatsApp disponível' : 'Google Maps',
          workshop.category,
          workshop.address,
          if (workshop.distanceKm != null) '${workshop.distanceKm} km'
        ].join(' · ')),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: saved ? 'Remover dos favoritos' : 'Salvar nos favoritos',
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          onPressed: () => provider.toggleFavorite(workshop.id),
        ),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) => WorkshopDetailScreen(workshop: workshop))),
      ),
      const Divider(height: 1),
    ]);
  }
}
