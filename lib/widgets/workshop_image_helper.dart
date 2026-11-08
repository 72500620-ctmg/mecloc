import 'dart:convert';
import 'package:flutter/material.dart';

/// Helper de renderização que suporta de forma transparente:
/// 1. Data URI Base64 ("data:image/jpeg;base64,...")
/// 2. Raw Base64 string pura
/// 3. URLs remotas (HTTP / HTTPS)
class WorkshopImageHelper {
  static bool isBase64(String? source) {
    if (source == null || source.isEmpty) return false;
    final trimmed = source.trim();
    return trimmed.startsWith('data:image/') ||
        (trimmed.length > 100 && !trimmed.startsWith('http://') && !trimmed.startsWith('https://'));
  }

  static Widget buildImage({
    required String? imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
  }) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    final trimmed = imageUrl.trim();
    Widget imageWidget;

    if (isBase64(trimmed)) {
      try {
        String base64Data = trimmed;
        if (trimmed.contains(',')) {
          base64Data = trimmed.split(',').last;
        }
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
        );
      } catch (_) {
        imageWidget = placeholder ?? const SizedBox.shrink();
      }
    } else {
      imageWidget = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }
    return imageWidget;
  }
}

