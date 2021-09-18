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

Let's assume we want to stringify objects to `String` using `JSON.stringify`.
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

## Web Worker Setup
In order for `JsIsolatedWorker` to run properly on Flutter web, there needs to be a single `worker.js` file in the `web` folder. You can download it [here](https://github.com/iandis/isolated_worker/blob/master/web/worker.js) and put it in your `web` folder like below
```
...
web /
    index.html
    worker.js
    ...
```