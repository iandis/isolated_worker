import 'isolated_worker_web_impl.dart'
    if (dart.library.io) 'isolated_worker_web_unimpl.dart';

/// An isolated worker spawning a single Web Worker
///
/// It's better to run [importScripts] first before going
/// to use any javascript functions in the worker.
///
/// However it is not mandatory to do so if no javascript files
/// are needed by the worker, e.g. the `JSON.stringify` function.
///
/// It will be mandatory to do so if there are external javascript
/// files needed by the worker.
abstract class JsIsolatedWorker {
  /// Returns a singleton instance of [JsIsolatedWorker]
  factory JsIsolatedWorker() = JsIsolatedWorkerImpl;

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
  Future<bool> importScripts(List<String> scripts);

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
  });

  /// Don't attempt to [close] when the app still needs the [run] function.
  Future<void> close();
}
