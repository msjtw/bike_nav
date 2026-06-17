import 'package:bike_nav/models/city_model.dart';
import 'package:geocoding/geocoding.dart';

class Point {
  final double lat;
  final double lon;

  const Point({
    required this.lat,
    required this.lon,
  });
}

Future<List<Point>> geocodeWaypoints(
  List<String> addresses,
  City city,
) async {
  final points = <Point>[];

  for (final address in addresses) {
    final fullQuery = '$address, ${city.name}';

    final results = await locationFromAddress(fullQuery);

    if (results.isEmpty) {
      throw Exception('Could not geocode: $fullQuery');
    }

    final loc = results.first;

    points.add(
      Point(
        lat: loc.latitude,
        lon: loc.longitude,
      ),
    );
  }

  return points;
}
