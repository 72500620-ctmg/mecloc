import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppNoticeTone { info, warning, error, success }

class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.title,
    required this.message,
    this.tone = AppNoticeTone.info,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final AppNoticeTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (color, icon) = switch (tone) {
      AppNoticeTone.info => (colors.primary, Icons.info_outline_rounded),
      AppNoticeTone.warning => (colors.tertiary, Icons.warning_amber_rounded),
      AppNoticeTone.error => (colors.error, Icons.error_outline_rounded),
      AppNoticeTone.success => (colors.primary, Icons.check_circle_outline),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          TextStyle(fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 3),
                  Text(message),
                  if (action != null) ...[
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: action!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
