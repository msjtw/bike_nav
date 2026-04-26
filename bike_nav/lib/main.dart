import 'package:bike_nav/providers/city_provider.dart';
import 'package:bike_nav/providers/nav_provider.dart';
import 'package:bike_nav/providers/tracking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'services/navigation_prompt.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChooseRoute(),
    );
  }
}

class ChooseRoute extends StatefulWidget {
  const ChooseRoute({super.key});

  @override
  State<ChooseRoute> createState() => _ChooseRouteState();
}

class _ChooseRouteState extends State<ChooseRoute> {
  final List<TextEditingController> controllers = [
    TextEditingController(), // From
    TextEditingController(), // To
  ];

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void addStop() {
    setState(() {
      // insert before last ("To")
      controllers.insert(
        controllers.length - 1,
        TextEditingController(),
      );
    });
  }

  void removeStop(int index) {
    if (index == 0 || index == controllers.length - 1) return;

    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);
    });
  }

  void _handleSearch() {
    final stops = controllers.map((c) => c.text).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          waypoints: stops,
        ),
      ),
    );
  }

  String getLabel(int index) {
    if (index == 0) return 'From';
    if (index == controllers.length - 1) return 'To';
    return 'Stop ${index}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addStop,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers[index],
                            decoration: InputDecoration(
                              labelText: getLabel(index),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (index != 0 && index != controllers.length - 1)
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => removeStop(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSearch,
                  child: const Text("Search Route"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final List<String> waypoints;

  const ResultScreen({
    super.key,
    required this.waypoints,
  });

  Widget getLabel(int index) {
    if (index == 0 || index == waypoints.length - 1) {
      return ListTile(
        leading: Icon(Icons.agriculture_sharp),
        visualDensity: const VisualDensity(vertical: -4),
        title: Text(
            style: TextStyle(fontWeight: FontWeight.bold), waypoints[index]),
      );
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      visualDensity: const VisualDensity(vertical: -4),
      leading: Icon(Icons.more_vert),
      title: Text(waypoints[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Result')),
      body: Center(
          child: ListView.builder(
              itemCount: waypoints.length,
              itemBuilder: (BuildContext cntx, int index) {
                return getLabel(index);
              })),
    );
  }
}
