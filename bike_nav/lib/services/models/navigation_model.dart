import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

// An immutable state is preferred.
// We could also use packages like Freezed to help with the implementation.
@immutable
class Navigation {
  // Since Todo is immutable, we implement a method that allows cloning the
  // Todo with slightly different content.

  final String start;
  final String end;
  final int type;
  final List<GeoPoint> wayPoints;

  const Navigation(
      {required this.start,
      required this.end,
      required this.wayPoints,
      int? type})
      : type = type ?? 0;
}
