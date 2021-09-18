import 'dart:async' show Completer, StreamSubscription;
import 'dart:collection' show LinkedHashMap;
import 'dart:html';

import 'isolated_worker_web.dart';

const int _kMaxCallbackMessageId = 1000;

class JsIsolatedWorkerImpl implements JsIsolatedWorker {
  factory JsIsolatedWorkerImpl() => _instance;

  JsIsolatedWorkerImpl._() {
    _init();
  }

  static final JsIsolatedWorkerImpl _instance = JsIsolatedWorkerImpl._();

  /// This should've been [LinkedHashMap] with type arguments of:
  /// - `FutureOr<R> Function(Q)`
  /// - `Completer<R>`
  ///
  /// It is now a [List] consists of:
  /// - [0] is `id`
  /// - [1] is `functionName`
  /// - [2] is `arguments`
  final LinkedHashMap<List<dynamic>, dynamic> _callbackObjects =
      LinkedHashMap<List<dynamic>, dynamic>(
    equals: (List<dynamic> a, List<dynamic> b) {
      return a[0] == b[0];
    },
    hashCode: (List<dynamic> callbackObject) {
      return callbackObject[0].hashCode;
    },
  );

  final Completer<Worker?> _workerCompleter = Completer<Worker?>();

  Future<Worker?> get _worker => _workerCompleter.future;

  // ignore: cancel_subscriptions, use_late_for_private_fields_and_variables
  StreamSubscription<MessageEvent>? _workerMessages;

  /// current count for next id
  int _callbackMessageId = 0;

  void _init() {
    if (Worker.supported) {
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
    /// [0] => id
    /// [1] => functionName
    /// [2] => return type ("result" or "error")
    /// [3] => value
    final List<dynamic> messageData = message.data as List<dynamic>;

    final Completer<dynamic> callbackCompleter =
        _callbackObjects.remove(messageData) as Completer<dynamic>;
    final String type = messageData[2] as String;
    final dynamic resultOrError = messageData[3];
    if (type == 'result') {
      callbackCompleter.complete(resultOrError);
    } else if (type == 'error') {
      callbackCompleter.completeError(resultOrError as Object);
    }
  }

  @override
  Future<bool> importScripts(List<String> scripts) async {
    assert(scripts.isNotEmpty);

    final Worker? worker = await _worker;
    if (worker != null) {
      worker.postMessage(['\$init_scripts', ...scripts]);
      return true;
    }
    return false;
  }

  @override
  Future<dynamic> run({
    required dynamic functionName,
    required dynamic arguments,
    Future<dynamic> Function()? fallback,
  }) async {
    assert(functionName != null);

    final Worker? worker = await _worker;
    // worker not available
    if (worker == null) {
      return fallback?.call();
    }
    _resetCurrentCallbackMessageIdIfReachedMax();
    final Completer<dynamic> callbackCompleter = Completer<dynamic>();
    final List<dynamic> callbackMessage = <dynamic>[
      _callbackMessageId++,
      functionName,
      arguments,
    ];

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
