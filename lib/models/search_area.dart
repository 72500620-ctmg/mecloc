import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

typedef SearchBounds = ({double south, double west, double north, double east});

class SearchArea {
  const SearchArea(this.center, {this.radius = 8000, this.bounds});
  final LatLng center;
  final int radius;
  final SearchBounds? bounds;
  String get key => bounds == null ? '$center:$radius' : 'box:$bounds';
  static const _distance = Distance(roundResult: false);

  bool contains(double lat, double lon) {
    final b = bounds;
    if (b != null) {
      return lat >= b.south && lat <= b.north && lon >= b.west && lon <= b.east;
    }
    return _distance(center, LatLng(lat, lon)) <= radius;
  }

  SearchBounds get envelope {
    final lat = radius / 111320;
    final lon = lat / math.max(0.01, math.cos(center.latitude * math.pi / 180));
    return bounds ??
        (
          south: center.latitude - lat,
          north: center.latitude + lat,
          west: center.longitude - lon,
          east: center.longitude + lon
        );
  }

  bool covers(SearchArea other) {
    if (bounds == null && other.bounds == null) {
      return _distance(center, other.center) + other.radius <= radius + 0.01;
    }
    final b = other.envelope;
    return contains(b.south, b.west) &&
        contains(b.south, b.east) &&
        contains(b.north, b.west) &&
        contains(b.north, b.east);
  }

  SearchArea padded() {
    final b = bounds;
    if (b == null) return this;
    final dy = (b.north - b.south) * 0.2, dx = (b.east - b.west) * 0.2;
    final expanded = (
      south: math.max(-90.0, b.south - dy),
      north: math.min(90.0, b.north + dy),
      west: math.max(-180.0, b.west - dx),
      east: math.min(180.0, b.east + dx)
    );
    if (_distance(LatLng(expanded.south, expanded.west),
            LatLng(expanded.north, expanded.east)) >
        80000) {
      return this;
    }
    return SearchArea(center, radius: radius, bounds: expanded);
  }

  Map<String, dynamic> toJson() => {
        'lat': center.latitude,
        'lon': center.longitude,
        'radius': radius,
        if (bounds != null)
          'bounds': [bounds!.south, bounds!.west, bounds!.north, bounds!.east]
      };
  factory SearchArea.fromJson(Map<String, dynamic> json) {
    final b = json['bounds'] as List<dynamic>?;
    return SearchArea(
        LatLng(
            (json['lat'] as num).toDouble(), (json['lon'] as num).toDouble()),
        radius: json['radius'] as int,
        bounds: b == null
            ? null
            : (
                south: (b[0] as num).toDouble(),
                west: (b[1] as num).toDouble(),
                north: (b[2] as num).toDouble(),
                east: (b[3] as num).toDouble()
              ));
  }
}
