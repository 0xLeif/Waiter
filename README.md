# Waiter

⌛ *Asynchronous Waiting Made Easy*

Waiter is a Swift library that provides convenient global functions for asynchronous waiting. It allows you to wait for values to satisfy specific conditions or become equal to expected values. Additionally, Waiter includes a Waitable protocol that you can adopt in your own types to enable waiting functionality.

## Usage

### Example

```swift
import Waiter

class Counter {
    var value: Int = 0
}

let counter = Counter()

Task {
    // Asynchronously increment the counter after a delay
    await Task.sleep(1)
    counter.value += 1
}

do {
    // Wait for the counter value to become equal to 1
    let finalValue = try await wait(
        on: counter,
        for: \.value,
        expecting: 1
    )

    print("Counter value: \(finalValue)") // Output: Counter value: 1
} catch {
    print("Timeout Error: \(error)")
}
```

### Wait for a Value to Satisfy a Condition

To wait for a value of a specified key path to satisfy a condition, use the global `wait` function:

```swift
@discardableResult
public func wait<Object: AnyObject, Value>(
    on object: Object,
    for keyPath: KeyPath<Object, Value>,
    duration: TimeInterval = 3,
    interval: TimeInterval = 0.1,
    expecting: @escaping (Value) -> Bool
) async throws -> Value
```

- object: The object to wait on.
- keyPath: The key path of the value to wait for.
- duration: The maximum amount of time to wait for the value to change (default: 3 seconds).
- interval: The interval at which to check the value (default: 0.1 seconds).
- expecting: A closure that determines whether the value satisfies the condition.

### Wait for a Value to Become Equal to a Specific Value

To wait for a value of a specified key path to become equal to a specific value, use the global `wait` function:

```swift
@discardableResult
public func wait<Object: AnyObject, Value: Equatable>(
	on object: Object,
	for keyPath: KeyPath<Object, Value>,
	duration: TimeInterval = 3,
	interval: TimeInterval = 0.1,
	expecting: Value
) async throws -> Value
```

- object: The object to wait on.
- keyPath: The key path of the value to wait for.
- duration: The maximum amount of time to wait for the value to change (default: 3 seconds).
- interval: The interval at which to check the value (default: 0.1 seconds).
- expecting: The expected value to wait for.

### Implementing Waitable Protocol

You can make your own types waitable by adopting the `Waitable` protocol. The protocol provides two default implementations for the wait functions, allowing you to use them directly or customize them based on your needs.

### Testing with XCTest

Waiter seamlessly integrates with XCTest, allowing you to test asynchronous behavior. Here's an example of a test case using Waiter:

```swift
import Waiter
import XCTest
@testable import YourProject

final class YourTests: XCTestCase, Waitable {
    func testYourFunctionality() async throws {
        // Test setup

        // Perform asynchronous operations

        // Wait for a value to satisfy a condition
        try await wait(on: object, for: keyPath, expecting: expectedValue)

        // Assertions and test verification
    }
}
```

### Error Handling

The `wait` function can throw errors if the wait times out. If an error occurs, it means the wait duration exceeded the specified timeout and the condition was not satisfied within the given time frame. You can handle the error by displaying an appropriate message, retrying the operation, or taking any other desired action.
