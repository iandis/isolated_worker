@JS()
library js_isolated_worker;

import 'package:js/js.dart' show JS;

@JS('CallbackObject')
class CallbackObject {
  external int id;

  /// `FutureOr<R> Function(Q message)`
  external Function callback;
}

@JS('CallbackMessage')
class CallbackMessage extends CallbackObject {
  /// `Q message`
  external dynamic message;
}

@JS('ResultMessage')
class ResultMessage extends CallbackObject {
  external dynamic result;
}

@JS('ResultErrorMessage')
class ResultErrorMessage extends CallbackObject {
  external Object error;
}
