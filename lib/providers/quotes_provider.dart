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
          .map((item) =>
              QuoteRequest.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
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
