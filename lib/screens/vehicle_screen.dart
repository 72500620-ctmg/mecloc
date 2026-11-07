import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../theme/app_theme.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  void _openAddVehicleSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddVehicleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          // Banner informativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF162E28), const Color(0xFF10201C)]
                    : [AppColors.forest, const Color(0xFF1C5F53)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garagem Inteligente',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Selecione seu veículo para calibrar especialidades, peças e orçamentos recomendados.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Text(
                '${vehicles.length} veículos',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
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
                      color: isDark ? Colors.white30 : AppColors.muted,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum veículo cadastrado',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cadastre seu carro para recomendações sob medida.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openAddVehicleSheet,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Cadastrar meu primeiro carro'),
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
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.forest
                        : (isDark ? AppColors.darkLine : AppColors.line),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.forest.withValues(alpha: 0.15),
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
                                      : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : AppColors.ink),
                              size: 24,
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
                                        v.displayName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15.5),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.forest
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'ATIVO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
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
                                      fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Excluir veículo',
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.muted, size: 20),
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
                          _SpecBadge(icon: Icons.speed_rounded, text: v.engine),
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

                      if (!isSelected)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () =>
                                vehicleProvider.selectVehicle(v.id),
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                size: 16),
                            label: const Text('Selecionar como veículo ativo'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

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
    super.dispose();
  }

  void _saveVehicle() {
    if (!_formKey.currentState!.validate()) return;

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
