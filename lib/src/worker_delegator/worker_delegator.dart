import 'package:isolated_worker/src/flutter_constants.dart';
import 'package:isolated_worker/src/isolated_worker_default.dart';
import 'package:isolated_worker/src/isolated_worker_web.dart';
import 'package:isolated_worker/src/worker_delegator/worker_delegate.dart';

part 'worker_delegator_impl.dart';

/// A class helping for easier bridging between
/// [IsolatedWorker] and [JsIsolatedWorker].
///
/// It will call [WorkerDelegate.defaultDelegate] when running on Dart VM.
///
/// When running on Web, it will call [WorkerDelegate.jsDelegate] instead.
abstract class WorkerDelegator {
  /// Returns a singleton instance of [WorkerDelegator]
  factory WorkerDelegator() => _WorkerDelegatorImpl._instance;

  factory WorkerDelegator.asNewInstance({
    Iterable<WorkerDelegate> delegates,
  }) = _WorkerDelegatorImpl;

  /// Executes [JsIsolatedWorker.importScripts] when running on Web.
  ///
  /// If it's running on Dart VM, this will always return `true`.
  Future<bool> importScripts(List<String> scripts);

  /// Adds a new [WorkerDelegate] with its [WorkerDelegate.key].
  ///
  /// Each [delegate] should have its unique key, meaning two or more
  /// [WorkerDelegate] with the same key cannot be added. Otherwise it will
  /// throw [AssertionError] on debug mode.
  void addDelegate<Q, R>(WorkerDelegate<Q, R> delegate);

  /// Adds new multiple [WorkerDelegate]s.
  ///
  /// Each of the [delegates] should have its unique key, meaning two or more
  /// [WorkerDelegate] with the same key cannot be added. Otherwise it will
  /// throw [AssertionError] on debug mode.
  void addAllDelegates<Q, R>(Iterable<WorkerDelegate<Q, R>> delegates);

  /// Executes a callback that is associated with the [key].
  ///
  /// If no [WorkerDelegate] with [key] found, this will throw [ArgumentError].
  Future<R> run<Q, R>(Object key, dynamic message);

  /// Closes the worker.
  ///
  /// If it's running on Dart VM, it will call [IsolatedWorker.close].
  ///
  /// If it's running on Web, it will call [JsIsolatedWorker.close].
  void close();
}
