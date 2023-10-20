import Foundation

// MARK: - Public

/**
 An error that is thrown when a wait operation times out.

 - Note: Conforms to the `LocalizedError` protocol for localized error messages.
 */
public enum WaitError: LocalizedError {
    /// The wait operation timed out before the condition was satisfied.
    case timeout(TimeInterval)

    /**
     The error message associated with the error.

     - Returns: The error message.
     */
    public var errorDescription: String? {
        switch self {
        case let .timeout(duration): return "Wait Timeout: Exceeded duration of \(duration) seconds."
        }
    }
}

/**
 Waits asynchronously for the value of the specified key path to satisfy the provided condition.

 - Parameters:
     - on: The object to wait on.
     - for: The key path of the value to wait for.
     - duration: The maximum amount of time to wait for the value to change.
     - interval: The interval at which to check the value.
     - expecting: The closure that determines whether the value satisfies the condition.

 - Returns: The value of the key path once it satisfies the condition.

 - Throws: An error if the wait times out.
 */
@discardableResult
public func wait<Object: AnyObject, Value>(
    on object: Object,
    for keyPath: KeyPath<Object, Value>,
    duration: TimeInterval = 3,
    interval: TimeInterval = 0.1,
    expecting: @escaping (Value) -> Bool
) async throws -> Value {
    try await wait(
        on: object,
        for: keyPath,
        interation: 0,
        duration: abs(duration),
        interval: abs(interval),
        expecting: expecting
    )
}

/**
 Waits asynchronously for the value of the specified key path to become equal to the provided value.

 - Parameters:
     - on: The object to wait on.
     - for: The key path of the value to wait for.
     - duration: The maximum amount of time to wait for the value to change.
     - interval: The interval at which to check the value.
     - expecting: The expected value to wait for.

 - Returns: The value of the key path once it becomes equal to the provided value.

 - Throws: An error if the wait times out.
 */
@discardableResult
public func wait<Object: AnyObject, Value: Equatable>(
    on object: Object,
    for keyPath: KeyPath<Object, Value>,
    duration: TimeInterval = 3,
    interval: TimeInterval = 0.1,
    expecting: Value
) async throws -> Value {
    try await wait(
        on: object,
        for: keyPath,
        interation: 0,
        duration: abs(duration),
        interval: abs(interval),
        expecting: { value in
            expecting == value
        }
    )
}

// MARK: - Internal

func wait<Object: AnyObject, Value>(
    on object: Object,
    for keyPath: KeyPath<Object, Value>,
    interation: UInt,
    duration: TimeInterval,
    interval: TimeInterval,
    expecting: @escaping (Value) -> Bool
) async throws -> Value {
    guard Double(interation) * interval < duration else {
        throw WaitError.timeout(duration)
    }

    let value = object[keyPath: keyPath]

    if expecting(value) {
        return value
    }

    try await Task.sleep(
        nanoseconds: UInt64(1_000_000_000 * abs(interval))
    )

    return try await wait(
        on: object,
        for: keyPath,
        interation: interation + 1,
        duration: duration,
        interval: interval,
        expecting: expecting
    )
}
