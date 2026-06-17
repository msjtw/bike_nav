import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pocketbase_provider.dart';

class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final pb = ref.watch(pbProvider);

    if (!pb.authStore.isValid) return [];
    final userId = pb.authStore.record?.id;
    if (userId == null) return [];

    // Pass the userId down so we only query this specific account's rows
    final initialList = await _fetchFromDatabase(userId);

    pb.collection('search_history').subscribe('*', (e) {
      final record = e.record;
      if (record == null) return;

      // FIX: Ignore real-time websocket signals belonging to other accounts
      if (record.getStringValue('user') != userId) return;

      final query = record.getStringValue('query');
      final currentList = state.value ?? [];

      if (e.action == 'create') {
        if (!currentList.contains(query)) {
          state = AsyncValue.data([query, ...currentList].take(10).toList());
        }
      } else if (e.action == 'delete') {
        state = AsyncValue.data(
            currentList.where((item) => item != query).toList());
      }
    }).catchError((error) {
      debugPrint("PocketBase subscription error: $error");
    });

    ref.onDispose(() {
      pb.collection('search_history').unsubscribe('*');
    });

    return initialList;
  }

  Future<List<String>> _fetchFromDatabase(String userId) async {
    final pb = ref.read(pbProvider);
    try {
      final records = await pb.collection('search_history').getList(
            filter: 'user = "$userId"',
            sort: '-created',
          );
      return records.items.map((item) => item.getStringValue('query')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final pb = ref.read(pbProvider);
    if (!pb.authStore.isValid) return;

    final userId = pb.authStore.record?.id;
    if (userId == null) return;

    final previousState = state.value ?? [];
    final updatedList = List<String>.from(previousState)..remove(trimmed);
    state = AsyncValue.data([trimmed, ...updatedList].take(10).toList());

    try {
      final existing = await pb.collection('search_history').getList(
            page: 1,
            perPage: 1,
            filter: 'user = "$userId" && query = "$trimmed"',
          );

      if (existing.items.isNotEmpty) {
        await pb.collection('search_history').delete(existing.items.first.id);
      }

      await pb.collection('search_history').create(body: {
        "query": trimmed,
        "user": userId,
      });
    } catch (e) {
      state = AsyncValue.data(previousState);
    }
  }

  Future<void> deleteHistoryItem(String query) async {
    final pb = ref.read(pbProvider);
    if (!pb.authStore.isValid) return;

    final userId = pb.authStore.record?.id;
    if (userId == null) return;

    final previousState = state.value ?? [];
    state =
        AsyncValue.data(previousState.where((item) => item != query).toList());

    try {
      final records = await pb.collection('search_history').getList(
            filter: 'user = "$userId" && query = "$query"',
          );

      for (final record in records.items) {
        await pb.collection('search_history').delete(record.id);
      }
    } catch (e) {
      debugPrint("Failed to delete item: $e");
      state = AsyncValue.data(previousState);
    }
  }

  Future<void> clearHistory() async {
    final pb = ref.read(pbProvider);
    if (!pb.authStore.isValid) return;

    final userId = pb.authStore.record?.id;
    if (userId == null) return;

    final previousState = state.value ?? [];
    state = const AsyncValue.data([]);

    try {
      final records = await pb.collection('search_history').getFullList(
            filter: 'user = "$userId"',
          );

      for (final record in records) {
        await pb.collection('search_history').delete(record.id);
      }
    } catch (e) {
      debugPrint("Error clearing history: $e");
      state = AsyncValue.data(previousState);
    }
  }
}

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
  () => SearchHistoryNotifier(),
);

final guestModeProvider = Provider<bool>((ref) => false);
