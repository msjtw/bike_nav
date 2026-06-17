import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

// An immutable state is preferred.
// We could also use packages like Freezed to help with the implementation.
@immutable
class City {
  // Since Todo is immutable, we implement a method that allows cloning the
  // Todo with slightly different content.

  final double lat;
  final double lon;
  final String name;

  const City({required this.name, required this.lat, required this.lon});
}

class LocationNotifier extends Notifier<City> {
  @override
  City build() {
    return const City(
      name: "Poznań",
      lat: 52.4064,
      lon: 16.9252,
    );
  }

  void setLocation(String name) async {
    final locations = await locationFromAddress(name);

    state = City(
        name: name, lon: locations[0].longitude, lat: locations[0].latitude);
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, City>(LocationNotifier.new);
