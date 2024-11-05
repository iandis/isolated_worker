part of 'worker_delegator.dart';

class _WorkerDelegatorImpl implements WorkerDelegator {
  _WorkerDelegatorImpl({
    Iterable<WorkerDelegate> delegates = const Iterable<WorkerDelegate>.empty(),
  }) {
    addAllDelegates(delegates);
  }

  final IsolatedWorker _isolatedWorker = IsolatedWorker.create();
  static final _WorkerDelegatorImpl _instance = _WorkerDelegatorImpl();

  final Map<Object, WorkerDelegate> _delegates = <Object, WorkerDelegate>{};

  @override
  Future<bool> importScripts(List<String> scripts) {
    if (isWeb) {
      return JsIsolatedWorker().importScripts(scripts);
    }

    return Future<bool>.value(true);
  }

  @override
  void addAllDelegates<Q, R>(Iterable<WorkerDelegate<Q, R>> delegates) {
    for (final WorkerDelegate delegate in delegates) {
      addDelegate(delegate);
    }
  }

  @override
  void addDelegate<Q, R>(WorkerDelegate<Q, R> delegate) {
    assert(
      !_delegates.containsKey(delegate.key),
      'WorkerDelegate of "${delegate.key}" already exists!',
    );
    _delegates[delegate.key] = delegate;
  }

  @override
  Future<R> run<Q, R>(Object key, dynamic message) async {
    final WorkerDelegate<Q, R>? delegate =
        _delegates[key] as WorkerDelegate<Q, R>?;
    if (delegate == null) {
      if (isDebugMode || isProfileMode) {
        throw ArgumentError(
          'No WorkerDelegate with key "$key" found!',
          'key',
        );
      }
      throw ArgumentError(
        'Not found',
        'key',
      );
    }
    if (isWeb) {
      return await JsIsolatedWorker().run(
        functionName: delegate.jsDelegate.callback,
        arguments: message,
        fallback: delegate.jsDelegate.fallback,
      ) as R;
    }

    return _isolatedWorker.run<Q, R>(
      delegate.defaultDelegate.callback,
      message as Q,
    );
  }

  @override
  void close() {
    if (isWeb) {
      JsIsolatedWorker().close();
      return;
    }
    _isolatedWorker.close();
  }
}
