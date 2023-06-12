import 'dart:developer' as dev;

import 'package:isolated_worker/isolated_worker.dart';

void tryPrint(void _) {
  dev.log('Hello from IsolatedWorker');
}

void main() {
  IsolatedWorker().run(tryPrint, null).then((_) => IsolatedWorker().close());
}
