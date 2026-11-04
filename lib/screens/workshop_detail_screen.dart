import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/automotive_service.dart';
import '../models/workshop.dart';
import '../providers/quotes_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

class WorkshopDetailScreen extends StatefulWidget {
  const WorkshopDetailScreen({super.key, required this.workshop});

  final Workshop workshop;

  @override
  State<WorkshopDetailScreen> createState() => _WorkshopDetailScreenState();
}

class _WorkshopDetailScreenState extends State<WorkshopDetailScreen> {
  int _selectedTab = 0; // 0: Serviços, 1: Sobre & Marcas, 2: Avaliações

  void _callPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone não informado por este estabelecimento.')),
      );
      return;
    }
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    launchUrl(Uri.parse('tel:$clean'));
  }

  void _openRoute() {
    final lat = widget.workshop.latitude;
    final lon = widget.workshop.longitude;
    if (lat != null && lon != null) {
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
      launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordenadas indisponíveis para traçar rota.')),
      );
    }
  }

  void _requestQuoteDialog(AutomotiveService? preSelectedService) {
    final vehicleProvider = context.read<VehicleProvider>();
    final quotesProvider = context.read<QuotesProvider>();
    final activeVehicle = vehicleProvider.activeVehicle;

    final service = preSelectedService ??
        (widget.workshop.services.isNotEmpty
            ? widget.workshop.services.first
            : const AutomotiveService(
                id: 'gen',
                name: 'Revisão e Diagnóstico Geral',
                category: 'Geral',
                estimatedPrice: 200,
                estimatedDuration: '1 hora',
                description: 'Checkup completo do veículo.',
              ));

    final notesController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Solicitar Orçamento / Agendamento',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Para ${widget.workshop.name}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 16),

                // Cartão com dados do serviço selecionado
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.forest.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Estimado: R\$ ${service.estimatedPrice.toStringAsFixed(0)} • ${service.estimatedDuration}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Veículo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 20, color: AppColors.forest),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          activeVehicle != null
                              ? 'Veículo: ${activeVehicle.displayName}'
                              : 'Veículo não selecionado',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observações ou sintomas do carro (opcional)',
                    hintText: 'Ex.: Barulho ao frear, luz de injeção acesa...',
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await quotesProvider.addQuoteRequest(
                        workshopId: widget.workshop.id,
                        workshopName: widget.workshop.name,
                        serviceName: service.name,
                        estimatedPrice: 'A partir de R\$ ${service.estimatedPrice.toStringAsFixed(0)}',
                        vehicleName: activeVehicle?.displayName ?? 'Veículo padrão',
                        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.forest,
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.leaf),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('Solicitação enviada! Acompanhe na aba "Atividade".'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Confirmar Solicitação'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final isFavorite = provider.isFavorite(widget.workshop.id);
    final activeVehicle = vehicleProvider.activeVehicle;
    final comp = widget.workshop.calculateCompatibility(activeVehicle);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. HERO APPBAR COM BANNER, TÍTULO E BOTÕES LIQUID GLASS
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LiquidGlassIconButton(
                size: 40,
                iconSize: 20,
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LiquidGlassIconButton(
                  size: 40,
                  iconSize: 20,
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isFavorite ? AppColors.coralRed : null,
                  onPressed: () => provider.toggleFavorite(widget.workshop.id),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradiente de fundo com ícone temático
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.workshop.categoryColor.withValues(alpha: 0.90),
                          AppColors.forestDark,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        widget.workshop.iconData,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),

                  // Overlay inferior com reflexo sutil
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            isDark ? AppColors.darkBackground : AppColors.paper,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Badges flutuantes no banner
                  Positioned(
                    left: 16,
                    bottom: 24,
                    child: Row(
                      children: [
                        LiquidGlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.amberGold),
                              const SizedBox(width: 4),
                              Text(
                                widget.workshop.rating?.toStringAsFixed(1) ?? '4.8',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              if (widget.workshop.ratingCount != null)
                                Text(
                                  ' (${widget.workshop.ratingCount})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        LiquidGlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          borderRadius: BorderRadius.circular(12),
                          child: Text(
                            widget.workshop.priceLevel,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CONTEÚDO PRINCIPAL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e verificado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.workshop.name,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (widget.workshop.isVerified) ...[
                        const SizedBox(width: 6),
                        const Tooltip(
                          message: 'Estabelecimento Homologado MecLoc',
                          child: Icon(Icons.verified, color: AppColors.forest, size: 24),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Endereço e Horários
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.workshop.address,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ),
                      if (widget.workshop.distanceKm != null)
                        Text(
                          '${widget.workshop.distanceKm} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F9D58),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Aberto agora • ${widget.workshop.openingHours}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // CARD DE COMPATIBILIDADE COM O VEÍCULO DO USUÁRIO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: comp.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: comp.accentColor.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: comp.accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comp.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: comp.accentColor,
                                    ),
                                  ),
                                  Text(
                                    activeVehicle != null
                                        ? activeVehicle.specsSummary
                                        : 'Selecione seu veículo para calibrar',
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ...comp.reasons.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_rounded, size: 16, color: comp.accentColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // BOTÕES DE AÇÃO RÁPIDA (Ligar, Rota, Orçamento, OSM)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _callPhone(widget.workshop.phone),
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Ligar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _openRoute,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('Como chegar'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ABAS DE CONTEÚDO (Serviços, Sobre & Especialidades, Avaliações)
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Serviços')),
                      ButtonSegment(value: 1, label: Text('Sobre & Marcas')),
                      ButtonSegment(value: 2, label: Text('Avaliações')),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: (set) => setState(() => _selectedTab = set.first),
                  ),
                  const SizedBox(height: 18),

                  // CONTEÚDO DA ABA SELECIONADA
                  if (_selectedTab == 0) ...[
                    // ABA SERVIÇOS
                    const Text(
                      'Serviços e Preços Estimados',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    ...widget.workshop.services.map(
                      (s) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkLine : AppColors.line,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          s.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                        ),
                                      ),
                                      if (s.popular) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.leaf.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'POPULAR',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.forest,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.description,
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'A partir de R\$ ${s.estimatedPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                      const Text(' • ', style: TextStyle(color: AppColors.muted)),
                                      Text(
                                        s.estimatedDuration,
                                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _requestQuoteDialog(s),
                              child: const Text('Pedir', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_selectedTab == 1) ...[
                    // ABA SOBRE E MARCAS
                    const Text(
                      'Marcas e Montadoras Atendidas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.workshop.supportedBrands.map((b) {
                        return Chip(
                          label: Text(b),
                          avatar: const Icon(Icons.directions_car_rounded, size: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Especialidades e Equipamentos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.workshop.specialties.map((s) {
                        return Chip(
                          label: Text(s),
                          avatar: const Icon(Icons.handyman_rounded, size: 16, color: AppColors.forest),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    if (widget.workshop.openStreetMapUrl != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => launchUrl(Uri.parse(widget.workshop.openStreetMapUrl!)),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver registro oficial no OpenStreetMap'),
                      ),
                  ] else ...[
                    // ABA AVALIAÇÕES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Comentários de Clientes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${widget.workshop.reviews.length} avaliações',
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.workshop.reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Nenhuma avaliação registrada ainda para esta oficina.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    else
                      ...widget.workshop.reviews.map(
                        (rev) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkLine : AppColors.line,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rev.authorName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: AppColors.amberGold),
                                      const SizedBox(width: 3),
                                      Text(
                                        rev.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (rev.carModel != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Proprietário de ${rev.carModel}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.forest, fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                rev.comment,
                                style: const TextStyle(fontSize: 13, height: 1.35),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rev.date,
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // BOTÃO INFERIOR FIXO PARA ORÇAMENTO / AGENDAMENTO
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(top: BorderSide(color: isDark ? AppColors.darkLine : AppColors.line)),
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _requestQuoteDialog(null),
            icon: const Icon(Icons.request_quote_rounded),
            label: const Text('Solicitar Orçamento / Agendar'),
          ),
        ),
      ),
    );
  }
}
