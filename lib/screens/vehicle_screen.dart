import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/maintenance_item.dart';
import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_body.dart';
import '../widgets/whatsapp_quote_modal.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'main_shell.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  void _openAddVehicleSheet() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _showLoginRequiredDialog(context);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddVehicleSheet(),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Identifique-se'),
        content: const Text(
          'Para cadastrar veículos e salvar o histórico de manutenção na nuvem, acesse sua conta ou faça um cadastro rápido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Entrar ou Cadastrar'),
          ),
        ],
      ),
    );
  }

  void _editMileage(BuildContext context, Vehicle v) {
    final controller = TextEditingController(text: v.mileageKm.toString());
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atualizar Quilometragem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informe a km atual do seu ${v.shortName}:',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Quilometragem atual (km)',
                suffixText: 'km',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final newKm =
                  int.tryParse(controller.text.replaceAll(RegExp(r'\D'), ''));
              if (newKm != null && newKm > 0) {
                context.read<VehicleProvider>().updateMileage(v.id, newKm);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Odômetro atualizado para $newKm km!')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _markMaintenanceDone(
      BuildContext context, Vehicle v, MaintenanceItem item) {
    context
        .read<VehicleProvider>()
        .recordMaintenanceDone(v.id, item.id, v.mileageKm);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF107C41),
        content: Text(
            'Revisão "${item.title}" marcada como feita aos ${v.mileageKm} km!'),
      ),
    );
  }

  void _quoteMaintenance(
      BuildContext context, Vehicle v, MaintenanceItem item) {
    final workshopProvider = context.read<WorkshopProvider>();
    final workshops = workshopProvider.workshops.isNotEmpty
        ? workshopProvider.workshops
        : workshopProvider.customWorkshops;

    if (workshops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pesquise oficinas na aba "Explorar" para cotar este serviço.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cotar: ${item.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Escolha a oficina para cotar via WhatsApp para seu ${v.shortName}:',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: workshops.take(12).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final w = workshops[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: w.categoryColor.withValues(alpha: 0.15),
                      child: Icon(w.iconData, color: w.categoryColor, size: 20),
                    ),
                    title: Text(w.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(w.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      WhatsAppQuoteModal.show(
                        context,
                        workshop: w,
                        initialService: item.recommendedService,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final vehicleProvider = context.watch<VehicleProvider>();
    final vehicles = vehicleProvider.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Veículo',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Adicionar veículo',
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.forest, size: 26),
            onPressed: _openAddVehicleSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppPageBody(
          child: !isAuthenticated
              ? _buildGuestScreen(context, isDark)
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                      24, 8, 24, 32 + MediaQuery.paddingOf(context).bottom),
                  children: [
                    // Banner informativo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.directions_car_rounded,
                                color: colors.onPrimaryContainer, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Garagem Inteligente',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Selecione seu veículo para calibrar especialidades, peças e orçamentos recomendados.',
                                  style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Veículos cadastrados',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${vehicles.length} veículos',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (vehicles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.no_crash_rounded,
                                size: 54,
                                color:
                                    isDark ? Colors.white30 : AppColors.muted,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Nenhum veículo cadastrado',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Cadastre seu carro para recomendações sob medida.',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _openAddVehicleSheet,
                                icon: const Icon(Icons.add_rounded),
                                label:
                                    const Text('Cadastrar meu primeiro carro'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...vehicles.map((v) {
                        final isSelected = v.isSelected;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.forest
                                  : (isDark
                                      ? AppColors.darkLine
                                      : AppColors.line),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.forest
                                          .withValues(alpha: 0.15),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.forest
                                            : (isDark
                                                ? Colors.white10
                                                : Colors.black
                                                    .withValues(alpha: 0.05)),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.directions_car_rounded,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white70
                                                : AppColors.ink),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  v.displayName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 15.5),
                                                ),
                                              ),
                                              if (isSelected) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 7,
                                                      vertical: 2.5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.forest
                                                        .withValues(
                                                            alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Text(
                                                    'ATIVO',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.forest,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            v.plate.isNotEmpty
                                                ? 'Placa: ${v.plate}'
                                                : 'Placa não cadastrada',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Excluir veículo',
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.muted,
                                          size: 20),
                                      onPressed: () =>
                                          vehicleProvider.removeVehicle(v.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),

                                // Detalhes técnicos em tags
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _SpecBadge(
                                        icon: Icons.speed_rounded,
                                        text: v.engine),
                                    _SpecBadge(
                                        icon: Icons.local_gas_station_rounded,
                                        text: v.fuel),
                                    _SpecBadge(
                                        icon: Icons.settings_rounded,
                                        text: v.transmission),
                                    _SpecBadge(
                                        icon: Icons.calendar_today_rounded,
                                        text: v.year.toString()),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Odômetro e Quilometragem
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.speed_rounded,
                                          size: 18, color: AppColors.forest),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Odômetro: ${v.mileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} km',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            _editMileage(context, v),
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 12),
                                        label: const Text('Atualizar',
                                            style: TextStyle(fontSize: 11.5)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Painel de Manutenção Preventiva do Veículo Ativo
                                if (isSelected) ...[
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.health_and_safety_rounded,
                                          color: AppColors.forest,
                                          size: 18),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                          'Saúde & Manutenção',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.forest
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${v.getMaintenanceList().where((m) => m.getStatus(v.mileageKm) == MaintenanceStatus.ok).length} em dia',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ...v.getMaintenanceList().map((item) {
                                    final color = item.statusColor(v.mileageKm);
                                    final statusLabel =
                                        item.statusBadgeLabel(v.mileageKm);
                                    final diffText =
                                        item.statusText(v.mileageKm);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.03)
                                            : const Color(0xFFF9F9F9),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.3),
                                          width: 1.1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(item.icon,
                                                  size: 18, color: color),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13.5),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                      alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: color,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            diffText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 6),
                                                    minimumSize:
                                                        const Size(0, 34),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                  ),
                                                  onPressed: () =>
                                                      _markMaintenanceDone(
                                                          context, v, item),
                                                  icon: const Icon(
                                                      Icons.check_rounded,
                                                      size: 14),
                                                  label: const Text(
                                                      'Feita hoje',
                                                      style: TextStyle(
                                                          fontSize: 11.5)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: FilledButton.tonalIcon(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF25D366)
                                                            .withValues(
                                                                alpha: 0.15),
                                                    foregroundColor:
                                                        const Color(0xFF107C41),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 6),
                                                    minimumSize:
                                                        const Size(0, 34),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                  ),
                                                  onPressed: () =>
                                                      _quoteMaintenance(
                                                          context, v, item),
                                                  icon: const Icon(
                                                      Icons.chat_bubble_rounded,
                                                      size: 13),
                                                  label: const Text(
                                                      'Cotar WhatsApp',
                                                      style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],

                                if (!isSelected)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onPressed: () =>
                                          vehicleProvider.selectVehicle(v.id),
                                      icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 16),
                                      label: const Text(
                                          'Selecionar como veículo ativo'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                    if (vehicles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _openAddVehicleSheet,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Adicionar novo veículo'),
                      ),
                    ],
                  ],
                )),
    );
  }

  Widget _buildGuestScreen(BuildContext context, bool isDark) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 32 + MediaQuery.paddingOf(context).bottom),
      children: [
        // Hero Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.slateInk,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.garage_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Garagem na Nuvem MecLoc',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Revisões e quilometragem em um só lugar',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Cadastre seus veículos para ter alertas de revisão preventiva, filtros automáticos de oficinas especializadas e orçamentos salvos na nuvem.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Ações de Autenticação
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forest,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            );
          },
          icon: const Icon(Icons.login_rounded),
          label: const Text(
            'Entrar com minha conta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppColors.forest, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
            );
          },
          icon: const Icon(Icons.person_add_outlined, color: AppColors.forest),
          label: const Text(
            'Criar conta gratuita',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () {
              MainShellNavigation.switchToTab(0);
            },
            child: const Text(
              'Continuar explorando oficinas no mapa',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'VANTAGENS DE CADASTRAR SEU VEÍCULO',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),

        _buildBenefitCard(
          isDark: isDark,
          icon: Icons.notifications_active_rounded,
          iconColor: const Color(0xFFE67E22),
          title: 'Alertas de Revisão Preventiva',
          subtitle:
              'Acompanhe quando trocar óleo, filtros, pastilhas de freio e correia dentada antes de quebras inesperadas.',
        ),
        const SizedBox(height: 10),
        _buildBenefitCard(
          isDark: isDark,
          icon: Icons.verified_rounded,
          iconColor: AppColors.forest,
          title: 'Oficinas 100% Compatíveis',
          subtitle:
              'Filtre oficinas que possuem maquinário, peças e mecânicos capacitados especificamente para a marca e motor do seu carro.',
        ),
        const SizedBox(height: 10),
        _buildBenefitCard(
          isDark: isDark,
          icon: Icons.cloud_sync_rounded,
          iconColor: const Color(0xFF2980B9),
          title: 'Histórico Seguro e Sincronizado',
          subtitle:
              'Consulte seus veículos e revisões ao acessar sua conta em outro dispositivo.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBenefitCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isDark ? AppColors.darkLine : AppColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecBadge extends StatelessWidget {
  const _SpecBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AddVehicleSheet extends StatefulWidget {
  const _AddVehicleSheet();

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();

  String _brand = 'Volkswagen';
  final _modelController = TextEditingController(text: 'Polo');
  final _versionController = TextEditingController(text: 'Comfortline TSI');
  int _year = 2023;
  String _engine = '1.0 TSI Turbo';
  String _fuel = 'Flex';
  String _transmission = 'Automático';
  final _plateController = TextEditingController();
  final _mileageController = TextEditingController(text: '45000');

  final List<String> _popularBrands = const [
    'Volkswagen',
    'Chevrolet',
    'Fiat',
    'Toyota',
    'Honda',
    'Hyundai',
    'Jeep',
    'Renault',
    'Nissan',
    'Ford',
    'BMW',
    'Audi',
    'Mercedes-Benz',
    'Outra',
  ];

  final List<String> _fuels = const [
    'Flex',
    'Gasolina',
    'Etanol',
    'Diesel',
    'Híbrido',
    'Elétrico'
  ];
  final List<String> _transmissions = const [
    'Manual',
    'Automático',
    'CVT',
    'Dupla Embreagem'
  ];

  @override
  void dispose() {
    _modelController.dispose();
    _versionController.dispose();
    _plateController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _saveVehicle() {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Faça login ou crie sua conta para cadastrar veículos na nuvem.'),
        ),
      );
      return;
    }

    final km =
        int.tryParse(_mileageController.text.replaceAll(RegExp(r'\D'), '')) ??
            45000;

    final vehicle = Vehicle(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      brand: _brand,
      model: _modelController.text.trim(),
      year: _year,
      engine: _engine,
      fuel: _fuel,
      transmission: _transmission,
      version: _versionController.text.trim(),
      plate: _plateController.text.trim().toUpperCase(),
      isSelected: true,
      mileageKm: km,
      lastOilChangeKm: km > 5000 ? km - 5000 : 0,
      lastBrakesKm: km > 15000 ? km - 15000 : 0,
      lastFiltersKm: km > 5000 ? km - 5000 : 0,
      lastTimingBeltKm: 0,
    );

    context.read<VehicleProvider>().addVehicle(vehicle);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        content: Text(
            'Veículo ${vehicle.displayName} cadastrado e definido como ativo!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                  'Cadastrar Veículo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Preencha as informações para compatibilidade técnica perfeita.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 16),

                // Marca
                DropdownButtonFormField<String>(
                  initialValue: _brand,
                  decoration:
                      const InputDecoration(labelText: 'Marca / Montadora'),
                  items: _popularBrands
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) => setState(() => _brand = val ?? _brand),
                ),
                const SizedBox(height: 12),

                // Modelo e Versão
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                            labelText: 'Modelo',
                            hintText: 'Ex.: Civic, Onix, Golf'),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Informe o modelo'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _versionController,
                        decoration: const InputDecoration(
                            labelText: 'Versão',
                            hintText: 'Ex.: Highline, LTZ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Ano e Motorização
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<int>(
                        initialValue: _year,
                        decoration: const InputDecoration(labelText: 'Ano'),
                        items: List.generate(
                                25, (index) => DateTime.now().year - index + 1)
                            .map((y) => DropdownMenuItem(
                                value: y, child: Text(y.toString())))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _year = val ?? _year),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _engine,
                        decoration: const InputDecoration(
                            labelText: 'Motorização',
                            hintText: 'Ex.: 1.0 Flex, 1.4 TSI'),
                        onChanged: (val) => _engine = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Câmbio e Combustível
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _transmission,
                        decoration: const InputDecoration(labelText: 'Câmbio'),
                        items: _transmissions
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) => setState(
                            () => _transmission = val ?? _transmission),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fuel,
                        decoration:
                            const InputDecoration(labelText: 'Combustível'),
                        items: _fuels
                            .map((f) =>
                                DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _fuel = val ?? _fuel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quilometragem atual
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem atual (km)',
                    hintText: 'Ex.: 48500',
                    prefixIcon: Icon(Icons.speed_rounded),
                    suffixText: 'km',
                  ),
                ),
                const SizedBox(height: 12),

                // Placa
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Placa (opcional)',
                    hintText: 'Ex.: BRA2E19',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveVehicle,
                    child: const Text('Salvar Veículo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
