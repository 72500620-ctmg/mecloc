import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotes_provider.dart';
import '../providers/vehicle_provider.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});
  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final service = TextEditingController();
  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotes = context.watch<QuotesProvider>();
    final vehicle = context.watch<VehicleProvider>().activeVehicle;
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos demonstrativos')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Simulação local',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text(
            'Experimente registrar um serviço. Nenhum pedido é enviado a oficinas e não há preços ou respostas reais.'),
        const SizedBox(height: 16),
        TextField(
            controller: service,
            decoration: const InputDecoration(
                labelText: 'Serviço que deseja simular',
                hintText: 'Ex.: revisão'),
            textInputAction: TextInputAction.done),
        const SizedBox(height: 12),
        Text(vehicle == null
            ? 'Nenhum veículo selecionado'
            : 'Veículo: ${vehicle.shortName}'),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: () async {
              final value = service.text.trim();
              if (value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Informe o serviço para criar uma simulação.')));
                return;
              }
              await quotes.addQuoteRequest(
                  workshopId: 'demo',
                  workshopName: 'Simulação local',
                  serviceName: value,
                  estimatedPrice: 'Sem preço real',
                  vehicleName: vehicle?.shortName ?? 'Não selecionado');
              service.clear();
              if (context.mounted) {
                FocusScope.of(context).unfocus();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Simulação salva neste dispositivo. Nenhum pedido foi enviado.')));
              }
            },
            child: const Text('Criar simulação')),
        const SizedBox(height: 24),
        Text('Simulações salvas',
            style: Theme.of(context).textTheme.titleMedium),
        if (quotes.quotes.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Nenhuma simulação salva.')),
        for (final quote in quotes.quotes)
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(quote.serviceName),
              subtitle: Text('Demonstração local · ${quote.vehicleName}'),
              trailing: IconButton(
                  tooltip: 'Excluir simulação',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => quotes.removeQuote(quote.id))),
      ]),
    );
  }
}
