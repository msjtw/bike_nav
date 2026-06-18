import 'dart:async';
import 'dart:math' as math;

import 'package:bike_nav/models/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class ActiveNavigationScreen extends ConsumerStatefulWidget {
  final RouteOption selectedRoute;

  const ActiveNavigationScreen({
    super.key,
    required this.selectedRoute,
  });

  @override
  ConsumerState<ActiveNavigationScreen> createState() =>
      _ActiveNavigationScreenState();
}

class _ActiveNavigationScreenState
    extends ConsumerState<ActiveNavigationScreen> {
  late final MapController controller;
  StreamSubscription<Position>? _positionStreamSub;
  int _nextPointIndex = 1;
  bool _isTracking = false;

  String _nextDirectionText = "Turn left onto Bike Path";
  String _distanceRemaining = "250 m";
  IconData _directionIcon = Icons.turn_left;

  @override
  void initState() {
    super.initState();
    controller = MapController.cyclOSMLayer(
      initPosition: widget.selectedRoute.points.first,
    );
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _updateRouteProgress(GeoPoint currentLocation) {
    final routePoints = widget.selectedRoute.points;
    while (_nextPointIndex < routePoints.length) {
      final target = routePoints[_nextPointIndex];
      final distanceToTarget = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        target.latitude,
        target.longitude,
      );

      if (distanceToTarget < 20) {
        _nextPointIndex++;
      } else {
        break;
      }
    }
  }

  double _calculateBearing(GeoPoint from, GeoPoint to) {
    final fromLat = _degreesToRadians(from.latitude);
    final fromLon = _degreesToRadians(from.longitude);
    final toLat = _degreesToRadians(to.latitude);
    final toLon = _degreesToRadians(to.longitude);
    final dLon = toLon - fromLon;

    final y = math.sin(dLon) * math.cos(toLat);
    final x = math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  double _radiansToDegrees(double radians) => radians * 180 / math.pi;

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_handleLocationUpdate);
  }

  Future<void> _handleLocationUpdate(Position position) async {
    final currentLocation = GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    _updateRouteProgress(currentLocation);

    if (_nextPointIndex >= widget.selectedRoute.points.length) {
      if (mounted) {
        setState(() {
          _nextDirectionText = 'Arrived at destination';
          _distanceRemaining = '0 m';
          _directionIcon = Icons.check;
        });
      }
      return;
    }

    final targetPoint = widget.selectedRoute.points[_nextPointIndex];
    final bearing = _calculateBearing(currentLocation, targetPoint);
    final remainingDistance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      targetPoint.latitude,
      targetPoint.longitude,
    );

    try {
      await controller.rotateMapCamera(bearing);
      await controller.moveTo(currentLocation, animate: false);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _distanceRemaining = '${remainingDistance.toStringAsFixed(0)} m';
        _nextDirectionText = 'Head toward next route point';
        _directionIcon = Icons.navigation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigating: ${widget.selectedRoute.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            OSMFlutter(
              controller: controller,
              onMapIsReady: (isReady) async {
                if (!isReady) return;

                // Draw the selected route line
                await controller.drawRoadManually(
                  widget.selectedRoute.points,
                  const RoadOption(
                    roadColor: Colors.blue,
                    roadWidth: 12,
                  ),
                );

                await controller.moveTo(widget.selectedRoute.points.first);

                if (!_isTracking) {
                  _isTracking = true;
                  await _startLocationTracking();
                }

                await controller.currentLocation();
              },
              osmOption: const OSMOption(
                userTrackingOption: UserTrackingOption(
                  enableTracking: true,
                  unFollowUser: false,
                ),
                showDefaultInfoWindow: false,
                showContributorBadgeForOSM: false,
                zoomOption: ZoomOption(
                  initZoom: 18, // Tight zoom for navigation clarity
                  minZoomLevel: 12,
                  maxZoomLevel: 19,
                ),
                roadConfiguration: RoadOption(
                  roadColor: Colors.transparent,
                ),
              ),
            ),

            // Positioned(
            //   top: 16,
            //   left: 16,
            //   right: 16,
            //   child: Card(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //     elevation: 8,
            //     color: Colors.green.shade700, // Standard navigation green
            //     child: Padding(
            //       padding: const EdgeInsets.all(16.0),
            //       child: Row(
            //         children: [
            //           // Direction Arrow Visual Indicator
            //           CircleAvatar(
            //             backgroundColor: Colors.white.withOpacity(0.2),
            //             radius: 24,
            //             child: Icon(
            //               _directionIcon,
            //               color: Colors.white,
            //               size: 28,
            //             ),
            //           ),
            //           const SizedBox(width: 16),
            //           // Text Instruction Content
            //           Expanded(
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 Text(
            //                   _nextDirectionText,
            //                   style: const TextStyle(
            //                     color: Colors.white,
            //                     fontWeight: FontWeight.bold,
            //                     fontSize: 18,
            //                   ),
            //                 ),
            //                 const SizedBox(height: 4),
            //                 Text(
            //                   'In $_distanceRemaining',
            //                   style: TextStyle(
            //                     color: Colors.white.withOpacity(0.85),
            //                     fontWeight: FontWeight.w500,
            //                     fontSize: 14,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.navigation, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.selectedRoute.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
