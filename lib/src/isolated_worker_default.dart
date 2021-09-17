import 'dart:async' show Completer, FutureOr, StreamSubscription;
import 'dart:collection' show LinkedHashMap;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;

import 'isolated_worker.dart';

const int _kMaxCallbackMessageId = 1000;

abstract class _CallbackObject {
  int get id;
  dynamic get callback;
}

class _CallbackMessage implements _CallbackObject {
  const _CallbackMessage({
    required this.id,
    required this.callback,
    required this.message,
  });

  @override
  final int id;

  /// `FutureOr<R> Function(Q message)`
  @override
  final dynamic callback;

  /// `Q message`
  final dynamic message;
}

class _ResultMessage implements _CallbackObject {
  const _ResultMessage({
    required this.id,
    required this.callback,
    required this.result,
  });

  factory _ResultMessage.from(
    _CallbackObject callbackObject, {
    required dynamic result,
  }) {
    return _ResultMessage(
      id: callbackObject.id,
      callback: callbackObject.callback,
      result: result,
    );
  }

  @override
  final int id;
  @override
  final dynamic callback;
  final dynamic result;
}

class _ResultErrorMessage implements _CallbackObject {
  const _ResultErrorMessage({
    required this.id,
    required this.callback,
    required this.error,
  });

  factory _ResultErrorMessage.from(
    _CallbackObject callbackObject, {
    required Object error,
  }) {
    return _ResultErrorMessage(
      id: callbackObject.id,
      callback: callbackObject.callback,
      error: error,
    );
  }

  @override
  final int id;
  @override
  final dynamic callback;
  final Object error;
}

class IsolatedWorkerImpl implements IsolatedWorker {
  factory IsolatedWorkerImpl() => _instance;

  /// it's important to call [IsolatedWorkerImpl._init] first
  /// before running any operations using [IsolatedWorkerImpl.run]
  IsolatedWorkerImpl._() {
    _init();
  }

  static final IsolatedWorkerImpl _instance = IsolatedWorkerImpl._();

  /// this is used to listen messages sent by [_Worker]
  ///
  /// its [SendPort] is used by [_Worker] to send messages
  final ReceivePort _receivePort = ReceivePort();

  /// we need to wrap [_workerSendPort] with [Completer] to avoid
  /// late initialization error
  final Completer<SendPort> _workerSendPortCompleter = Completer<SendPort>();

  /// this should've been [LinkedHashMap] with type arguments of:
  /// - `FutureOr<R> Function(Q)`
  /// - `Completer<R>`
  /// 
  /// But we can't due to analyzer's restriction on [dynamic] type arguments
  final LinkedHashMap<_CallbackObject, dynamic> _callbackObjects = LinkedHashMap<_CallbackObject, dynamic>(
    equals: (_CallbackObject a, _CallbackObject b) {
      return a.id == b.id && a.callback == b.callback;
    },
    hashCode: (_CallbackObject callbackObject) {
      return callbackObject.id.hashCode ^ callbackObject.callback.hashCode;
    },
  );

  late final Isolate _isolate;

  /// this is used to send messages to [_Worker]
  late final StreamSubscription<dynamic> _workerMessages;

  /// used by [IsolatedWorkerImpl] to send messages to [_Worker]
  Future<SendPort> get _workerSendPort => _workerSendPortCompleter.future;

  /// current count for next [_CallbackMessage] id
  int _callbackMessageId = 0;

  Future<void> _init() async {
    _workerMessages = _receivePort.listen(_workerMessageReceiver);
    _isolate = await Isolate.spawn<SendPort>(
      _workerEntryPoint,
      _receivePort.sendPort,
    );
  }

  /// reset [_callbackMessageId] when reached [_kMaxCallbackMessageId]
  void _resetCurrentCallbackMessageIdIfReachedMax() {
    if (_callbackMessageId == _kMaxCallbackMessageId) {
      _callbackMessageId = 0;
    }
  }

  @override
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  ) async {
    _resetCurrentCallbackMessageIdIfReachedMax();
    final Completer<R> callbackCompleter = Completer<R>();
    final _CallbackMessage callbackMessage = _CallbackMessage(
      id: _callbackMessageId++,
      callback: callback,
      message: message,
    );
    _callbackObjects[callbackMessage] = callbackCompleter;
    (await _workerSendPort).send(callbackMessage);
    return callbackCompleter.future;
  }

  void _workerMessageReceiver(dynamic message) {
    if (message is SendPort) {
      _workerSendPortCompleter.complete(message);
    } else if (message is _CallbackObject) {
      final Completer<dynamic> callbackCompleter = _callbackObjects.remove(message) as Completer<dynamic>;

      if (message is _ResultMessage) {
        callbackCompleter.complete(message.result);
      } else if (message is _ResultErrorMessage) {
        callbackCompleter.completeError(message.error);
      }
    }
  }

  @override
  void close() {
    /// tell [_Worker] to call _dispose()
    _workerSendPort.then((sendPort) => sendPort.send(false));
    _workerMessages.cancel();
    _receivePort.close();
    _isolate.kill();
  }
}

void _workerEntryPoint(final SendPort parentSendPort) {
  _Worker(parentSendPort).init();
}

class _Worker {
  _Worker(this.parentSendPort);

  /// this is used to listen messages sent by [IsolatedWorkerImpl]
  ///
  /// its [SendPort] is used by [IsolatedWorkerImpl] to send messages
  final ReceivePort _receivePort = ReceivePort();

  /// this is used to send messages back to [IsolatedWorkerImpl]
  final SendPort parentSendPort;

  late final StreamSubscription<dynamic> _parentMessages;

  void init() {
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

      final _ResultMessage resultMessage = _ResultMessage.from(
        parentMessage,
        result: result,
      );
      parentSendPort.send(resultMessage);
    } catch (error) {
      final _ResultErrorMessage resultErrorMessage = _ResultErrorMessage.from(
        parentMessage,
        error: error,
      );
      parentSendPort.send(resultErrorMessage);
    }
  }

  void _dispose() {
    _parentMessages.cancel();
    _receivePort.close();
  }
}
