import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackingNotifier extends Notifier<int> {
  // We initialize the list of todos to an empty list
  @override
  int build() {
    return 0;
  }

  void toggle() {
    if (state == 1) {
      state = 0;
    } else {
      state = 1;
    }
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, int>(() {
  return TrackingNotifier();
});
