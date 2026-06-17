import 'dart:convert';

import 'package:bike_nav/models/city_model.dart';
import 'package:bike_nav/models/geocode.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:http/http.dart' as http;

class LatLngPoint {
  final double lat;
  final double lon;

  const LatLngPoint(this.lat, this.lon);
}

class RouteOption {
  final String name;
  final List<GeoPoint> points;
  final double distance; // In meters
  final double duration; // In seconds

  const RouteOption({
    required this.name,
    required this.points,
    required this.distance,
    required this.duration,
  });
}

class RouteService {
  static Future<List<RouteOption>> fetchRoute({
    required List<String> waypoints,
    required City city,
  }) async {
    final geoPoints = await geocodeWaypoints(waypoints, city);

    final coords = geoPoints.map((p) => '${p.lon},${p.lat}').join(';');
    final url = 'http://192.168.1.102:5000/route/v1/bike/$coords'
        '?steps=true&overview=full&geometries=geojson'
        '&alternatives=true';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);
    final routes = data['routes'] as List;

    final options = routes.asMap().entries.map((entry) {
      final index = entry.key;
      final route = entry.value;

      final coordinates = route['geometry']['coordinates'] as List;
      final points = coordinates.map<GeoPoint>((c) {
        return GeoPoint(latitude: c[1], longitude: c[0]);
      }).toList();

      final double distance = (route['distance'] as num).toDouble();
      final double duration = (route['duration'] as num).toDouble();

      return RouteOption(
        name: index == 0 ? 'Fast Route' : 'Alternative $index',
        points: points,
        distance: distance,
        duration: duration,
      );
    }).toList();

    return options;
  }
}
