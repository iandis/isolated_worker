library isolated_worker;

export 'src/isolated_worker_default.dart'
  if(dart.library.html) 'src/isolated_worker_web.dart' show IsolatedWorker;
