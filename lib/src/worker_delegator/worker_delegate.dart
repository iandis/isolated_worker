import 'package:isolated_worker/src/flutter_constants.dart';
import 'package:isolated_worker/src/worker_delegator/default_delegate.dart';
import 'package:isolated_worker/src/worker_delegator/js_delegate.dart';

/// A worker delegate for both Dart's Isolate and Web Worker.
abstract class WorkerDelegate<Q, R> {
  /// Creates a new [WorkerDelegate] that consists of its [key],
  /// [defaultDelegate] for when running on Dart VM, and
  /// [jsDelegate] for when running on Web.
  const factory WorkerDelegate({
    required Object key,
    required DefaultDelegate<Q, R> defaultDelegate,
    required JsDelegate jsDelegate,
  }) = _AdaptiveWorkerDelegate<Q, R>;

  /// The key associated to this [WorkerDelegate].
  Object get key;

  /// The delegate for when running on Dart VM.
  ///
  /// This will be null when running on Web.
  JsDelegate get jsDelegate;

  /// The delegate for when running on Web.
  ///
  /// This will be null when running on Dart VM.
  DefaultDelegate<Q, R> get defaultDelegate;
}

class _AdaptiveWorkerDelegate<Q, R> implements WorkerDelegate<Q, R> {
  const _AdaptiveWorkerDelegate({
    required this.key,
    required DefaultDelegate<Q, R> defaultDelegate,
    required JsDelegate jsDelegate,
  })  : _jsDelegate = isWeb ? jsDelegate : null,
        _defaultDelegate = isWeb ? null : defaultDelegate;

  @override
  final Object key;

  final DefaultDelegate<Q, R>? _defaultDelegate;

  @override
  DefaultDelegate<Q, R> get defaultDelegate {
    if (_defaultDelegate != null) {
      return _defaultDelegate!;
    }
    throw UnsupportedError('defaultDelegate');
  }

  final JsDelegate? _jsDelegate;

  @override
  JsDelegate get jsDelegate {
    if (_jsDelegate != null) {
      return _jsDelegate!;
    }
    throw UnsupportedError('jsDelegate');
  }
}
