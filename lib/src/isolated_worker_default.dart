import 'dart:async' show FutureOr;

import 'isolated_worker_default_impl.dart'
    if (dart.library.html) 'isolated_worker_default_unimpl.dart';

/// An isolated worker spawning a single Isolate.
abstract class IsolatedWorker {
  factory IsolatedWorker.create() = IsolatedWorkerImpl.create;

  /// Just like using `Isolate.run` function
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  );

  bool get isClosed;

  /// Closes the this worker, and sends a [IsolatedWorkerShutdownException] to
  /// every running callbacks.
  FutureOr<void> close();
}

abstract class IsolatedSingleOperation {
  factory IsolatedSingleOperation() = IsolatedSingleOperationImpl;

  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  );

  /// Closes the running [IsolatedWorker] and creates a new one.
  void release();
}

sealed class IsolatedWorkerException implements Exception {}

class IsolatedWorkerShutdownException implements IsolatedWorkerException {}

class IsolatedWorkerUnexpectedShutdownException
    implements IsolatedWorkerException {
  IsolatedWorkerUnexpectedShutdownException({
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;
}
