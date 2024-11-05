import 'dart:async' show Completer, FutureOr, StreamSubscription;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;

import 'isolated_worker_default.dart';

sealed class _CallbackResult {
  int get id;
}

class _ResultMessage implements _CallbackResult {
  const _ResultMessage({
    required this.id,
    required this.result,
  });

  @override
  final int id;
  final dynamic result;
}

class _ResultErrorMessage implements _CallbackResult {
  const _ResultErrorMessage({
    required this.id,
    required this.error,
    required this.stackTrace,
  });

  @override
  final int id;
  final Object error;
  final StackTrace? stackTrace;
}

class IsolatedWorkerImpl implements IsolatedWorker {
  factory IsolatedWorkerImpl.create() => IsolatedWorkerImpl._();

  /// it's important to call [IsolatedWorkerImpl._init] first
  /// before running any operations using [IsolatedWorkerImpl.run]
  IsolatedWorkerImpl._() {
    _init();
  }

  /// this is used to listen messages sent by [_Worker]
  ///
  /// its [SendPort] is used by [_Worker] to send messages
  final ReceivePort _receivePort = ReceivePort();

  final ReceivePort _errorPort = ReceivePort();

  /// we need to wrap [_workerSendPort] with [Completer] to avoid
  /// late initialization error
  final Completer<SendPort> _workerSendPortCompleter = Completer<SendPort>();

  Map<int, Completer<dynamic>> _callbacks = {};

  late final Isolate _isolate;

  /// used by [IsolatedWorker] to send messages to [_Worker]
  Future<SendPort> get _workerSendPort => _workerSendPortCompleter.future;

  Future<void> _init() async {
    _receivePort.listen(_workerMessageReceiver);
    _errorPort.listen(_errorMessageReceiver);
    _isolate = await Isolate.spawn<SendPort>(
      _workerEntryPoint,
      _receivePort.sendPort,
      onError: _errorPort.sendPort,
    );
  }

  int _idCounter = 0;
  static const int _kMaxId = 1000000;

  void _resetIdCounterIfReachedMax() {
    if (_idCounter == _kMaxId) {
      _idCounter = 0;
    }
  }

  @override
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  ) async {
    if (isClosed) {
      throw StateError('IsolatedWorker is already closed.');
    }

    _resetIdCounterIfReachedMax();
    final Completer<R> callbackCompleter = Completer<R>();
    final id = _idCounter++;
    _callbacks[id] = callbackCompleter;
    final workerSendPort = await _workerSendPort;
    workerSendPort.send(_CallbackMessage(
      id: id,
      callback: callback,
      message: message,
    ));
    return callbackCompleter.future;
  }

  void _workerMessageReceiver(dynamic message) {
    if (isClosed) return;

    if (message is SendPort) {
      _workerSendPortCompleter.complete(message);
    } else if (message is _CallbackResult) {
      final callbackCompleter = _callbacks.remove(message.id);
      if (callbackCompleter == null || callbackCompleter.isCompleted) return;

      switch (message) {
        case _ResultMessage _:
          callbackCompleter.complete(message.result);
        case _ResultErrorMessage _:
          callbackCompleter.completeError(message.error, message.stackTrace);
      }
    }
  }

  void _errorMessageReceiver(dynamic message) {
    if (isClosed) return;

    final msg = message as List<dynamic>;
    final errorString = msg[0] as String;
    final stackTraceString = msg[1] as String?;
    final stackTrace = stackTraceString != null
        ? StackTrace.fromString(stackTraceString)
        : null;

    _closeWithError(IsolatedWorkerUnexpectedShutdownException(
      error: errorString,
      stackTrace: stackTrace,
    ));
  }

  bool _isClosed = false;
  @override
  bool get isClosed => _isClosed;

  @override
  Future<void> close() => _closeWithError(IsolatedWorkerShutdownException());

  Future<void> _closeWithError(IsolatedWorkerException error) async {
    if (isClosed) return;

    _isClosed = true;
    final callbacks = _callbacks;
    _callbacks = {};
    for (final id in callbacks.keys) {
      final callbackCompleter = callbacks[id]!;
      if (callbackCompleter.isCompleted) continue;

      callbackCompleter.completeError(
        error,
        error is IsolatedWorkerUnexpectedShutdownException
            ? error.stackTrace
            : null,
      );
    }

    /// tell [_Worker] to call _dispose()
    final SendPort sendPort = await _workerSendPort;
    sendPort.send(false);
    _receivePort.close();
    _errorPort.close();
    _isolate.kill(priority: Isolate.immediate);
  }
}

final class _CallbackMessage {
  _CallbackMessage({
    required this.id,
    required this.callback,
    required this.message,
  });

  final int id;
  final Function callback;
  final dynamic message;
}

void _workerEntryPoint(final SendPort parentSendPort) {
  _Worker(parentSendPort);
}

class _Worker {
  _Worker(this.parentSendPort) {
    _init();
  }

  /// this is used to listen messages sent by [IsolatedWorker]
  ///
  /// its [SendPort] is used by [IsolatedWorker] to send messages
  final ReceivePort _receivePort = ReceivePort();

  /// this is used to send messages back to [IsolatedWorker]
  final SendPort parentSendPort;

  late final StreamSubscription<dynamic> _parentMessages;

  void _init() {
    _parentMessages = _receivePort.listen(_parentMessageReceiver);

    parentSendPort.send(_receivePort.sendPort);
  }

  void _parentMessageReceiver(dynamic message) {
    if (message is bool) {
      _dispose();
    } else if (message is _CallbackMessage) {
      _runCallback(message);
    }
  }

  Future<void> _runCallback(
    final _CallbackMessage parentMessage,
  ) async {
    try {
      final dynamic result = await parentMessage.callback(parentMessage.message);

      final _ResultMessage resultMessage = _ResultMessage(
        id: parentMessage.id,
        result: result,
      );
      parentSendPort.send(resultMessage);
    } catch (e, st) {
      final _ResultErrorMessage resultErrorMessage = _ResultErrorMessage(
        id: parentMessage.id,
        error: e,
        stackTrace: st,
      );
      parentSendPort.send(resultErrorMessage);
    }
  }

  void _dispose() {
    _parentMessages.cancel();
    _receivePort.close();
  }
}

class IsolatedSingleOperationImpl implements IsolatedSingleOperation {
  IsolatedWorker? _worker;

  @override
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  ) {
    release();
    final worker = IsolatedWorkerImpl.create();
    _worker = worker;
    return worker.run(callback, message).whenComplete(worker.close);
  }

  @override
  void release() {
    _worker?.close();
    _worker = null;
  }
}
