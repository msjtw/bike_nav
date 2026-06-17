import 'package:bike_nav/map_screen.dart';
import 'package:bike_nav/models/city_model.dart';
import 'package:bike_nav/models/history_provider.dart';
import 'package:bike_nav/models/pocketbase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChooseRoute(),
    );
  }
}

class ChooseRoute extends ConsumerStatefulWidget {
  const ChooseRoute({super.key});

  @override
  ConsumerState<ChooseRoute> createState() => _ChooseRouteState();
}

class _ChooseRouteState extends ConsumerState<ChooseRoute> {
  final List<TextEditingController> controllers = [
    TextEditingController(), // From
    TextEditingController(), // To
  ];

  final List<FocusNode> focusNodes = [
    FocusNode(),
    FocusNode(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void addStop() {
    setState(() {
      controllers.insert(controllers.length - 1, TextEditingController());
      focusNodes.insert(focusNodes.length - 1, FocusNode());
    });
  }

  void removeStop(int index) {
    if (index == 0 || index == controllers.length - 1) return;

    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);

      focusNodes[index].dispose();
      focusNodes.removeAt(index);
    });
  }

  void _clearAllFocus() {
    FocusScope.of(context).unfocus();
    for (var node in focusNodes) {
      node.unfocus();
    }
  }

  void _resetInputFields() {
    _clearAllFocus();
    setState(() {
      // Keep only two main text boxes (From & To) and wipe their contents
      while (controllers.length > 2) {
        controllers[1].dispose();
        controllers.removeAt(1);
        focusNodes[1].dispose();
        focusNodes.removeAt(1);
      }
      for (var controller in controllers) {
        controller.clear();
      }
    });
  }

  void _handleSearch() {
    final stops = controllers.map((c) => c.text).toList();
    final nonEmpty = stops.where((s) => s.trim().isNotEmpty).toList();

    if (nonEmpty.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least two stops')),
      );
      return;
    }

    for (final stop in nonEmpty) {
      ref.read(searchHistoryProvider.notifier).saveSearch(stop);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(waypoints: nonEmpty),
      ),
    );
  }

  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authControllerProvider);

            ref.listen<AuthState>(authControllerProvider, (prev, next) {
              if (next.isAuthenticated) {
                ref.invalidate(searchHistoryProvider);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged in successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (next.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(next.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            });

            return AlertDialog(
              title: const Text('Login to Sync History'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      authState.isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          ref.read(authControllerProvider.notifier).login(
                                emailController.text,
                                passwordController.text,
                              );
                        },
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String getLabel(int index) {
    if (index == 0) return 'From';
    if (index == controllers.length - 1) return 'To';
    return 'Stop $index';
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(locationProvider);
    final historyAsync = ref.watch(searchHistoryProvider);

    // Wipe fields reactively if authentication changes or clears out entirely
    ref.listen<AsyncValue<AuthStoreEvent>>(authStateProvider, (previous, next) {
      next.whenData((event) {
        // Now 'event' is safely unwrapped as a real AuthStoreEvent
        if (event.token.isEmpty) {
          _resetInputFields();
        }
      });
    });
    final pb = ref.watch(pbProvider);
    final isLoggedIn = pb.authStore.isValid;

    final List<String> historyOptions = historyAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <String>[],
    );

    return GestureDetector(
      onTap: _clearAllFocus,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Choose Route'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _clearAllFocus();
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_location_rounded),
              onPressed: addStop,
            ),
          ],
        ),
        drawer: Drawer(
          key: const ValueKey('navigation_drawer_root'),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    isLoggedIn ? Icons.person : Icons.person_outline_rounded,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                accountName: Text(
                  isLoggedIn
                      ? (() {
                          // 1. Try to get the "name" field using PocketBase's official getter
                          final name =
                              pb.authStore.record?.getStringValue('name') ?? '';
                          if (name.trim().isNotEmpty) return name;

                          // 2. Fallback to username if name is empty or unconfigured
                          final username =
                              pb.authStore.record?.getStringValue('username') ??
                                  '';
                          if (username.trim().isNotEmpty) return username;

                          // 3. Last resort fallback
                          return 'Rider Account';
                        })()
                      : 'Guest Account',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: Text(
                  isLoggedIn
                      ? (pb.authStore.record?.getStringValue('email') ??
                          'Logged In')
                      : 'Log in to back up your trips online.',
                ),
              ),
              if (!isLoggedIn) ...[
                ListTile(
                  leading: const Icon(Icons.login, color: Colors.blue),
                  title: const Text('Sign In Account',
                      style: TextStyle(color: Colors.blue)),
                  onTap: () {
                    Navigator.pop(context);
                    _showLoginDialog();
                  },
                ),
              ],
              if (isLoggedIn) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
                  child: Text(
                    'Recent Searches',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                if (historyOptions.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'No recent searches found.',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  )
                else
                  ...historyOptions.map((String query) {
                    return ListTile(
                      leading: const Icon(Icons.history, size: 20),
                      title: Text(query,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onLongPress: () =>
                          _showDeleteConfirmationDialog(context, query),
                      onTap: () {
                        if (controllers.isNotEmpty) {
                          controllers[0].text = query;
                        }
                        Navigator.pop(context);
                      },
                    );
                  }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.orangeAccent),
                  title: const Text('Clear Cloud History'),
                  onTap: () {
                    ref.read(searchHistoryProvider.notifier).clearHistory();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sign Out',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    _resetInputFields();
                    ref.read(authControllerProvider.notifier).logout();
                    ref.invalidate(searchHistoryProvider);
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              TextButton.icon(
                onPressed: () {
                  _clearAllFocus();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Popup Title'),
                        content: const Text('This is a popup screen'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.location_city),
                label: Text(city.name),
              ),
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
                            child: Autocomplete<String>(
                              key: ValueKey(
                                  'autocomplete_${index}_${historyOptions.join(',')}'),
                              textEditingController: controllers[index],
                              focusNode: focusNodes[index],
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return historyOptions;
                                }
                                return historyOptions.where((String option) {
                                  return option.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      );
                                });
                              },
                              onSelected: (String selection) {
                                controllers[index].text = selection;
                                _clearAllFocus();
                              },
                              fieldViewBuilder: (context, textController,
                                  internalFocusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: textController,
                                  focusNode: internalFocusNode,
                                  decoration: InputDecoration(
                                    labelText: getLabel(index),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.history,
                                        size: 20, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (index != 0 && index != controllers.length - 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
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
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String query) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Search History?'),
          content: Text(
              'Are you sure you want to permanently remove "$query" from your cloud history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(searchHistoryProvider.notifier)
                    .deleteHistoryItem(query);
                if (dialogContext.mounted) Navigator.pop(dialogContext);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
