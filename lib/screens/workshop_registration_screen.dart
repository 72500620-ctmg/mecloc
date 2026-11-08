import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';

class WorkshopRegistrationScreen extends StatefulWidget {
  const WorkshopRegistrationScreen({
    super.key,
    this.initialName,
    this.initialAddress,
  });

  final String? initialName;
  final String? initialAddress;

  @override
  State<WorkshopRegistrationScreen> createState() =>
      _WorkshopRegistrationScreenState();
}

class _WorkshopRegistrationScreenState
    extends State<WorkshopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _addressController;
  final _cityController = TextEditingController();
  final _openingHoursController = TextEditingController(
    text: 'Seg a Sex: 08:00 - 18:00 | Sáb: 08:00 - 12:00',
  );
  final _descriptionController = TextEditingController();

  WorkshopCategory _selectedCategory = WorkshopCategory.mechanic;
  bool _hasEmergencyService = false;

  final Set<String> _selectedBrands = {'Todas as marcas (Multimarcas)'};
  final Set<String> _selectedSpecialties = {'Mecânica Geral', 'Injeção Eletrônica'};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _addressController = TextEditingController(
      text: (widget.initialAddress != null && widget.initialAddress != 'Endereço não informado')
          ? widget.initialAddress!
          : '',
    );
  }

  static const _availableBrands = [
    'Todas as marcas (Multimarcas)',
    'Chevrolet / GM',
    'Volkswagen',
    'Fiat',
    'Ford',
    'Toyota',
    'Honda',
    'Hyundai',
    'Renault',
    'Nissan',
    'Jeep',
    'Peugeot / Citroën',
    'BMW / Mercedes-Benz / Audi',
  ];

  static const _availableSpecialties = [
    'Mecânica Geral',
    'Freios e ABS',
    'Suspensão e Direção',
    'Injeção Eletrônica',
    'Câmbio Automático',
    'Troca de Óleo e Filtros',
    'Ar Condicionado Automotivo',
    'Auto Elétrica e Baterias',
    'Alinhamento e Balanceamento',
    'Retífica de Motor',
    'Socorro Móvel / Guincho',
    'Funilaria e Pintura',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _openingHoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitWorkshop() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final fullAddress = city.isNotEmpty ? '$address, $city' : address;

    String catName;
    switch (_selectedCategory) {
      case WorkshopCategory.carWash:
        catName = 'Lava-jato';
        break;
      case WorkshopCategory.tireShop:
        catName = 'Borracharia e Pneus';
        break;
      case WorkshopCategory.oilChange:
        catName = 'Troca de Óleo';
        break;
      case WorkshopCategory.autoCenter:
        catName = 'Auto Center';
        break;
      case WorkshopCategory.detailing:
        catName = 'Estética Automotiva';
        break;
      case WorkshopCategory.bodyPaint:
        catName = 'Funilaria e Pintura';
        break;
      case WorkshopCategory.specialist:
        catName = 'Oficina Especializada';
        break;
      case WorkshopCategory.mechanic:
        catName = 'Oficina Mecânica';
        break;
    }

    final specialtiesList = _selectedSpecialties.toList();
    if (_hasEmergencyService && !specialtiesList.contains('Socorro Móvel / Guincho')) {
      specialtiesList.add('Socorro Móvel / Guincho');
    }

    final newWorkshop = Workshop(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: fullAddress,
      phone: whatsapp.isNotEmpty ? whatsapp : (phone.isNotEmpty ? phone : null),
      whatsappPhone: whatsapp,
      category: catName,
      categoryType: _selectedCategory,
      supportedBrands: _selectedBrands.toList(),
      specialties: specialtiesList,
      openingHours: _openingHoursController.text.trim(),
      isCustomRegistered: true,
      isVerified: true,
      isOpenNow: true,
      rating: 5.0,
      ratingCount: 1,
      description: _descriptionController.text.trim(),
    );

    final provider = context.read<WorkshopProvider>();
    await provider.registerCustomWorkshop(newWorkshop);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Oficina "$name" cadastrada com sucesso! Ela agora aparece no topo das buscas.'),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF107C41),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final myCustoms = provider.customWorkshops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Proprietário'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de destaque
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF132822), const Color(0xFF0C1B17)]
                      : [const Color(0xFF107C41), const Color(0xFF174D43)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cadastre seu Estabelecimento',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Apareça para motoristas da sua região e receba orçamentos pré-formatados no seu WhatsApp.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Formulário
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados do Estabelecimento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome da Oficina / Centro Automotivo *',
                      hintText: 'Ex.: Mecânica Silva & Irmãos',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe o nome do estabelecimento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp para Orçamentos *',
                      hintText: 'Ex.: 11987654321',
                      prefixIcon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe o WhatsApp para receber clientes';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Endereço Completo (Rua e Número) *',
                      hintText: 'Ex.: Av. das Américas, 1250, Barra',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe o endereço da oficina';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'Cidade e Estado',
                      hintText: 'Ex.: Rio de Janeiro - RJ',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Categoria
                  const Text(
                    'Categoria Principal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WorkshopCategory>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: WorkshopCategory.mechanic,
                        child: Text('Oficina Mecânica Geral'),
                      ),
                      DropdownMenuItem(
                        value: WorkshopCategory.autoCenter,
                        child: Text('Auto Center Completo'),
                      ),
                      DropdownMenuItem(
                        value: WorkshopCategory.tireShop,
                        child: Text('Borracharia e Pneus'),
                      ),
                      DropdownMenuItem(
                        value: WorkshopCategory.oilChange,
                        child: Text('Troca de Óleo e Lubrificantes'),
                      ),
                      DropdownMenuItem(
                        value: WorkshopCategory.specialist,
                        child: Text('Oficina Especializada / Injeção'),
                      ),
                      DropdownMenuItem(
                        value: WorkshopCategory.bodyPaint,
                        child: Text('Funilaria e Pintura'),
                      ),
                      DropdownMenuItem(
                        value: WorkshopCategory.carWash,
                        child: Text('Lava-jato / Estética'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Horário
                  TextFormField(
                    controller: _openingHoursController,
                    decoration: InputDecoration(
                      labelText: 'Horário de Atendimento',
                      prefixIcon: const Icon(Icons.schedule_rounded),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Switch de emergência
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Atende Emergências / Guincho / Socorro Móvel?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Sua oficina será recomendada no botão de SOS de emergência.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    value: _hasEmergencyService,
                    onChanged: (val) => setState(() => _hasEmergencyService = val),
                  ),
                  const SizedBox(height: 16),

                  // Marcas Atendidas
                  const Text(
                    'Marcas Atendidas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableBrands.map((brand) {
                      final isSelected = _selectedBrands.contains(brand);
                      return FilterChip(
                        label: Text(brand, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedBrands.add(brand);
                            } else {
                              if (_selectedBrands.length > 1) {
                                _selectedBrands.remove(brand);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Especialidades
                  const Text(
                    'Especialidades do Estabelecimento',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableSpecialties.map((spec) {
                      final isSelected = _selectedSpecialties.contains(spec);
                      return FilterChip(
                        label: Text(spec, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSpecialties.add(spec);
                            } else {
                              _selectedSpecialties.remove(spec);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Descrição
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Diferenciais da sua Oficina (opcional)',
                      hintText: 'Ex.: Garantia de serviço, scanner original de montadoras, sala de espera com café...',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF107C41),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _submitWorkshop,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Cadastrar Oficina Gratuitamente',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Lista de oficinas já cadastradas pelo usuário
            if (myCustoms.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Minhas Oficinas Cadastradas (${myCustoms.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...myCustoms.map((w) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF107C41).withValues(alpha: 0.15),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF107C41)),
                    ),
                    title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${w.category} • ${w.phone ?? "Sem WhatsApp"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remover cadastro',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
                      onPressed: () async {
                        await provider.removeCustomWorkshop(w.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Oficina removida do cadastro.')),
                          );
                        }
                      },
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

