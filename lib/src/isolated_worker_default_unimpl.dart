import 'dart:async' show FutureOr;

import 'package:isolated_worker/src/isolated_worker_default.dart';

class IsolatedWorkerImpl implements IsolatedWorker {
  factory IsolatedWorkerImpl() {
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
}
