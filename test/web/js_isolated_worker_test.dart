import 'dart:collection';

import 'package:isolated_worker/js_isolated_worker.dart';
import 'package:test/test.dart';

void main() {
  group('Test [JsIsolatedWorker]\n', () {
    tearDownAll(() {
      JsIsolatedWorker().close();
    });

    test(
        'Verify [JSON.stringify] returns "{}"\n'
        'when running on [JsIsolatedWorker]', () {
      expectLater(
        JsIsolatedWorker().run(
          functionName: [
            'JSON',
            'stringify',
          ],
          arguments: {},
        ).then((dynamic jsonString) {
          expect(jsonString, isA<String>());
          expect(jsonString, equals('{}'));
        }),
        completes,
      );
    });

    test(
        'Verify [JSON.parse] returns {}\n'
        'when running on [JsIsolatedWorker]', () {
      expectLater(
        JsIsolatedWorker().run(
          functionName: [
            'JSON',
            'parse',
          ],
          arguments: '{}',
        ).then((dynamic jsonString) {
          expect(jsonString, isA<LinkedHashMap>());
          expect(jsonString, equals({}));
        }),
        completes,
      );
    });

    const String targetUrl = "https://jsonplaceholder.typicode.com/posts/1/comments";
    test(
        'Verify user-defined JS function [get] returns JSArray\n'
        'when fetching $targetUrl\n'
        'while running on [JsIsolatedWorker]', () async {
      await JsIsolatedWorker().importScripts(['user_defined_js_fn.js']);
      expectLater(
        JsIsolatedWorker().run(
          functionName: 'get',
          arguments: targetUrl,
        ).then((dynamic responseData) {
          expect(responseData, isA<List>());
          expect(responseData.length, equals(5));
          expect(responseData[0], isA<LinkedHashMap>());
          expect(responseData[0]['email'], equals('Eliseo@gardner.biz'));
        }),
        completes,
      );
    });
  });
}
