import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/search_area.dart';

class MapSearchPolicy {
  static const minimumZoom = 12.0;
  static const debounce = Duration(milliseconds: 1100);
  static bool shouldSearch(LatLng center, double zoom, SearchBounds bounds,
      {LatLng? previousCenter, double? previousZoom}) {
    if (zoom < minimumZoom) return false;
    if (previousCenter == null ||
        previousZoom == null ||
        (zoom - previousZoom).abs() >= 0.5) {
      return true;
    }
    const distance = Distance(roundResult: false);
    final width = distance(LatLng(center.latitude, bounds.west),
        LatLng(center.latitude, bounds.east));
    final height = distance(LatLng(bounds.south, center.longitude),
        LatLng(bounds.north, center.longitude));
    final threshold = (math.min(width, height) * 0.25).clamp(200.0, 1800.0);
    return distance(previousCenter, center) >= threshold;
  }
}
