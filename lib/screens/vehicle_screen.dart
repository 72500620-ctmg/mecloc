import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  static const _vehiclesKey = 'saved_vehicles';

  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  List<String> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _vehicles = preferences.getStringList(_vehiclesKey) ?? []);
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    final vehicle =
        '${_modelController.text.trim()}|${_plateController.text.trim()}';
    final updated = [..._vehicles, vehicle];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_vehiclesKey, updated);
    if (!mounted) return;
    setState(() => _vehicles = updated);
    _modelController.clear();
    _plateController.clear();
  }

  Future<void> _removeVehicle(int index) async {
    final updated = [..._vehicles]..removeAt(index);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_vehiclesKey, updated);
    if (mounted) setState(() => _vehicles = updated);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Meu veículo')),
          SliverPadding(
            padding: contentPadding(context, top: 4),
            sliver: SliverList.list(
              children: [
                Text('Veículos cadastrados', style: text.titleLarge),
                const SizedBox(height: 14),
                AppSurface(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _modelController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Modelo e ano',
                            hintText: 'Ex.: Onix LT 2020',
                            prefixIcon: Icon(Icons.directions_car_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Informe o modelo do veículo.'
                                  : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _plateController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Placa (opcional)',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        PressableScale(
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _addVehicle,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Adicionar veículo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _vehicles.isEmpty
                      ? Padding(
                          key: const ValueKey('empty'),
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Column(
                            children: [
                              Icon(Icons.garage_outlined,
                                  size: 40, color: t.muted),
                              const SizedBox(height: 8),
                              Text(
                                'Seus veículos salvos aparecerão aqui.',
                                textAlign: TextAlign.center,
                                style: text.bodyMedium?.copyWith(color: t.muted),
                              ),
                            ],
                          ),
                        )
                      : AppSurface(
                          key: const ValueKey('list'),
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < _vehicles.length;
                                  index++) ...[
                                if (index > 0)
                                  const Divider(indent: 72, endIndent: 18),
                                FadeSlideIn(
                                  key: ValueKey(_vehicles[index]),
                                  index: index,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        16, 6, 8, 6),
                                    leading: IconBadge(
                                      icon: Icons.directions_car_rounded,
                                      size: 42,
                                      background: t.surfaceAlt,
                                      foreground: t.ink,
                                    ),
                                    title: Text(
                                      _vehicles[index].split('|').first,
                                      style: text.titleMedium,
                                    ),
                                    subtitle: Text(
                                      _vehicles[index].split('|').length > 1 &&
                                              _vehicles[index]
                                                  .split('|')[1]
                                                  .isNotEmpty
                                          ? _vehicles[index].split('|')[1]
                                          : 'Placa não informada',
                                      style: TextStyle(color: t.muted),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Remover veículo',
                                      onPressed: () => _removeVehicle(index),
                                      icon: const Icon(
                                          Icons.delete_outline_rounded),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Histórico e lembretes de manutenção podem ser conectados a este cadastro nas próximas etapas.',
                  style: text.bodySmall?.copyWith(color: t.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
