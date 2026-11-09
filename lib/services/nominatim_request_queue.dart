import 'dart:async';

/// Compartilha o limite entre geocodificação e buscas textuais do mesmo app.
/// O tráfego agregado de vários usuários requer um proxy com limite próprio.
class NominatimRequestQueue {
  static Future<void> _tail = Future.value();
  static DateTime? _lastStart;

  static Future<T> run<T>(Future<T> Function() request) async {
    final previous = _tail;
    final finished = Completer<void>();
    _tail = finished.future;
    await previous;
    try {
      final last = _lastStart;
      if (last != null) {
        final remaining =
            const Duration(seconds: 1) - DateTime.now().difference(last);
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      _lastStart = DateTime.now();
      return await request();
    } finally {
      finished.complete();
    }
  }
}
