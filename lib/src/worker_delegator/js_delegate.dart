/// A delegate for when running on Web.
abstract class JsDelegate {
  /// Creates a [JsDelegate] with a single argument [callback] to be
  /// called when running on Web.
  ///
  /// [callback] must be either a [String] or a [List] of [String].
  const factory JsDelegate({
    required dynamic callback,
    Future<dynamic> Function()? fallback,
  }) = _SingleDynamicArgumentJsDelegate;

  /// The callback name declared in the web worker.
  /// This should either be a [String] or a [List] of [String],
  /// otherwise it will throw [AssertionError] on debug mode.
  dynamic get callback;

  /// The fallback function that will be called by JsIsolatedWorker
  /// when Web Worker is not available on the user's browser.
  Future<dynamic> Function()? get fallback;
}

class _SingleDynamicArgumentJsDelegate implements JsDelegate {
  const _SingleDynamicArgumentJsDelegate({
    required this.callback,
    this.fallback,
  }) : assert(
          callback is String || callback is List<String>,
          '$callback is not compatible with type `String` or `List<String>`',
        );

  @override
  final dynamic callback;

  @override
  final Future<dynamic> Function()? fallback;
}
