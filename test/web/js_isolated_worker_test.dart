import 'dart:collection';

import 'package:isolated_worker/js_isolated_worker.dart';
import 'package:isolated_worker/worker_delegator.dart';
import 'package:test/test.dart';

void main() {
  tearDownAll(() {
    JsIsolatedWorker().close();
  });
  group('Test [JsIsolatedWorker]\n', () {
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

    const String targetUrl =
        "https://jsonplaceholder.typicode.com/posts/1/comments";

    test(
        'Verify user-defined JS function [get] returns JSArray\n'
        'when fetching $targetUrl\n'
        'while running on [JsIsolatedWorker]', () async {
      await JsIsolatedWorker().importScripts(['user_defined_js_fn.js']);
      expectLater(
        JsIsolatedWorker().run(functionName: 'get', arguments: targetUrl).then(
          (dynamic responseData) {
            expect(responseData, isA<List>());
            expect(responseData.length, equals(5));
            expect(responseData[0], isA<LinkedHashMap>());
            expect(responseData[0]['email'], equals('Eliseo@gardner.biz'));
          },
        ),
        completes,
      );
    });
  });

  group('Test [WorkerDelegator] on Web\n', () {
    setUpAll(() {
      const JsDelegate dummyJsDelegate = JsDelegate(
        callback: ['JSON', 'stringify'],
      );

      final DefaultDelegate<String, Object> dummyDefDelegate = DefaultDelegate(
        callback: (String a) => '',
      );

      final WorkerDelegate dummyWorkerDelegate = WorkerDelegate(
        key: 'dummyJsonStringify',
        defaultDelegate: dummyDefDelegate,
        jsDelegate: dummyJsDelegate,
      );

      WorkerDelegator().addDelegate(dummyWorkerDelegate);
    });

    test(
        'Verify [JSON.stringify] returns "{}"\n'
        'when running on [WorkerDelegator]', () {
      expectLater(
        WorkerDelegator().run(
          'dummyJsonStringify',
          {},
        ).then((dynamic jsonString) {
          expect(jsonString, isA<String>());
          expect(jsonString, equals('{}'));
        }),
        completes,
      );
    });
  });
}
