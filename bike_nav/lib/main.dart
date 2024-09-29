import 'package:bike_nav/providers/city_provider.dart';
import 'package:bike_nav/providers/tracking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'services/navigation_prompt.dart';
import 'test_route.dart';

void main() {
  runApp(
    // To install Riverpod, we need to add this widget above everything else.
    // This should not be inside "MyApp" but as direct parameter to "runApp".
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final searchControler = TextEditingController();
  MapController controller = MapController(
    initPosition: GeoPoint(latitude: 52.4, longitude: 17),
  );

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    controller.dispose();
    searchControler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchControler,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () async {
              ref.read(cityProvider.notifier).setCity(searchControler.text);
              await controller.moveTo(
                  GeoPoint(
                      latitude: ref.read(cityProvider).lat,
                      longitude: ref.read(cityProvider).lon),
                  animate: true);
            },
          ),
        ],
      ),
      floatingActionButton: Wrap(
        direction: Axis.vertical,
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
                child: const Icon(Icons.navigation),
                onPressed: () async {
                  await newNav(context);
                  controller.drawRoadManually(
                      waypointList,
                      const RoadOption(
                          roadColor: Colors.blue,
                          roadWidth: 15,
                          zoomInto: true));
                }),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: Builder(
              builder: (BuildContext context) {
                if (ref.watch(trackingProvider) == 1) {
                  return FloatingActionButton(
                      child: const Icon(Icons.location_on),
                      onPressed: () async {
                        await controller.startLocationUpdating();
                        await controller.setZoom(zoomLevel: 14);
                        ref.read(trackingProvider.notifier).toggle();
                      });
                } else {
                  return FloatingActionButton(
                      child: const Icon(Icons.location_off),
                      onPressed: () async {
                        await controller.stopLocationUpdating();
                        await controller.setZoom(zoomLevel: 17);
                        ref.read(trackingProvider.notifier).toggle();
                      });
                }
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: OSMFlutter(
          controller: controller,
          osmOption: OSMOption(
            userTrackingOption: const UserTrackingOption(
              enableTracking: true,
              unFollowUser: false,
            ),
            userLocationMarker: UserLocationMaker(
              personMarker: const MarkerIcon(
                icon: Icon(
                  Icons.location_history_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              directionArrowMarker: const MarkerIcon(
                icon: Icon(
                  Icons.assistant_navigation,
                  size: 48,
                ),
              ),
            ),
            zoomOption: const ZoomOption(
              initZoom: 10,
              minZoomLevel: 2,
              maxZoomLevel: 19,
              stepZoom: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
