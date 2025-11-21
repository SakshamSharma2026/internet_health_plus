import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_health_plus/internet_health_plus.dart';

/// --- Providers ---

/// Provides a lifecycle-managed InternetHealthPlus instance.
/// When the provider is disposed (no listeners), `checker.dispose()` runs.
final internetCheckerProvider = Provider<InternetHealthPlus>((ref) {
  var options = ProbeOptions(periodicProbeInterval: Duration(seconds: 2));
  final checker = InternetHealthPlus(
    options: options,
  ); // created once per ProviderScope lifetime
  ref.onDispose(() => checker.dispose());
  return checker;
});

/// Stream provider that emits InternetStatus updates.
/// autoDispose means it will cancel subscription when UI doesn't need it.
final internetStatusStreamProvider = StreamProvider<InternetStatus>((ref) {
  final checker = ref.watch(internetCheckerProvider);

  final controller = StreamController<InternetStatus>();

  // emit last known status immediately
  controller.add(checker.lastStatus);

  // forward live updates
  final sub = checker.onStatusChange.listen(controller.add);

  // do an immediate probe so UI shows fresh result
  checker.checkInternetDetailed();

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});
