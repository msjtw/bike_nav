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
    print(start);
    print(end);
    var tmp = Uri.http('10.0.2.2:8000', '/path/', {
      "city": ref.read(cityProvider).name,
      "start": start,
      "end": end,
    });
    final response = await http.get(tmp);

    final List<GeoPoint> wayPoints = (jsonDecode(response.body)['path'] as List)
        .map((data) => GeoPoint(
            latitude: (data[1] as num)
                .toDouble(), // Ensure the value is cast to double
            longitude: (data[0] as num)
                .toDouble() // Ensure the value is cast to double
            ))
        .toList();
    state = Navigation(start: start, end: end, wayPoints: wayPoints);
  }
}

// Finally, we are using NotifierProvider to allow the UI to interact with
// our NavsNotifier class.
final navProvider = NotifierProvider<NavNotifier, Navigation>(() {
  return NavNotifier();
});
