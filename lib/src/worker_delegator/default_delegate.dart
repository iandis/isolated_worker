import 'dart:async' show FutureOr;

/// A delegate for when running on Dart VM.
abstract class DefaultDelegate<Q, R> {
  /// Creates a [DefaultDelegate] with a single argument [callback] to be called
  /// when running on Dart VM.
  const factory DefaultDelegate({
    required FutureOr<R> Function(Q message) callback,
  }) = _SingleArgumentDefaultDelegate<Q, R>;

  /// The callback that will be called when the app is running
  /// on Dart VM (Android, iOS, macOS, etc).
  ///
  /// This must be a top-level function.
  FutureOr<R> Function(Q message) get callback;
}

class _SingleArgumentDefaultDelegate<Q, R> implements DefaultDelegate<Q, R> {
  const _SingleArgumentDefaultDelegate({
    required this.callback,
  });

  @override
  final FutureOr<R> Function(Q message) callback;
}
