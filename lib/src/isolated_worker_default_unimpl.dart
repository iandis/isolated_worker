import 'dart:async' show FutureOr;

import 'isolated_worker_default.dart';

class IsolatedWorkerImpl implements IsolatedWorker {
  factory IsolatedWorkerImpl.create() {
    throw UnimplementedError(
      'IsolatedWorker is not available on this platform',
    );
  }

  @override
  void close() {
    throw UnimplementedError(
      'IsolatedWorker is not available on this platform',
    );
  }

  @override
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  ) {
    throw UnimplementedError(
      'IsolatedWorker is not available on this platform',
    );
  }

  @override
  bool get isClosed => throw UnimplementedError(
        'IsolatedWorker is not available on this platform',
      );
}

class IsolatedSingleOperationImpl implements IsolatedSingleOperation {
  @override
  void release() {
    throw UnimplementedError(
      'IsolatedSingleOperation is not available on this platform',
    );
  }

  @override
  Future<R> run<Q, R>(FutureOr<R> Function(Q message) callback, Q message) {
    throw UnimplementedError(
      'IsolatedSingleOperation is not available on this platform',
    );
  }
}
