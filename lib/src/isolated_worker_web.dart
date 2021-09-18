import 'dart:async' show Completer, StreamSubscription;
import 'dart:collection' show LinkedHashMap;
import 'dart:html';

const int _kMaxCallbackMessageId = 1000;

/// An isolated worker spawning a single [Worker]
/// 
/// It's better to run [importScripts] first before going
/// to use any javascript functions in the worker.
/// 
/// However it is not mandatory to do so if no javascript files
/// are needed by the worker, e.g. the `JSON.stringify` function.
/// 
/// It will be mandatory to do so if there are external javascript 
/// files needed by the worker.
class JsIsolatedWorker {
  /// Returns a singleton instance of [JsIsolatedWorker]
  factory JsIsolatedWorker() => _instance;

  JsIsolatedWorker._() {
    _init();
  }

  static final JsIsolatedWorker _instance = JsIsolatedWorker._();

  /// This should've been [LinkedHashMap] with type arguments of:
  /// - `FutureOr<R> Function(Q)`
  /// - `Completer<R>`
  ///
  /// It is now a [List] consists of:
  /// - [0] is `id`
  /// - [1] is `functionName`
  /// - [2] is `arguments`
  final LinkedHashMap<List<dynamic>, dynamic> _callbackObjects = LinkedHashMap<List<dynamic>, dynamic>(
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

    final Completer<dynamic> callbackCompleter = _callbackObjects.remove(messageData) as Completer<dynamic>;
    final String type = messageData[2] as String;
    final dynamic resultOrError = messageData[3];
    if (type == 'result') {
      callbackCompleter.complete(resultOrError);
    } else if (type == 'error') {
      callbackCompleter.completeError(resultOrError as Object);
    }
  }

  /// It's important to wait for [importScripts] to complete
  /// 
  /// If this returns `false` then it is discouraged to use the [run] function,
  /// because it cannot do anything other than calling its fallback parameter.
  /// 
  /// [scripts] cannot be empty.
  /// 
  /// example:
  /// ```dart
  /// void main() async {
  ///   final bool loaded = await JsIsolatedWorker().importScripts(
  ///     ['my_module1.js', 'my_module2.js']
  ///   );
  ///   if(loaded) {
  ///     print(await JsIsolatedWorker().run(
  ///       functionName: 'myFunction1',
  ///       arguments: 100,
  ///     ));
  ///   }
  /// }
  /// ```
  Future<bool> importScripts(List<String> scripts) async {
    assert(scripts.isNotEmpty);

    final Worker? worker = await _worker;
    if (worker != null) {
      worker.postMessage(['\$init_scripts', ...scripts]);
      return true;
    }
    return false;
  }

  /// [functionName] can be a [String] or a [List] of [String]
  ///
  /// this will be called by the worker like below:
  ///
  /// ```js
  /// const callback = self[functionName];
  /// // or
  /// const length = functionName.length;
  /// let callback = self[functionName[0]];
  /// for (let i = 1; i < length; i++) {
  ///   callback = callback[functionName[i]];
  /// }
  /// ```
  ///
  /// [arguments] the arguments that will be applied to the callback defined by [functionName]
  ///
  /// ```js
  /// // if we need to call the JSON.stringify function: 
  /// // functionName = ['JSON','stringify'];
  /// const callback = self[functionName];
  /// const result = callback(arguments);
  /// ```
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

  /// Don't attempt to [close] when the app still needs the [run] function.
  Future<void> close() async {
    final Worker? worker = await _worker;
    if (worker != null) {
      _workerMessages!.cancel();
      worker.terminate();
    }
  }
}
