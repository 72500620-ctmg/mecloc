import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/auth_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workshop_image_helper.dart';
import 'auth/login_screen.dart';

class WorkshopRegistrationScreen extends StatefulWidget {
  const WorkshopRegistrationScreen({
    super.key,
    this.initialName,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    this.initialPhone,
    this.initialCategory,
    this.workshopToEdit,
  });

  final String? initialName;
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialPhone;
  final WorkshopCategory? initialCategory;
  final Workshop? workshopToEdit;

  @override
  State<WorkshopRegistrationScreen> createState() =>
      _WorkshopRegistrationScreenState();
}

class _WorkshopRegistrationScreenState
    extends State<WorkshopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _openingHoursController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  WorkshopCategory _selectedCategory = WorkshopCategory.mechanic;
  bool _hasEmergencyService = false;

  final Set<String> _selectedBrands = {'Todas as marcas (Multimarcas)'};
  final Set<String> _selectedSpecialties = {'Mecânica Geral', 'Injeção Eletrônica'};

  final _picker = ImagePicker();
  bool _isProcessingImage = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 75,
      );
      if (picked != null) {
        setState(() => _isProcessingImage = true);
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _imageUrlController.text = base64String;
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      setState(() => _isProcessingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar a imagem selecionada.')),
        );
      }
    }
  }
  static const _imagePresets = [
    (
      'Oficina Moderna',
      'https://images.unsplash.com/photo-1613214149922-f1809c99b414?auto=format&fit=crop&w=800&q=80',
    ),
    (
      'Auto Center & Elevador',
      'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80',
    ),
    (
      'Lava Jato & Estética',
      'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?auto=format&fit=crop&w=800&q=80',
    ),
    (
      'Pneus & Alinhamento',
      'https://images.unsplash.com/photo-1578844251758-2f71da64c96f?auto=format&fit=crop&w=800&q=80',
    ),
    (
      'Ferramentas & Motor',
      'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  bool get _isEditing => widget.workshopToEdit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.workshopToEdit;

    _nameController = TextEditingController(
      text: edit?.name ?? widget.initialName ?? '',
    );
    _whatsappController = TextEditingController(
      text: edit?.whatsappPhone ?? edit?.phone ?? widget.initialPhone ?? '',
    );
    _phoneController = TextEditingController(
      text: edit?.phone ?? widget.initialPhone ?? '',
    );
    _addressController = TextEditingController(
      text: edit?.address ??
          ((widget.initialAddress != null && widget.initialAddress != 'Endereço não informado')
              ? widget.initialAddress!
              : ''),
    );
    _cityController = TextEditingController();
    _openingHoursController = TextEditingController(
      text: edit?.openingHours ?? 'Seg a Sex: 08:00 - 18:00 | Sáb: 08:00 - 12:00',
    );
    _descriptionController = TextEditingController(
      text: edit?.description ?? '',
    );
    _imageUrlController = TextEditingController(
      text: edit?.imageUrl ?? '',
    );

    if (edit != null) {
      _selectedCategory = edit.categoryType;
      _selectedBrands.clear();
      _selectedBrands.addAll(edit.supportedBrands);
      if (_selectedBrands.isEmpty) {
        _selectedBrands.add('Todas as marcas (Multimarcas)');
      }

      _selectedSpecialties.clear();
      _selectedSpecialties.addAll(edit.specialties);
      _hasEmergencyService = edit.specialties.contains('Socorro Móvel / Guincho');
    } else if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
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
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitWorkshop() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.coralRed,
          content: Text('Você precisa estar logado para cadastrar ou gerenciar uma oficina.'),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final fullAddress = city.isNotEmpty ? '$address, $city' : address;
    final imageUrl = _imageUrlController.text.trim();

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

    final existing = widget.workshopToEdit;
    final fallbackCenter = context.read<WorkshopProvider>().searchCenter;
    final lat = existing?.latitude ?? widget.initialLatitude ?? fallbackCenter?.latitude;
    final lng = existing?.longitude ?? widget.initialLongitude ?? fallbackCenter?.longitude;

    final updatedWorkshop = Workshop(
      id: existing?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: fullAddress,
      latitude: lat,
      longitude: lng,
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
      rating: existing?.rating ?? 5.0,
      ratingCount: existing?.ratingCount ?? 1,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      description: _descriptionController.text.trim(),
      ownerId: existing?.ownerId ?? auth.user?.uid,
    );

    final provider = context.read<WorkshopProvider>();
    await provider.registerCustomWorkshop(updatedWorkshop);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF107C41),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isEditing
                    ? 'Oficina "$name" atualizada com sucesso!'
                    : 'Oficina "$name" cadastrada com sucesso!',
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final auth = context.watch<AuthProvider>();
    final isAuthenticated = auth.isAuthenticated;
    final currentUserId = auth.user?.uid;
    final myCustoms = isAuthenticated && currentUserId != null
        ? provider.customWorkshops
            .where((w) => w.ownerId == currentUserId || w.ownerId == null)
            .toList()
        : const <Workshop>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Personalizar Oficina' : 'Cadastre sua Oficina'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // Banner de Destaque
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF107C41), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? 'Personalize seu Estabelecimento'
                              : 'Receba Clientes no WhatsApp',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isEditing
                              ? 'Atualize fotos, serviços e horários para atrair mais motoristas.'
                              : 'Adicione fotos, especialidades e seu número para contato direto.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulário
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome da Oficina
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome da Oficina / Estabelecimento *',
                      prefixIcon: const Icon(Icons.business_rounded),
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
                  const SizedBox(height: 16),

                  // WhatsApp
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Comercial (com DDD) *',
                      hintText: 'Ex.: (11) 98888-7777 ou 11988887777',
                      prefixIcon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe o WhatsApp para cotações';
                      }
                      final digits = val.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 10) {
                        return 'Informe um número com DDD válido (pelo menos 10 dígitos)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Endereço
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Endereço Completo (Rua e Número) *',
                      prefixIcon: const Icon(Icons.place_rounded),
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
                  const SizedBox(height: 16),

                  // Cidade
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'Cidade e Estado',
                      hintText: 'Ex.: Belo Horizonte - MG',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Personalização visual & Foto da Fachada
                  const Text(
                    'Foto de Fachada / Imagem da Oficina',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),

                  // Botão de Selecionar Arquivo / Galeria ou Câmera
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isProcessingImage ? null : () => _pickImage(ImageSource.gallery),
                          icon: _isProcessingImage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_photo_alternate_rounded, color: AppColors.forest),
                          label: const Text(
                            'Escolher Foto do Arquivo',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Tirar Foto com a Câmera',
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: _isProcessingImage ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded, color: AppColors.forest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Preview da imagem selecionada
                  if (_imageUrlController.text.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            WorkshopImageHelper.buildImage(
                              imageUrl: _imageUrlController.text.trim(),
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.65),
                                radius: 16,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _imageUrlController.clear();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Campo opcional de URL manual caso o usuário prefira link
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Ou inserir link / URL de imagem manualmente',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                      children: [
                        TextFormField(
                          controller: _imageUrlController,
                          keyboardType: TextInputType.url,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'URL da Imagem',
                            hintText: 'https://exemplo.com/oficina.jpg',
                            prefixIcon: const Icon(Icons.link_rounded),
                            filled: true,
                            fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sugestões rápidas de fotos de fachada
                  const Text(
                    'Ou escolha uma foto de fachada profissional:',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final preset = _imagePresets[index];
                        final isSelected = _imageUrlController.text == preset.$2;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _imageUrlController.text = preset.$2;
                            });
                          },
                          child: Container(
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF107C41) : Colors.transparent,
                                width: 2.2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(preset.$2, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.75),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 5,
                                    left: 6,
                                    right: 6,
                                    child: Text(
                                      preset.$1,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 4,
                                      right: 4,
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundColor: Color(0xFF107C41),
                                        child: Icon(Icons.check, size: 12, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

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
                      DropdownMenuItem(
                        value: WorkshopCategory.detailing,
                        child: Text('Polimento & Detailing'),
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
                    label: Text(
                      _isEditing ? 'Salvar Alterações' : 'Cadastrar Oficina Gratuitamente',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Lista de oficinas já cadastradas pelo usuário
            if (myCustoms.isNotEmpty && !_isEditing) ...[
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
                      backgroundImage: w.imageUrl != null ? NetworkImage(w.imageUrl!) : null,
                      child: w.imageUrl == null
                          ? const Icon(Icons.verified_rounded, color: Color(0xFF107C41))
                          : null,
                    ),
                    title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${w.category} • ${w.phone ?? "Sem WhatsApp"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar oficina',
                          icon: const Icon(Icons.edit_outlined, color: AppColors.forest),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => WorkshopRegistrationScreen(
                                  workshopToEdit: w,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
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
                      ],
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
