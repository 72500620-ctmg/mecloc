import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

class FloatingSearchBar extends StatefulWidget {
  const FloatingSearchBar({
    super.key,
    required this.onOpenFilterModal,
    required this.onOpenVehicleModal,
  });

  final VoidCallback onOpenFilterModal;
  final VoidCallback onOpenVehicleModal;

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  final List<String> _suggestedSearches = const [
    'Troca de óleo para Honda Civic',
    'Oficina especializada em Volkswagen',
    'Lava-jato com lavagem detalhada',
    'Mecânico especializado em câmbio automático',
    'Troca de pneus perto de mim',
    'Higienização de ar-condicionado',
    'Polimento técnico e vitrificação',
    'Alinhamento 3D e suspensão',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isExpanded = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    _controller.text = query;
    _focusNode.unfocus();
    setState(() => _isExpanded = false);
    final provider = context.read<WorkshopProvider>();
    provider.setSearchQuery(query);
    provider.addRecentSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workshopProvider = context.watch<WorkshopProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final activeVehicle = vehicleProvider.activeVehicle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiquidGlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.forest,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: activeVehicle != null
                            ? 'Buscar para seu ${activeVehicle.shortName}...'
                            : 'Buscar serviços, oficinas, marcas...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white54 : AppColors.muted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: (value) {
                        workshopProvider.setSearchQuery(value);
                      },
                      onSubmitted: _submitSearch,
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _controller.clear();
                        workshopProvider.setSearchQuery('');
                      },
                    ),
                  const SizedBox(width: 6),
                  // Botão de Filtro
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.onOpenFilterModal,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: workshopProvider.selectedCategory != null ||
                                workshopProvider.onlyCompatibleWithVehicle
                            ? AppColors.forest
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: workshopProvider.selectedCategory != null ||
                                workshopProvider.onlyCompatibleWithVehicle
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.ink),
                      ),
                    ),
                  ),
                ],
              ),

              // Chip do veículo ativo abaixo da barra
              if (activeVehicle != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onOpenVehicleModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 14,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              activeVehicle.displayName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: AppColors.forest,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (workshopProvider.onlyCompatibleWithVehicle)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9D58).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '100% Compatíveis',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F9D58),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Dropdown de Histórico e Sugestões quando expandido
        if (_isExpanded)
          LiquidGlassContainer(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  if (workshopProvider.recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PESQUISAS RECENTES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: workshopProvider.clearRecentSearches,
                            child: const Text(
                              'Limpar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...workshopProvider.recentSearches.map(
                      (item) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.history_rounded, size: 18),
                        title: Text(item, style: const TextStyle(fontSize: 13.5)),
                        onTap: () => _submitSearch(item),
                      ),
                    ),
                    const Divider(height: 12),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      'SUGESTÕES POPULARES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ..._suggestedSearches.map(
                    (item) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.trending_up_rounded, size: 18, color: AppColors.forest),
                      title: Text(item, style: const TextStyle(fontSize: 13.5)),
                      onTap: () => _submitSearch(item),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
