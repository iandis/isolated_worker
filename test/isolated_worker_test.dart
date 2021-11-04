import 'package:isolated_worker/isolated_worker.dart';
import 'package:isolated_worker/worker_delegator.dart';
import 'package:test/test.dart';

List<int> isolatedWork(int number) {
  return List<int>.generate(number, (index) => index + 1);
}

void main() {
  tearDownAll(() {
    IsolatedWorker().close();
  });

  group('Test [IsolatedWorker]\n', () {
    test(
        'Verify [isolatedWork] running with [IsolatedWorker]\n'
        'returns a List of integers containing 1 to 9', () {
      expectLater(
        IsolatedWorker().run(isolatedWork, 9).then(
          (value) {
            expect(value, isA<List<int>>());

            expect(
              value,
              containsAllInOrder(Iterable.generate(9, (n) => n + 1)),
            );
          },
        ),
        completes,
      );
    });

    test(
        'Verify 2 [isolatedWork]s running with [IsolatedWorker]\n'
        'returns 2 Lists of integers containing the expected numbers',
        () async {
      final Future<List<int>> result1 = IsolatedWorker().run(isolatedWork, 10);
      final Future<List<int>> result2 = IsolatedWorker().run(isolatedWork, 15);
      result1.then((value) {
        expect(value, isA<List<int>>());

        expect(
          value,
          containsAllInOrder(Iterable.generate(10, (n) => n + 1)),
        );
      });

      result2.then((value) {
        expect(value, isA<List<int>>());

        expect(
          value,
          containsAllInOrder(Iterable.generate(15, (n) => n + 1)),
        );
      });
    });

    test(
        'Verify 4 [isolatedWork]s running with [IsolatedWorker]\n'
        'returns 4 Lists of integers containing the expected numbers',
        () async {
      final Future<List<int>> result1 = IsolatedWorker().run(isolatedWork, 10);
      final Future<List<int>> result2 = IsolatedWorker().run(isolatedWork, 15);
      final Future<List<int>> result3 = IsolatedWorker().run(isolatedWork, 20);
      final Future<List<int>> result4 = IsolatedWorker().run(isolatedWork, 25);
      result1.then((value) {
        expect(value, isA<List<int>>());

        expect(
          value,
          containsAllInOrder(Iterable.generate(10, (n) => n + 1)),
        );
      });

      result2.then((value) {
        expect(value, isA<List<int>>());

        expect(
          value,
          containsAllInOrder(Iterable.generate(15, (n) => n + 1)),
        );
      });

      result3.then((value) {
        expect(value, isA<List<int>>());

        expect(
          value,
          containsAllInOrder(Iterable.generate(20, (n) => n + 1)),
        );
      });

      result4.then((value) {
        expect(value, isA<List<int>>());

        expect(
          value,
          containsAllInOrder(Iterable.generate(25, (n) => n + 1)),
        );
      });
    });
  });

  group('Test [WorkerDelegator] on Dart VM\n', () {
    setUpAll(() {
      const JsDelegate dummyJsDelegate = JsDelegate(callback: 'callback');

      const DefaultDelegate<int, List<int>> dummyDefDelegate =
          DefaultDelegate<int, List<int>>(callback: isolatedWork);

      const WorkerDelegate<int, List<int>> dummyWorkerDelegate =
          WorkerDelegate<int, List<int>>(
        key: 'dummy1to9',
        defaultDelegate: dummyDefDelegate,
        jsDelegate: dummyJsDelegate,
      );

      WorkerDelegator().addDelegate(dummyWorkerDelegate);
    });

    test(
        'Verify [isolatedWork] running with [WorkerDelegator]\n'
        'returns a List of integers containing 1 to 9\n', () {
      expectLater(
        WorkerDelegator().run<int, List<int>>('dummy1to9', 9).then(
          (value) {
            expect(value, isA<List<int>>());

            expect(
              value,
              containsAllInOrder(Iterable.generate(9, (n) => n + 1)),
            );
          },
        ),
        completes,
      );
    });
  });
}
