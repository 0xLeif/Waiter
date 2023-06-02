//
//  Waitable.swift
//  
//
//  Created by Leif on 6/1/23.
//

import Foundation

public protocol Waitable {
    /**
     Waits asynchronously for the value of the specified key path to satisfy the provided condition.

     - Parameters:
         - `on`: The object to wait on.
         - `for`: The key path of the value to wait for.
         - `duration`: The maximum amount of time to wait for the value to change.
         - `interval`: The interval at which to check the value.
         - `expecting`: The closure that determines whether the value satisfies the condition.

     - Returns: The value of the key path once it satisfies the condition.

     - Throws: An error if the wait times out.
     */
    @discardableResult
    func wait<Object: AnyObject, Value>(
        on object: Object,
        for keyPath: KeyPath<Object, Value>,
        duration: TimeInterval,
        interval: TimeInterval,
        expecting: @escaping (Value) -> Bool
    ) async throws -> Value

    /**
     Waits asynchronously for the value of the specified key path to become equal to the provided value.

     - Parameters:
         - `on`: The object to wait on.
         - `for`: The key path of the value to wait for.
         - `duration`: The maximum amount of time to wait for the value to change.
         - `interval`: The interval at which to check the value.
         - `expecting`: The expected value to wait for.

     - Returns: The value of the key path once it becomes equal to the provided value.

     - Throws: An error if the wait times out.
     */
    @discardableResult
    func wait<Object: AnyObject, Value: Equatable>(
        on object: Object,
        for keyPath: KeyPath<Object, Value>,
        duration: TimeInterval,
        interval: TimeInterval,
        expecting: Value
    ) async throws -> Value
}

extension Waitable {
    /**
     Waits asynchronously for the value of the specified key path to satisfy the provided condition.

     - Parameters:
         - `on`: The object to wait on.
         - `for`: The key path of the value to wait for.
         - `duration`: The maximum amount of time to wait for the value to change.
         - `interval`: The interval at which to check the value.
         - `expecting`: The closure that determines whether the value satisfies the condition.

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
        try await Waiter.wait(
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
         - `on`: The object to wait on.
         - `for`: The key path of the value to wait for.
         - `duration`: The maximum amount of time to wait for the value to change.
         - `interval`: The interval at which to check the value.
         - `expecting`: The expected value to wait for.

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
        try await Waiter.wait(
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
}
