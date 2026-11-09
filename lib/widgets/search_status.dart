import 'package:flutter/material.dart';

/// Estado compacto da busca: mantém a cobertura visível sem bloquear a lista.
class SearchStatus extends StatelessWidget {
  const SearchStatus(
      {required this.label,
      required this.message,
      required this.busy,
      required this.onRefresh,
      super.key});
  final String label, message;
  final bool busy;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(children: [
          if (busy)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(Icons.info_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
              child: Tooltip(
                  message: message,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)))),
          if (!busy)
            TextButton(onPressed: onRefresh, child: const Text('Atualizar')),
        ]),
      ));
}
