import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final pb = ref.watch(pbProvider);
    return AuthState(isAuthenticated: pb.authStore.isValid);
  }

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true);
    final pb = ref.read(pbProvider);

    try {
      await pb.collection('users').authWithPassword(email, password);
      state = AuthState(isAuthenticated: true);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString().contains('400')
            ? 'Invalid email or password'
            : 'Connection error',
      );
    }
  }

  void logout() {
    final pb = ref.read(pbProvider);
    pb.authStore.clear();
    state = AuthState(isAuthenticated: false);
  }
}

final authControllerProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main.dart first');
});

final pbProvider = Provider<PocketBase>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const storageKey = 'pb_auth';
  final cachedAuth = prefs.getString(storageKey);

  final authStore = AsyncAuthStore(
    initial: cachedAuth,
    save: (String data) async {
      await prefs.setString(storageKey, data);
    },
    clear: () async {
      await prefs.remove(storageKey);
    },
  );

  return PocketBase('http://192.168.1.102:8090', authStore: authStore);
});

final authStateProvider = StreamProvider<AuthStoreEvent>((ref) {
  final pb = ref.watch(pbProvider);
  return pb.authStore.onChange;
});
