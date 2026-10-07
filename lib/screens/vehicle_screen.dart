import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Meu veículo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Veículos cadastrados',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Form(
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
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o modelo do veículo.'
                      : null,
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Placa (opcional)',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addVehicle,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar veículo'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_vehicles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Seus veículos salvos aparecerão aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (var index = 0; index < _vehicles.length; index++)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading:
                      const Icon(Icons.directions_car, color: AppColors.forest),
                  title: Text(_vehicles[index].split('|').first),
                  subtitle: Text(
                    _vehicles[index].split('|').length > 1 &&
                            _vehicles[index].split('|')[1].isNotEmpty
                        ? _vehicles[index].split('|')[1]
                        : 'Placa não informada',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remover veículo',
                    onPressed: () => _removeVehicle(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          const Text(
            'Histórico e lembretes de manutenção podem ser conectados a este cadastro nas próximas etapas.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
