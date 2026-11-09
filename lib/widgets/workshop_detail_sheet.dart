import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../screens/workshop_registration_screen.dart';
import '../theme/app_theme.dart';
import 'whatsapp_quote_modal.dart';
import 'workshop_image_helper.dart';

/// Modal Bottom Sheet moderno, arrastável e com cantos arredondados
/// para visualização completa e interação com uma oficina mecânica.
class WorkshopDetailSheet extends StatefulWidget {
  const WorkshopDetailSheet({super.key, required this.workshop});

  final Workshop workshop;

  static Future<void> show(BuildContext context, Workshop workshop) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => WorkshopDetailSheet(workshop: workshop),
    );
  }

  @override
  State<WorkshopDetailSheet> createState() => _WorkshopDetailSheetState();
}

class _WorkshopDetailSheetState extends State<WorkshopDetailSheet> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsSectionKey = GlobalKey();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(Uri uri) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir esta ação no dispositivo.')),
      );
    }
  }

  void _scrollToReviews() {
    final ctx = _reviewsSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAddReviewModal(BuildContext context, Workshop w) {
    final auth = context.read<AuthProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    final activeVehicle = vehicleProvider.activeVehicle;

    double rating = 5.0;
    final commentController = TextEditingController();
    String carModel = activeVehicle != null
        ? '${activeVehicle.brand} ${activeVehicle.model} ${activeVehicle.year}'
        : '';
    final nameController = TextEditingController(
      text: auth.user?.displayName?.trim().isNotEmpty == true
          ? auth.user!.displayName!
          : (auth.isAuthenticated ? 'Motorista MecLoc' : ''),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.rate_review_rounded, color: AppColors.forest, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Avaliar ${w.name}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Compartilhe sua experiência real para orientar outros motoristas.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 20),

                      // Estrelas Interativas
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                final starVal = index + 1;
                                return IconButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  iconSize: 36,
                                  onPressed: () {
                                    setModalState(() => rating = starVal.toDouble());
                                  },
                                  icon: Icon(
                                    starVal <= rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: starVal <= rating
                                        ? AppColors.amberGold
                                        : (isDark ? Colors.white24 : Colors.black26),
                                  ),
                                );
                              }),
                            ),
                            Text(
                              switch (rating.toInt()) {
                                5 => 'Excelente atendimento! ★★★★★',
                                4 => 'Muito bom atendimento ★★★★☆',
                                3 => 'Atendimento regular ★★★☆☆',
                                2 => 'Deixou a desejar ★★☆☆☆',
                                _ => 'Experiência ruim ★☆☆☆☆',
                              },
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amberGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nome do Avaliador
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Seu nome ou apelido',
                          hintText: 'Ex: Carlos Silva',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkLine : AppColors.line,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Veículo utilizado
                      TextField(
                        controller: TextEditingController(text: carModel),
                        onChanged: (val) => carModel = val,
                        decoration: InputDecoration(
                          labelText: 'Veículo atendido',
                          hintText: 'Ex: VW Polo TSI, Corolla 2.0',
                          prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkLine : AppColors.line,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Comentário
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'O que achou do serviço?',
                          hintText: 'Ex: Serviço rápido, honesto no orçamento e peças originais.',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkLine : AppColors.line,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final author = nameController.text.trim().isNotEmpty
                              ? nameController.text.trim()
                              : 'Motorista MecLoc';
                          final comment = commentController.text.trim().isNotEmpty
                              ? commentController.text.trim()
                              : 'Excelente serviço e pontualidade!';

                          final now = DateTime.now();
                          final dateStr =
                              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

                          final review = WorkshopReview(
                            authorName: author,
                            rating: rating,
                            comment: comment,
                            date: dateStr,
                            carModel: carModel.trim().isNotEmpty ? carModel.trim() : null,
                            authorId: auth.user?.uid,
                          );

                          await sheetCtx.read<WorkshopProvider>().addReview(
                                workshopId: w.id,
                                review: review,
                              );

                          if (sheetCtx.mounted) {
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Avaliação publicada com sucesso! Obrigado pelo feedback.'),
                                backgroundColor: AppColors.forest,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Publicar Avaliação',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFullScreenGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) {
          int active = initialIndex;
          final pageCtrl = PageController(initialPage: initialIndex);

          return StatefulBuilder(
            builder: (ctx, setGalleryState) {
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text(
                    'Foto ${active + 1} de ${images.length}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  centerTitle: true,
                ),
                body: PageView.builder(
                  controller: pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) => setGalleryState(() => active = i),
                  itemBuilder: (_, index) {
                    return InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: Center(
                        child: WorkshopImageHelper.buildImage(
                          imageUrl: images[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Resolve a oficina atualizada com dados de reviews e customizações
    final w = provider.customWorkshops.firstWhere(
      (c) =>
          c.id == widget.workshop.id ||
          c.name.toLowerCase().trim() == widget.workshop.name.toLowerCase().trim(),
      orElse: () {
        final osmMatch = provider.workshops
            .where((item) => item.id == widget.workshop.id)
            .firstOrNull;
        return osmMatch ?? widget.workshop;
      },
    );

    final saved = provider.isFavorite(w.id);
    final isRegistered = w.isCustomRegistered;
    final currentUserId = authProvider.user?.uid;
    final isOwner = isRegistered &&
        currentUserId != null &&
        w.ownerId != null &&
        w.ownerId == currentUserId;

    final allImages = w.allImageUrls;
    final hasImages = allImages.isNotEmpty;
    final reviews = provider.getReviewsForWorkshop(w.id).isNotEmpty
        ? provider.getReviewsForWorkshop(w.id)
        : w.reviews;

    return DraggableScrollableSheet(
      initialChildSize: 0.90, // Abre quase no topo da tela
      minChildSize: 0.45,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Column(
              children: [
                // Barra de arrasto (Drag handle)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 6),
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),

                // Conteúdo rolável sincronizado com o drag do sheet
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // 1. CARROSSEL DE FOTOS OU CONTAINER VAZIO COM MESMO TAMANHO
                      SizedBox(
                        height: 230,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            if (hasImages)
                              PageView.builder(
                                controller: _pageController,
                                itemCount: allImages.length,
                                onPageChanged: (idx) {
                                  setState(() => _currentPhotoIndex = idx);
                                },
                                itemBuilder: (ctx, idx) {
                                  return GestureDetector(
                                    onTap: () => _showFullScreenGallery(
                                      context,
                                      allImages,
                                      idx,
                                    ),
                                    child: WorkshopImageHelper.buildImage(
                                      imageUrl: allImages[idx],
                                      width: double.infinity,
                                      height: 230,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              )
                            else
                              // Container placeholder de mesmo tamanho com ícone de ausência de foto
                              Container(
                                width: double.infinity,
                                height: 230,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isDark
                                        ? const [Color(0xFF232B30), Color(0xFF171D21)]
                                        : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.no_photography_outlined,
                                        size: 28,
                                        color: isDark ? Colors.white54 : AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Nenhuma foto adicionada ainda',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white70 : AppColors.slateInk,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Fotos do estabelecimento podem ser cadastradas pelo proprietário',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white38 : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Contador de fotos estilo OLX/Mercado Livre no canto inferior direito
                            if (hasImages)
                              Positioned(
                                bottom: 12,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_currentPhotoIndex + 1}/${allImages.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Botão Fechar flutuante (Superior Esquerdo)
                            Positioned(
                              top: 10,
                              left: 14,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Botões Flutuantes (Superior Direito: Favorito e Editar)
                            Positioned(
                              top: 10,
                              right: 14,
                              child: Row(
                                children: [
                                  if (isOwner) ...[
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => WorkshopRegistrationScreen(
                                                workshopToEdit: w,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.45),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => provider.toggleFavorite(w.id, w),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: saved ? Colors.redAccent : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. CORPO PRINCIPAL COM CONTEÚDO ORGANIZADO
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges de Categoria e Parceria
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: w.categoryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(w.iconData, size: 14, color: w.categoryColor),
                                      const SizedBox(width: 5),
                                      Text(
                                        w.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: w.categoryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isRegistered)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF107C41).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF107C41)),
                                        SizedBox(width: 5),
                                        Text(
                                          'OFICINA PARCEIRA',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF107C41),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.public_rounded, size: 14, color: AppColors.muted),
                                        SizedBox(width: 5),
                                        Text(
                                          'MAPA PÚBLICO',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Nome da Oficina
                            Text(
                              w.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Linha de Avaliação e Distância (Bug corrigido com casas decimais)
                            InkWell(
                              onTap: _scrollToReviews,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 18, color: AppColors.amberGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    w.rating != null
                                        ? w.rating!.toStringAsFixed(1)
                                        : 'Novo',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.amberGold,
                                    ),
                                  ),
                                  Text(
                                    ' (${reviews.length > (w.ratingCount ?? 0) ? reviews.length : (w.ratingCount ?? 0)} ${reviews.length == 1 ? 'avaliação' : 'avaliações'})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  if (w.distanceKm != null) ...[
                                    const Text('  •  ', style: TextStyle(color: AppColors.muted)),
                                    const Icon(Icons.near_me_rounded, size: 14, color: AppColors.forest),
                                    const SizedBox(width: 3),
                                    Text(
                                      w.formattedDistance,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // BARRA DE AÇÕES RÁPIDAS (Quick Actions limpas e intuitivas)
                            Row(
                              children: [
                                // Rota GPS
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context: context,
                                    icon: Icons.directions_car_rounded,
                                    label: 'Traçar Rota',
                                    color: AppColors.forest,
                                    onTap: () {
                                      final url = w.googleMapsDirectionsUrl ?? w.googleMapsUrl;
                                      _openUrl(Uri.parse(url));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // WhatsApp ou Ligar
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context: context,
                                    icon: Icons.chat_bubble_rounded,
                                    label: isRegistered ? 'WhatsApp' : 'Contato',
                                    color: const Color(0xFF25D366),
                                    onTap: () {
                                      if (isRegistered) {
                                        WhatsAppQuoteModal.show(context, workshop: w);
                                      } else if (w.phone != null && w.phone!.trim().isNotEmpty) {
                                        _openUrl(Uri.parse('tel:${w.phone!.replaceAll(RegExp(r'\D'), '')}'));
                                      } else {
                                        _openUrl(Uri.parse(w.googleMapsUrl));
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Google Maps
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context: context,
                                    icon: Icons.map_rounded,
                                    label: 'Google Maps',
                                    color: const Color(0xFF1A73E8),
                                    onTap: () => _openUrl(Uri.parse(w.googleMapsUrl)),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Compartilhar / Copiar
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context: context,
                                    icon: Icons.share_rounded,
                                    label: 'Copiar',
                                    color: isDark ? Colors.white70 : AppColors.slateInk,
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                        text: '${w.name}\nEndereço: ${w.address}\nLocalização: ${w.googleMapsUrl}',
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Dados da oficina copiados para a área de transferência!'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // INFORMAÇÕES DETALHADAS (Cards limpos)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? AppColors.darkLine : AppColors.line,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Endereço
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.place_outlined, size: 20, color: AppColors.muted),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Endereço',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              w.address,
                                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.forest),
                                        tooltip: 'Copiar endereço',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: w.address));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Endereço copiado!'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Horário
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 20, color: AppColors.muted),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text(
                                                  'Horário de Atendimento',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: w.isOpenNow
                                                        ? Colors.green.withValues(alpha: 0.15)
                                                        : Colors.red.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    w.isOpenNow ? 'Aberto agora' : 'Fechado',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: w.isOpenNow ? Colors.green.shade700 : Colors.red.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              w.openingHours,
                                              style: const TextStyle(fontSize: 13, height: 1.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Telefone se verificado
                                  if (w.phone != null && w.phone!.trim().isNotEmpty) ...[
                                    const Divider(height: 24),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 20, color: AppColors.muted),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Telefone',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                w.phone!,
                                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Especialidades e Marcas (se existirem)
                            if (w.supportedBrands.isNotEmpty || w.specialties.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Especialidades & Marcas Atendidas',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ...w.supportedBrands.map((b) => Chip(
                                        avatar: const Icon(Icons.directions_car_rounded, size: 14),
                                        label: Text(b, style: const TextStyle(fontSize: 11.5)),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )),
                                  ...w.specialties.map((s) => Chip(
                                        avatar: const Icon(Icons.build_rounded, size: 14),
                                        label: Text(s, style: const TextStyle(fontSize: 11.5)),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )),
                                ],
                              ),
                            ],

                            // Descrição / Diferenciais
                            if (w.description != null && w.description!.trim().isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Sobre o Estabelecimento',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkLine : AppColors.line,
                                  ),
                                ),
                                child: Text(
                                  w.description!,
                                  style: const TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // 3. SEÇÃO DE AVALIAÇÕES E COMENTÁRIOS COM ESTRELAS
                            Container(
                              key: _reviewsSectionKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Avaliações da Oficina',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                      FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => _showAddReviewModal(context, w),
                                        icon: const Icon(Icons.star_outline_rounded, size: 16),
                                        label: const Text('Avaliar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Card Resumo de Avaliação
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkLine : AppColors.line,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              w.rating != null ? w.rating!.toStringAsFixed(1) : '5.0',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                            Row(
                                              children: List.generate(5, (index) {
                                                final filled = index < (w.rating ?? 5.0).round();
                                                return Icon(
                                                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                                  size: 16,
                                                  color: AppColors.amberGold,
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${reviews.length} ${reviews.length == 1 ? 'opinião' : 'opiniões'} no MecLoc',
                                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _openUrl(Uri.parse(w.googleMapsUrl)),
                                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                          label: const Text('Ver no Google', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Lista de Comentários
                                  if (reviews.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkLine : AppColors.line,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.chat_outlined, size: 28, color: isDark ? Colors.white30 : AppColors.muted),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Ainda não há comentários publicados.',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Já realizou algum serviço aqui? Seja o primeiro a avaliar!',
                                            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 10),
                                          TextButton.icon(
                                            onPressed: () => _showAddReviewModal(context, w),
                                            icon: const Icon(Icons.star_rounded, size: 16, color: AppColors.forest),
                                            label: const Text('Escrever primeira avaliação', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ...reviews.map((r) => _buildReviewCard(context, r, isDark)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 4. CARD DO PROPRIETÁRIO (Elegante e no rodapé, sem poluir a experiência)
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkLine : AppColors.line,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Você administra esta oficina',
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                          Text(
                                            'Personalize fotos, horários e WhatsApp a qualquer momento.',
                                            style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => WorkshopRegistrationScreen(
                                              workshopToEdit: w,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.forest),
                                      label: const Text('Editar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              )
                            else if (!isRegistered)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF132822) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFF107C41).withValues(alpha: 0.25)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.storefront_rounded, color: Color(0xFF107C41), size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'É o dono deste estabelecimento?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: Color(0xFF107C41),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Cadastre seu WhatsApp comercial gratuitamente para receber pedidos de orçamento direto pelo MecLoc e adicionar fotos reais da oficina.',
                                      style: TextStyle(fontSize: 12, height: 1.35),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.tonalIcon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF107C41),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 42),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => WorkshopRegistrationScreen(
                                              initialName: w.name,
                                              initialAddress: w.address,
                                              initialLatitude: w.latitude,
                                              initialLongitude: w.longitude,
                                              initialPhone: w.phone,
                                              initialCategory: w.categoryType,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add_business_rounded, size: 16),
                                      label: const Text(
                                        'Reivindicar / Cadastrar esta Oficina',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Registro bruto do OpenStreetMap (Discreto)
                            if (w.openStreetMapUrl != null) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _openUrl(Uri.parse(w.openStreetMapUrl!)),
                                  icon: const Icon(Icons.info_outline, size: 14),
                                  label: const Text(
                                    'Ver registro público no OpenStreetMap',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkLine : AppColors.line,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, WorkshopReview review, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkLine : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.forest.withValues(alpha: 0.15),
                child: Text(
                  review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Nome e Veículo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    if (review.carModel != null && review.carModel!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          const Icon(Icons.directions_car_rounded, size: 11, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              review.carModel!,
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Estrelas e Data
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 13,
                        color: AppColors.amberGold,
                      );
                    }),
                  ),
                  if (review.date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      review.date,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
