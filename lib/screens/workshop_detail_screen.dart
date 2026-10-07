import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import 'quotes_screen.dart';

class WorkshopDetailScreen extends StatelessWidget {
  const WorkshopDetailScreen({super.key, required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final isFavorite = provider.isFavorite(workshop.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Oficina')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child:
                  Icon(Icons.handyman_outlined, size: 58, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  workshop.name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    isFavorite ? 'Remover dos favoritos' : 'Favoritar oficina',
                onPressed: () => provider.toggleFavorite(workshop.id),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : AppColors.forest,
                ),
              ),
            ],
          ),
          if (workshop.rating != null)
            _InfoLine(
              icon: Icons.star,
              text:
                  '${workshop.rating!.toStringAsFixed(1)}${workshop.ratingCount == null ? '' : ' · ${workshop.ratingCount} avaliações'}',
            ),
          _InfoLine(icon: Icons.location_on_outlined, text: workshop.address),
          if (workshop.phone != null)
            _InfoLine(icon: Icons.phone_outlined, text: workshop.phone!),
          const SizedBox(height: 18),
          const Text(
            'Informações',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dados colaborativos do OpenStreetMap podem estar incompletos. '
            'Confirme endereço, serviços, horários e valores diretamente com a oficina.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const QuotesScreen()),
            ),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Solicitar orçamento'),
          ),
          if (workshop.openStreetMapUrl != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(workshop.openStreetMapUrl!)),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver no OpenStreetMap'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.forest),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
