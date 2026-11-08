import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote_request.dart';
import '../models/vehicle.dart';
import '../models/workshop.dart';

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

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('quotes').get();
      if (snapshot.docs.isNotEmpty) {
        final cloudQuotes = <QuoteRequest>[];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            cloudQuotes.add(QuoteRequest.fromJson(data));
          } catch (_) {}
        }
        if (cloudQuotes.isNotEmpty) {
          _quotes = cloudQuotes;
          await _save();
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch quotes fallback: $e');
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Normaliza números de telefone brasileiros para o formato do WhatsApp (E.164 sem +)
  static String formatPhoneForWhatsApp(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 10 || digits.length == 11) {
      digits = '55$digits';
    }
    return digits;
  }

  /// Monta o texto padronizado e profissional para o orçamento no WhatsApp
  static String generateWhatsAppMessage({
    required Workshop workshop,
    required Vehicle? vehicle,
    required String serviceName,
    String? notes,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('👋 *Olá, equipe da ${workshop.name}!*');
    buffer.writeln('Encontrei sua oficina no aplicativo *MecLoc* e gostaria de solicitar um orçamento.');
    buffer.writeln('');
    buffer.writeln('🛠️ *Serviço desejado:* $serviceName');

    if (vehicle != null) {
      buffer.writeln('');
      buffer.writeln('🚗 *Dados do Veículo:*');
      buffer.writeln('• Modelo: ${vehicle.displayName}');
      if (vehicle.plate.trim().isNotEmpty) {
        buffer.writeln('• Placa: ${vehicle.plate}');
      }
      buffer.writeln('• Motor / Câmbio: ${vehicle.specsSummary}');
    }

    if (notes != null && notes.trim().isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📝 *Detalhes adicionais:* ${notes.trim()}');
    }

    buffer.writeln('');
    buffer.writeln('Poderiam me informar valores estimados e disponibilidade para atendimento? Obrigado!');
    return buffer.toString();
  }

  /// Monta a URI do WhatsApp pronta para abertura
  static Uri? buildWhatsAppUri({
    required Workshop workshop,
    required Vehicle? vehicle,
    required String serviceName,
    String? notes,
  }) {
    final phone = workshop.phone?.trim();
    if (phone == null || phone.isEmpty) return null;
    final phoneDigits = formatPhoneForWhatsApp(phone);
    if (phoneDigits.isEmpty) return null;

    final message = generateWhatsAppMessage(
      workshop: workshop,
      vehicle: vehicle,
      serviceName: serviceName,
      notes: notes,
    );
    final encodedText = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$phoneDigits?text=$encodedText');
  }

  /// Registra a cotação após o usuário confirmar o envio no WhatsApp (local e nuvem)
  Future<QuoteRequest> recordConfirmedQuote({
    required Workshop workshop,
    required Vehicle? vehicle,
    required String serviceName,
    String? notes,
  }) async {
    final phone = workshop.phone?.trim();
    final newQuote = QuoteRequest(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      workshopId: workshop.id,
      workshopName: workshop.name,
      serviceName: serviceName,
      estimatedPrice: 'Sob consulta via WhatsApp',
      estimatedDeadline: 'A combinar',
      vehicleName: vehicle != null ? vehicle.shortName : 'Veículo geral',
      status: 'sent_whatsapp',
      createdAt: DateTime.now(),
      notes: notes,
      workshopPhone: phone,
      workshopAddress: workshop.address,
      vehicleDetails: vehicle?.displayName,
    );

    _quotes = [newQuote, ..._quotes];
    await _save();
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('quotes')
          .doc(newQuote.id)
          .set(newQuote.toJson());
    } catch (e) {
      debugPrint('Firestore save quote: $e');
    }

    return newQuote;
  }

  /// Compatibilidade legado: registra diretamente
  Future<Uri?> createAndRegisterWhatsAppQuote({
    required Workshop workshop,
    required Vehicle? vehicle,
    required String serviceName,
    String? notes,
  }) async {
    await recordConfirmedQuote(
      workshop: workshop,
      vehicle: vehicle,
      serviceName: serviceName,
      notes: notes,
    );

    return buildWhatsAppUri(
      workshop: workshop,
      vehicle: vehicle,
      serviceName: serviceName,
      notes: notes,
    );
  }

  Future<void> addQuoteRequest({
    required String workshopId,
    required String workshopName,
    required String serviceName,
    required String estimatedPrice,
    required String vehicleName,
    String? notes,
    String? workshopPhone,
    String? workshopAddress,
    String? vehicleDetails,
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
      workshopPhone: workshopPhone,
      workshopAddress: workshopAddress,
      vehicleDetails: vehicleDetails,
    );

    _quotes = [newQuote, ..._quotes];
    await _save();
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('quotes')
          .doc(newQuote.id)
          .set(newQuote.toJson());
    } catch (_) {}
  }

  Future<void> updateStatus(String quoteId, String newStatus) async {
    final index = _quotes.indexWhere((q) => q.id == quoteId);
    if (index != -1) {
      _quotes[index].status = newStatus;
      await _save();
      notifyListeners();

      try {
        await FirebaseFirestore.instance
            .collection('quotes')
            .doc(quoteId)
            .update({'status': newStatus});
      } catch (_) {}
    }
  }

  Future<void> removeQuote(String quoteId) async {
    _quotes = _quotes.where((q) => q.id != quoteId).toList();
    await _save();
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('quotes')
          .doc(quoteId)
          .delete();
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _quotes.map((q) => jsonEncode(q.toJson())).toList();
    await prefs.setStringList(_quotesKey, jsonList);
  }
}
