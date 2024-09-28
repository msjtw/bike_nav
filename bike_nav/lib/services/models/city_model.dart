import 'package:flutter/material.dart';

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
