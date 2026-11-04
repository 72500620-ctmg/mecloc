import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote_request.dart';

class QuotesProvider extends ChangeNotifier {
  static const _quotesKey = 'saved_quotes_v1';

  List<QuoteRequest> _quotes = [];
  bool _isLoaded = false;

  List<QuoteRequest> get quotes => List.unmodifiable(_quotes);
  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_quotesKey);

    if (jsonList != null && jsonList.isNotEmpty) {
      _quotes = jsonList
          .map((item) => QuoteRequest.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } else {
      // Propostas padrão iniciais demonstrativas
      _quotes = [
        QuoteRequest(
          id: 'quote_1',
          workshopId: 'w_demo_1',
          workshopName: 'Precision Tech Oficina Mecânica',
          serviceName: 'Revisão Preventiva Geral (40 itens)',
          estimatedPrice: 'A partir de R\$ 320',
          estimatedDeadline: '1 dia útil',
          vehicleName: 'Volkswagen Golf Highline',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          notes: 'Inclui diagnóstico computadorizado e checkup completo.',
        ),
        QuoteRequest(
          id: 'quote_2',
          workshopId: 'w_demo_2',
          workshopName: 'Auto Center Aliança & Freios',
          serviceName: 'Troca de Pastilhas Dianteiras Cerâmica',
          estimatedPrice: 'A partir de R\$ 260',
          estimatedDeadline: 'Hoje (em 2 horas)',
          vehicleName: 'Volkswagen Golf Highline',
          status: 'scheduled',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          notes: 'Peças em estoque para pronto atendimento.',
        ),
      ];
      await _save();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addQuoteRequest({
    required String workshopId,
    required String workshopName,
    required String serviceName,
    required String estimatedPrice,
    required String vehicleName,
    String? notes,
  }) async {
    final newQuote = QuoteRequest(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      workshopId: workshopId,
      workshopName: workshopName,
      serviceName: serviceName,
      estimatedPrice: estimatedPrice,
      estimatedDeadline: '1 a 2 dias úteis',
      vehicleName: vehicleName,
      status: 'pending',
      createdAt: DateTime.now(),
      notes: notes,
    );

    _quotes = [newQuote, ..._quotes];
    await _save();
    notifyListeners();
  }

  Future<void> updateStatus(String quoteId, String newStatus) async {
    final index = _quotes.indexWhere((q) => q.id == quoteId);
    if (index != -1) {
      _quotes[index].status = newStatus;
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeQuote(String quoteId) async {
    _quotes = _quotes.where((q) => q.id != quoteId).toList();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _quotes.map((q) => jsonEncode(q.toJson())).toList();
    await prefs.setStringList(_quotesKey, jsonList);
  }
}

