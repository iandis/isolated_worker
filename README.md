A singleton isolated worker for all platforms. On most platforms, it uses Flutter's `Isolate`, except on the web, since `Isolate` is not available, it uses `Worker` instead.

## Features

*   💙  Easy to use*
*   👬  Identical syntax to the `compute` function provided by Flutter*
*   🚫  Not a one-off worker
*   🌐  Available on web**


*except on web
**by using `JsIsolatedWorker`

## Usage

### Basic example
```dart
int doSomeHeavyCalculation(int count) {
    // ...
}
void main() {
    // if using compute function:
    // compute(doSomeHeavyCalculation, 1000);
    IsolatedWorker().run(doSomeHeavyCalculation, 1000);
}
``` 
If we want to do some heavy work that does not need any arguments and/or return values.
```dart
// WRONG
void doSomethingHeavy() {
    // ...
}

// CORRECT
void doSomethingHeavy(void _) {
    // ...
}

void main() {
    IsolatedWorker().run(doSomethingHeavy, null);
}

```

### Web example
We can utilize the `JsIsolatedWorker` for spawning a web worker. However, it cannot use Dart closures as messages to the worker because of some limitations (I have tried using `JSONfn` and `allowInterop` but no luck).
Instead we need to use native JS closures. In order to do this, we can utilize existing JS APIs or by importing external libraries/files.

Let's assume we want to stringify objects using `JSON.stringify`.
```dart
void main() {
    JsIsolatedWorker().run(
        functionName: ['JSON', 'stringify'],
        arguments: {},
        // optional argument, in case web worker is not available.
        fallback: () {
            return '{}';
        },
    ).then(print);
    // prints "{}"
}
```
Now let's assume we have external js libraries/files that we want the worker to use.
```dart
void main() async {
    // import the scripts first
    // and check if web worker is available
    final bool loaded = await JsIsolatedWorker().importScripts(['myModule1.js']);
    // web worker is available
    if(loaded) {
        print(await JsIsolatedWorker().run(
            functionName: 'myFunction1',
            arguments: 'Hello from Dart :)',
        ));
    }else{
        print('Web worker is not available :(');
    }
}
```
## Shared Platform Worker
There might be a case where we need to use both `IsolatedWorker` and `JsIsolatedWorker`. There are many ways to go about it. We can use conditional import, dependency injections, or `WorkerDelegator`.
### WorkerDelegator
For example, we have a `foo` Dart method that returns a list of numbers from 1 to **count**.
```dart
List<int> foo(int count) {
    List<int> result = <int>[];
    for(int i = 1; i <= count; i++) {
        result.add(i);
    }
    return result;
}
```
And a JS file `foo.js` containing a `foo` JS method that does the same thing.
```js
function foo(count) {
    let result = [];
    for(let i = 1; i <= count; i++) {
        result.push(i);
    }
    return result;
}
```
To call these methods using `WorkerDelegator`, we need to create a `DefaultDelegate`, `JsDelegate`, and `WorkerDelegate` first. Then register the `WorkerDelegate` to our `WorkerDelegator`.
```dart
Future<void> main() async {
    const DefaultDelegate<int, List<int>> fooDelegate = 
        DefaultDelegate(callback: foo);
    
    const JsDelegate fooJsDelegate = JsDelegate(callback: 'foo');

    const WorkerDelegate<int, List<int>> workerDelegate = 
        WorkerDelegate(
            key: 'foo',
            defaultDelegate: fooDelegate,
            jsDelegate: fooJsDelegate,
        );
    
    WorkerDelegator().addDelegate(workerDelegate);

    // Don't forget to call importScripts for our "foo" js method.
    await WorkerDelegator().importScripts(const <String>['foo.js']);
}
```
After registering our `WorkerDelegate`, we just need to call it using its `key` "foo".
```dart
...
print(await WorkerDelegator().run('foo', 9));
...
```
The `key` can be anything except `null`.
```dart
enum DelegateKeys { foo, bar }
const WorkerDelegate<int, List<int>> workerDelegate = 
    WorkerDelegate(
        key: DelegateKeys.foo,
        defaultDelegate: fooDelegate,
        jsDelegate: fooJsDelegate,
    );
```
Notes: `WorkerDelegator()` is a singleton. If we need to create a new instance, we can create one using 
```dart
WorkerDelegator.asNewInstance(
    delegates: /* pass our WorkerDelegates here. OPTIONAL. */
);
```
## Web Worker Setup
In order for `JsIsolatedWorker` to run properly on Flutter web, there needs to be a single `worker.js` file in the `web` folder. You can download it [here](https://github.com/iandis/isolated_worker/blob/master/web/worker.js) and put it in your `web` folder like below
```
...
web /
    index.html
    worker.js
    ...
```

## Examples
*   [Fetch](https://github.com/iandis/flutter_isolated_worker_fetch_example) - an example of how to get response from a URL using `IsolatedWorker` and `JsIsolatedWorker`