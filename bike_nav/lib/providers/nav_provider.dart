import 'dart:convert';

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
    final response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));
    final wayPoints = jsonDecode(response.body)['path']
        .map((data) => GeoPoint(latitude: data[0], longitude: data[1]))
        .toList();
    state = Navigation(start: start, end: end, wayPoints: wayPoints);
  }
}

// Finally, we are using NotifierProvider to allow the UI to interact with
// our NavsNotifier class.
final navProvider = NotifierProvider<NavNotifier, Navigation>(() {
  return NavNotifier();
});
