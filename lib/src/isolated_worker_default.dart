import 'dart:async' show FutureOr;

import 'package:isolated_worker/src/isolated_worker_default_impl.dart'
    if (dart.library.html) 'isolated_worker_default_unimpl.dart';

/// An isolated worker spawning a single Isolate.
abstract class IsolatedWorker {
  /// Returns a singleton instance of [IsolatedWorker]
  factory IsolatedWorker() = IsolatedWorkerImpl;

  /// Just like using Flutter's [compute] function
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  );

  /// Don't try to [close] when the app still needs the [run] function
  FutureOr<void> close();
}
