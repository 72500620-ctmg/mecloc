import 'dart:collection';
import 'workshop.dart';

/// Metadados pertencem à resposta, evitando misturar buscas concorrentes.
class WorkshopSearchResult extends ListBase<Workshop> {
  WorkshopSearchResult(Iterable<Workshop> items,
      {this.isComplete = true,
      this.isStale = false,
      this.fromCache = false,
      this.fetchedAt})
      : _items = List.unmodifiable(items);

  final List<Workshop> _items;
  final bool isComplete;
  final bool isStale;
  final bool fromCache;
  final DateTime? fetchedAt;
  String? get notice => isStale
      ? 'Exibindo dados salvos. A atualização desta área está indisponível.'
      : isComplete
          ? null
          : 'Cobertura limitada: alguns estabelecimentos podem não aparecer.';

  @override
  int get length => _items.length;
  @override
  set length(int value) => throw UnsupportedError('Resultado imutável');
  @override
  Workshop operator [](int index) => _items[index];
  @override
  void operator []=(int index, Workshop value) =>
      throw UnsupportedError('Resultado imutável');
}
