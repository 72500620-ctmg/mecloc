import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Estado compacto da busca exibido flutuando sobre o mapa, próximo ao container principal.
class SearchStatus extends StatelessWidget {
  const SearchStatus({
    required this.label,
    required this.message,
    required this.busy,
    required this.onRefresh,
    super.key,
  });

  final String label;
  final String message;
  final bool busy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: Material(
        elevation: 4,
        shadowColor: colors.shadow.withValues(alpha: 0.16),
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              else
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: context.customColors.warning,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Tooltip(
                  message: message,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (!busy) ...[
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onRefresh,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      'Atualizar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
