import 'dart:async';

/// Reactivity glue for sqflite-backed repositories.
///
/// sqflite has no change notifications, so each repository keeps a broadcast
/// "changes" stream it pings after every mutation. [watchQuery] turns that
/// ping stream + a re-runnable query into a `watch*` stream that:
///  * emits the current query result immediately on listen, and
///  * re-queries and emits after every change ping.
///
/// Emissions are serialised: if pings arrive while a query is in flight, one
/// trailing re-query runs afterwards, so listeners never observe results out
/// of order.
Stream<T> watchQuery<T>(
  Stream<void> changes,
  Future<T> Function() query,
) {
  late StreamController<T> controller;
  StreamSubscription<void>? sub;
  var running = false;
  var dirty = false;

  Future<void> emit() async {
    if (running) {
      dirty = true;
      return;
    }
    running = true;
    try {
      do {
        dirty = false;
        final value = await query();
        if (controller.isClosed) return;
        controller.add(value);
      } while (dirty);
    } finally {
      running = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      // Subscribe to pings before the initial query so no change is missed.
      sub = changes.listen((_) => emit());
      emit();
    },
    onCancel: () async {
      await sub?.cancel();
      await controller.close();
    },
  );
  return controller.stream;
}
