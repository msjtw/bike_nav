import 'dart:convert';

import 'package:bike_nav/providers/city_provider.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/models/navigation_model.dart';
import 'package:http/http.dart' as http;

class NavNotifier extends Notifier<Navigation> {
  @override
  Navigation build() {
    return const Navigation(start: "", end: " ", wayPoints: []);
  }

  void setNav(String start, String end) async {
    try {
      print("setNav start");

      final uri = Uri(
        scheme: 'http',
        host: '192.168.1.102',
        port: 5000,
        path: '/path/',
        queryParameters: {
          "city": ref.read(cityProvider).name,
          "start": start,
          "end": end,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      print(response.body);

      final List<GeoPoint> wayPoints =
          (jsonDecode(response.body)['path'] as List)
              .map((data) => GeoPoint(
                    latitude: (data[1] as num).toDouble(),
                    longitude: (data[0] as num).toDouble(),
                  ))
              .toList();

      state = Navigation(start: start, end: end, wayPoints: wayPoints);
    } catch (e) {
      print("setNav error: $e");
    }
  }
}

// Finally, we are using NotifierProvider to allow the UI to interact with
// our NavsNotifier class.
final navProvider = NotifierProvider<NavNotifier, Navigation>(() {
  return NavNotifier();
});
