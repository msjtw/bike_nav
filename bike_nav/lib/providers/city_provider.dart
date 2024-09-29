import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/models/city_model.dart';
import 'package:geocoding/geocoding.dart';

class CityNotifier extends Notifier<City> {
  @override
  City build() {
    return const City(name: "", lon: 0, lat: 0);
  }

  void setCity(String name) async {
    final locations = await locationFromAddress(name);

    state = City(
        name: name, lon: locations[0].longitude, lat: locations[0].latitude);
  }
}

// Finally, we are using NotifierProvider to allow the UI to interact with
// our CitysNotifier class.
final cityProvider = NotifierProvider<CityNotifier, City>(() {
  return CityNotifier();
});
