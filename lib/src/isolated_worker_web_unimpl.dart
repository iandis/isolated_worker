import 'isolated_worker_web.dart';

class JsIsolatedWorkerImpl implements JsIsolatedWorker {
  factory JsIsolatedWorkerImpl() {
    throw UnimplementedError(
      'JsIsolatedWorker is not available on this platform',
    );
  }

  @override
  Future<void> close() {
    throw UnimplementedError(
      'JsIsolatedWorker is not available on this platform',
    );
  }

  @override
  Future<bool> importScripts(List<String> scripts) {
    throw UnimplementedError(
      'JsIsolatedWorker is not available on this platform',
    );
  }

  @override
  Future<dynamic> run({
    required dynamic functionName,
    required dynamic arguments,
    Future<dynamic> Function()? fallback,
  }) {
    throw UnimplementedError(
      'JsIsolatedWorker is not available on this platform',
    );
  }
}
