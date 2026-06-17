import 'package:bike_nav/ActiveNavigationScreen.dart';
import 'package:bike_nav/models/city_model.dart';
import 'package:bike_nav/models/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapScreen extends ConsumerStatefulWidget {
  final List<String> waypoints;

  const MapScreen({
    super.key,
    required this.waypoints,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController controller;
  List<RouteOption> routes = [];
  int selectedRouteIndex = 0;
  bool loadingRoutes = false;

  @override
  void initState() {
    super.initState();
    final city = ref.read(locationProvider);
    controller = MapController.cyclOSMLayer(
      initPosition: GeoPoint(latitude: city.lat, longitude: city.lon),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void addMarkersOnce() {
    final city = ref.read(locationProvider);
    controller.addMarker(
      GeoPoint(latitude: city.lat, longitude: city.lon),
      markerIcon: const MarkerIcon(
        icon: Icon(Icons.location_city, color: Colors.red, size: 50),
      ),
    );
  }

  // Formatting helpers for OSRM data
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  Widget getLabel(int index) {
    if (index == 0 || index == widget.waypoints.length - 1) {
      return ListTile(
        leading: const Icon(Icons.agriculture_sharp),
        visualDensity: const VisualDensity(vertical: -4),
        title: Text(
          widget.waypoints[index],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      visualDensity: const VisualDensity(vertical: -4),
      leading: const Icon(Icons.more_vert),
      title: Text(widget.waypoints[index]),
    );
  }

  Future<void> _drawSelectedRoute() async {
    if (routes.isEmpty) return;
    final route = routes[selectedRouteIndex];
    await controller.clearAllRoads();
    await controller.drawRoadManually(
      route.points,
      const RoadOption(
        roadColor: Colors.red,
        roadWidth: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = routes.isNotEmpty ? routes[selectedRouteIndex] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Route Result')),
      // The FAB appears dynamically once a route option is ready
      floatingActionButton: routes.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveNavigationScreen(
                      selectedRoute: routes[selectedRouteIndex],
                    ),
                  ),
                );
              },
              label: const Text('Start Route'),
              icon: const Icon(Icons.navigation),
              backgroundColor: Colors.blue,
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext cntx, BoxConstraints constraints) {
            return Column(
              children: [
                LimitedBox(
                  maxHeight: constraints.maxHeight / 3,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.waypoints.length,
                    itemBuilder: (BuildContext cntx, int index) {
                      return getLabel(index);
                    },
                  ),
                ),
                if (routes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 40, // Reduced from 50 to make it sleeker
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: routes.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (context, index) {
                          final isSelected = index == selectedRouteIndex;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(routes[index].name),
                              selected: isSelected,
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                              selectedColor: Colors.blue,
                              backgroundColor: Colors.grey[200],
                              checkmarkColor: Colors
                                  .white, // Shows a subtle checkmark when selected
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide
                                  .none, // Removes the default border line
                              elevation: isSelected ? 2 : 0,
                              onSelected: (bool selected) async {
                                if (selected) {
                                  setState(() {
                                    selectedRouteIndex = index;
                                  });
                                  await _drawSelectedRoute();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Route Information Panel
                if (currentRoute != null)
                  Card(
                    margin: const EdgeInsets.all(12),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_bike,
                                  color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                _formatDistance(currentRoute.distance),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(currentRoute.duration),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                Expanded(
                  child: OSMFlutter(
                    controller: controller,
                    onMapIsReady: (isReady) async {
                      if (!isReady) return;
                      final city = ref.read(locationProvider);
                      addMarkersOnce();

                      GeoPoint centerMap =
                          GeoPoint(latitude: city.lat, longitude: city.lon);
                      await controller.moveTo(centerMap);

                      setState(() {
                        loadingRoutes = true;
                      });

                      final fetchedRoutes = await RouteService.fetchRoute(
                        waypoints: widget.waypoints,
                        city: city,
                      );

                      setState(() {
                        routes = fetchedRoutes;
                        loadingRoutes = false;
                        selectedRouteIndex = 0;
                      });

                      await _drawSelectedRoute();
                    },
                    osmOption: const OSMOption(
                      userTrackingOption: UserTrackingOption(
                        enableTracking: false,
                        unFollowUser: false,
                      ),
                      showDefaultInfoWindow: false,
                      showContributorBadgeForOSM: false,
                      zoomOption: ZoomOption(
                        initZoom: 14,
                        minZoomLevel: 10,
                        maxZoomLevel: 19,
                        stepZoom: 1.0,
                      ),
                      roadConfiguration: RoadOption(
                        roadColor: Colors.yellowAccent,
                        roadWidth: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
