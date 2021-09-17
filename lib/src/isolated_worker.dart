import 'dart:async' show FutureOr;

import 'isolated_worker_default.dart' if (dart.library.html) 'isolated_worker_web.dart' as _isolated_worker
    show IsolatedWorkerImpl;

/// An isolated worker spawn a single [Isolate].
/// 
/// When running on web this will spawn a single [Worker] instead.
abstract class IsolatedWorker {
  /// Returns a singleton instance of [IsolatedWorker]
  factory IsolatedWorker() = _isolated_worker.IsolatedWorkerImpl;

  /// Just like using Flutter's [compute] function
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  );

  /// Don't try to [close] when the app is still running
  FutureOr<void> close();
}
