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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      liveRegion: true,
      child: Material(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.slateBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cobaltPrimary,
                  ),
                )
              else
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDark ? Colors.amber.shade300 : AppColors.amberGold,
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
                      color: isDark ? Colors.white : AppColors.slateInk,
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Atualizar',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cobaltPrimary,
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
