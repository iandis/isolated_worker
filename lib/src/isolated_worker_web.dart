import 'dart:async' show Completer, FutureOr, StreamSubscription;
import 'dart:collection' show LinkedHashMap;
import 'dart:html';
import 'dart:js';

import 'isolated_worker.dart';
import 'isolated_worker_web_jsobjects.dart';

const int _kMaxCallbackMessageId = 1000;

class IsolatedWorkerImpl implements IsolatedWorker {
  factory IsolatedWorkerImpl() => _instance;

  IsolatedWorkerImpl._() {
    _init();
  }

  static final IsolatedWorkerImpl _instance = IsolatedWorkerImpl._();

  /// this should've been [LinkedHashMap] with type arguments of:
  /// - `FutureOr<R> Function(Q)`
  /// - `Completer<R>`
  ///
  /// But we can't due to analyzer's restriction on [dynamic] type arguments
  final LinkedHashMap<CallbackObject, dynamic> _callbackObjects = LinkedHashMap<CallbackObject, dynamic>(
    equals: (CallbackObject a, CallbackObject b) {
      return a.id == b.id && a.callback == b.callback;
    },
    hashCode: (CallbackObject callbackObject) {
      return callbackObject.id.hashCode ^ callbackObject.callback.hashCode;
    },
  );

  final Completer<Worker?> _workerCompleter = Completer<Worker?>();

  Future<Worker?> get _worker => _workerCompleter.future;

  // ignore: cancel_subscriptions, use_late_for_private_fields_and_variables
  StreamSubscription<MessageEvent>? _workerMessages;

  /// current count for next [CallbackMessage] id
  int _callbackMessageId = 0;

  void _init() {
    if (Worker.supported) {
      document.body!.appendHtml('<script src="isolated_worker.js" type="application/javascript"></script>');
      document.body!.appendHtml('<script src="worker.js" type="application/javascript"></script>');
      final Worker worker = Worker('worker.js');
      _workerCompleter.complete(worker);
      _workerMessages = worker.onMessage.listen(_workerMessageReceiver);
    } else {
      _workerCompleter.complete(null);
    }
  }

  /// reset [_callbackMessageId] when reached [_kMaxCallbackMessageId]
  void _resetCurrentCallbackMessageIdIfReachedMax() {
    if (_callbackMessageId == _kMaxCallbackMessageId) {
      _callbackMessageId = 0;
    }
  }

  void _workerMessageReceiver(MessageEvent message) {
    final dynamic messageData = message.data;

    if (messageData is CallbackObject) {
      final Completer<dynamic> callbackCompleter = _callbackObjects.remove(messageData) as Completer<dynamic>;

      if (messageData is ResultMessage) {
        callbackCompleter.complete(messageData.result);
      } else if (messageData is ResultErrorMessage) {
        callbackCompleter.completeError(messageData.error);
      }
    }
  }

  @override
  Future<R> run<Q, R>(
    FutureOr<R> Function(Q message) callback,
    Q message,
  ) async {
    final Worker? worker = await _worker;
    // worker not available
    if (worker == null) {
      return callback(message);
    }
    _resetCurrentCallbackMessageIdIfReachedMax();
    final Completer<R> callbackCompleter = Completer<R>();
    final CallbackMessage callbackMessage = CallbackMessage()
      ..id = _callbackMessageId++
      ..callback = allowInterop(callback)
      ..message = message;
      
    _callbackObjects[callbackMessage] = callbackCompleter;
    worker.postMessage(callbackMessage);
    return callbackCompleter.future;
  }

  @override
  Future<void> close() async {
    final Worker? worker = await _worker;
    if (worker != null) {
      _workerMessages!.cancel();
      worker.terminate();
    }
  }
}
