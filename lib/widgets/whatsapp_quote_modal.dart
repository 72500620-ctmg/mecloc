import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vehicle.dart';
import '../models/workshop.dart';
import '../providers/quotes_provider.dart';
import '../providers/vehicle_provider.dart';
import '../theme/app_theme.dart';

class WhatsAppQuoteModal extends StatefulWidget {
  const WhatsAppQuoteModal({
    super.key,
    required this.workshop,
    this.initialService,
  });

  final Workshop workshop;
  final String? initialService;

  static Future<void> show(
    BuildContext context, {
    required Workshop workshop,
    String? initialService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhatsAppQuoteModal(
        workshop: workshop,
        initialService: initialService,
      ),
    );
  }

  @override
  State<WhatsAppQuoteModal> createState() => _WhatsAppQuoteModalState();
}

class _WhatsAppQuoteModalState extends State<WhatsAppQuoteModal> {
  late final TextEditingController _serviceController;
  final _notesController = TextEditingController();
  Vehicle? _selectedVehicle;

  static const _commonServices = [
    'Troca de Óleo e Filtros',
    'Pastilhas e Discos de Freio',
    'Revisão Preventiva Geral',
    'Alinhamento e Balanceamento',
    'Diagnóstico / Luz de Injeção',
    'Troca de Correia Dentada',
    'Ar Condicionado / Higienização',
    'Troca de Bateria',
    'Embreagem e Câmbio',
    'Suspensão e Amortecedores',
  ];

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(text: widget.initialService ?? '');
    final vehicleProvider = context.read<VehicleProvider>();
    _selectedVehicle = vehicleProvider.activeVehicle ??
        (vehicleProvider.vehicles.isNotEmpty ? vehicleProvider.vehicles.first : null);
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitQuote() async {
    final service = _serviceController.text.trim();
    if (service.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o serviço desejado.')),
      );
      return;
    }

    final notes = _notesController.text.trim();
    final quotesProvider = context.read<QuotesProvider>();
    final vehicle = _selectedVehicle;
    final workshop = widget.workshop;

    final uri = QuotesProvider.buildWhatsAppUri(
      workshop: workshop,
      vehicle: vehicle,
      serviceName: service,
      notes: notes,
    );

    final parentContext = context;
    Navigator.of(context).pop();

    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Erro ao abrir o WhatsApp.')),
          );
        }
      }

      if (!parentContext.mounted) return;

      // Diálogo de confirmação de envio pós-WhatsApp
      final confirmed = await showDialog<bool>(
        context: parentContext,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
              SizedBox(width: 10),
              Text('Confirmação'),
            ],
          ),
          content: Text(
            'Você chegou a enviar a mensagem no WhatsApp para a ${workshop.name}?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Não enviei'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF107C41),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sim, enviei'),
            ),
          ],
        ),
      );

      if (confirmed == true && parentContext.mounted) {
        await quotesProvider.recordConfirmedQuote(
          workshop: workshop,
          vehicle: vehicle,
          serviceName: service,
          notes: notes,
        );
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(
              content: Text('Cotação confirmada e salva nos seus orçamentos!'),
              backgroundColor: Color(0xFF107C41),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text('Tudo bem, nenhuma cotação foi registrada.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Esta oficina não possui WhatsApp cadastrado para contato direto.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vehicleProvider = context.watch<VehicleProvider>();
    final vehicles = vehicleProvider.vehicles;
    final hasPhone = widget.workshop.phone != null && widget.workshop.phone!.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Área de toque superior para arrastar e fechar (Drag Handle)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 80) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                alignment: Alignment.center,
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Header fixo com ícone, título e botão fechar (X)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orçamento via WhatsApp',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          widget.workshop.name,
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.6),

            // Conteúdo scrollável com fechamento por pull-down overscroll
            Flexible(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification &&
                      notification.overscroll < -18) {
                    Navigator.of(context).pop();
                    return true;
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasPhone)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Esta oficina não tem WhatsApp listado no mapa. O orçamento será salvo no seu histórico do app.',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Seleção de Veículo
                      const Text(
                        'Veículo para o orçamento',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (vehicles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.directions_car_outlined, size: 20, color: AppColors.muted),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Nenhum carro cadastrado. Cadastre na aba "Veículos" para preenchimento automático.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Vehicle>(
                          initialValue: _selectedVehicle,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: vehicles.map((v) {
                            return DropdownMenuItem<Vehicle>(
                              value: v,
                              child: Text('${v.displayName}${v.plate.isNotEmpty ? " • ${v.plate}" : ""}'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedVehicle = val),
                        ),

                      const SizedBox(height: 16),
                      const Text(
                        'Serviço desejado',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _serviceController,
                        decoration: InputDecoration(
                          hintText: 'Ex.: Troca de pastilhas de freio dianteiras',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Atalhos de serviços mais comuns
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _commonServices.map((serviceName) {
                          final isSelected = _serviceController.text == serviceName;
                          return ChoiceChip(
                            label: Text(serviceName, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _serviceController.text = selected ? serviceName : '';
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Observações / Sintomas (opcional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ex.: Barulho ao frear, carro trepida em alta velocidade...',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submitQuote,
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          hasPhone ? 'Enviar Orçamento via WhatsApp' : 'Registrar Solicitação no App',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
