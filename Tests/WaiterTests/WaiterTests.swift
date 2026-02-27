import XCTest
@testable import Waiter

final class WaiterTests: XCTestCase, Waitable, @unchecked Sendable {
    var testWaitValue: Void = ()

    func testWaitTimeout() async {
        let expectedError: Error = Waiter.WaitError.timeout(0)

        do {
            try await wait(
                for: \.testWaitValue,
                duration: 0,
                expecting: { false }
            )

            XCTFail()
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                expectedError.localizedDescription
            )
        }
    }

    func testWaiter() async throws {
        class Value: @unchecked Sendable {
            var count = 0
        }

        let value = Value()

        try await wait(
            on: value,
            for: \.count,
            expecting: 0
        )

        XCTAssertEqual(value.count, 0)

        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            value.count += 1
        }

        XCTAssertEqual(value.count, 0)

        try await wait(
            on: value,
            for: \.count,
            expecting: { count in
                count == 1
            }
        )

        XCTAssertEqual(value.count, 1)
    }

    func testWaitable() async throws {
        class Value: Waitable, @unchecked Sendable {
            var count = 0
        }

        let value = Value()

        try await value.wait(
            for: \.count,
            expecting: 0
        )

        XCTAssertEqual(value.count, 0)

        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            value.count += 1
        }

        XCTAssertEqual(value.count, 0)

        try await value.wait(
            for: \.count,
            expecting: { count in
                count == 1
            }
        )

        XCTAssertEqual(value.count, 1)
    }

    // MARK: - WaitError Tests

    func testWaitErrorDescription() {
        let error = WaitError.timeout(5.0)
        XCTAssertEqual(
            error.errorDescription,
            "Wait Timeout: Exceeded duration of 5.0 seconds."
        )
    }

    func testWaitErrorDescriptionZeroDuration() {
        let error = WaitError.timeout(0)
        XCTAssertEqual(
            error.errorDescription,
            "Wait Timeout: Exceeded duration of 0.0 seconds."
        )
    }

    // MARK: - Free Function Timeout Tests

    func testFreeWaitClosureTimeout() async {
        class Value: @unchecked Sendable {
            var flag = false
        }
        let value = Value()

        do {
            try await Waiter.wait(
                on: value,
                for: \.flag,
                duration: 0.3,
                interval: 0.1,
                expecting: { $0 == true }
            )
            XCTFail("Expected timeout error")
        } catch {
            if let waitError = error as? WaitError, case .timeout(let duration) = waitError {
                XCTAssertEqual(duration, 0.3)
            } else {
                XCTFail("Expected WaitError.timeout(0.3), but got \(error)")
            }
        }
    }

    func testFreeWaitEquatableTimeout() async {
        class Value: @unchecked Sendable {
            var count = 0
        }
        let value = Value()

        do {
            try await Waiter.wait(
                on: value,
                for: \.count,
                duration: 0.3,
                interval: 0.1,
                expecting: 99
            )
            XCTFail("Expected timeout error")
        } catch {
            if let waitError = error as? WaitError, case .timeout(let duration) = waitError {
                XCTAssertEqual(duration, 0.3)
            } else {
                XCTFail("Expected WaitError.timeout(0.3), but got \(error)")
            }
        }
    }

    // MARK: - Immediate Success Tests

    func testImmediateSuccessClosure() async throws {
        class Value: @unchecked Sendable {
            var name = "ready"
        }
        let value = Value()

        let result = try await Waiter.wait(
            on: value,
            for: \.name,
            duration: 1,
            interval: 0.1,
            expecting: { $0 == "ready" }
        )

        XCTAssertEqual(result, "ready")
    }

    func testImmediateSuccessEquatable() async throws {
        class Value: @unchecked Sendable {
            var count = 42
        }
        let value = Value()

        let result = try await Waiter.wait(
            on: value,
            for: \.count,
            duration: 1,
            interval: 0.1,
            expecting: 42
        )

        XCTAssertEqual(result, 42)
    }

    // MARK: - Negative Duration and Interval Tests

    func testNegativeDurationUsesAbsoluteValue() async {
        class Value: @unchecked Sendable {
            var flag = false
        }
        let value = Value()

        do {
            try await Waiter.wait(
                on: value,
                for: \.flag,
                duration: -0.3,
                interval: 0.1,
                expecting: true
            )
            XCTFail("Expected timeout error")
        } catch {
            // Should timeout at abs(-0.3) = 0.3 seconds
            if let waitError = error as? WaitError, case .timeout(let duration) = waitError {
                XCTAssertEqual(duration, 0.3)
            } else {
                XCTFail("Expected WaitError.timeout(0.3), but got \(error)")
            }
        }
    }

    func testNegativeIntervalUsesAbsoluteValue() async throws {
        class Value: @unchecked Sendable {
            var count = 5
        }
        let value = Value()

        // Negative interval should still work (abs applied)
        let result = try await Waiter.wait(
            on: value,
            for: \.count,
            duration: 1,
            interval: -0.1,
            expecting: 5
        )

        XCTAssertEqual(result, 5)
    }

    // MARK: - Custom Interval Tests

    func testCustomIntervalTiming() async throws {
        class Value: @unchecked Sendable {
            var count = 0
        }
        let value = Value()

        Task {
            try await Task.sleep(nanoseconds: 200_000_000)
            value.count = 1
        }

        let result = try await Waiter.wait(
            on: value,
            for: \.count,
            duration: 2,
            interval: 0.05,
            expecting: 1
        )

        XCTAssertEqual(result, 1)
    }

    // MARK: - Waitable Protocol wait(on:for:) Tests

    func testWaitableOnExternalObjectClosure() async throws {
        class Observer: Waitable {}
        class Target: @unchecked Sendable {
            var status = "pending"
        }

        let observer = Observer()
        let target = Target()

        Task {
            try await Task.sleep(nanoseconds: 200_000_000)
            target.status = "done"
        }

        let result = try await observer.wait(
            on: target,
            for: \.status,
            duration: 2,
            interval: 0.1,
            expecting: { $0 == "done" }
        )

        XCTAssertEqual(result, "done")
    }

    func testWaitableOnExternalObjectEquatable() async throws {
        class Observer: Waitable {}
        class Target: @unchecked Sendable {
            var value = 0
        }

        let observer = Observer()
        let target = Target()

        Task {
            try await Task.sleep(nanoseconds: 200_000_000)
            target.value = 10
        }

        let result = try await observer.wait(
            on: target,
            for: \.value,
            duration: 2,
            interval: 0.1,
            expecting: 10
        )

        XCTAssertEqual(result, 10)
    }

    func testWaitableOnExternalObjectTimeout() async {
        class Observer: Waitable {}
        class Target: @unchecked Sendable {
            var value = 0
        }

        let observer = Observer()
        let target = Target()

        do {
            try await observer.wait(
                on: target,
                for: \.value,
                duration: 0.3,
                interval: 0.1,
                expecting: 999
            )
            XCTFail("Expected timeout error")
        } catch {
            if let waitError = error as? WaitError, case .timeout(let duration) = waitError {
                XCTAssertEqual(duration, 0.3)
            } else {
                XCTFail("Expected WaitError.timeout(0.3), but got \(error)")
            }
        }
    }

    // MARK: - Waitable Self (AnyObject) Default Parameter Tests

    func testWaitableSelfDefaultDurationAndInterval() async throws {
        class Value: Waitable, @unchecked Sendable {
            var ready = true
        }
        let value = Value()

        // Uses default duration (3) and interval (0.1)
        let result = try await value.wait(
            for: \.ready,
            expecting: true
        )

        XCTAssertTrue(result)
    }

    func testWaitableSelfClosureDefaultParameters() async throws {
        class Value: Waitable, @unchecked Sendable {
            var text = "hello"
        }
        let value = Value()

        // Uses default duration and interval
        let result = try await value.wait(
            for: \.text,
            expecting: { $0.count == 5 }
        )

        XCTAssertEqual(result, "hello")
    }

    // MARK: - Multiple Value Changes Test

    func testWaitThroughMultipleValueChanges() async throws {
        class Value: @unchecked Sendable {
            var step = 0
        }
        let value = Value()

        Task {
            try await Task.sleep(nanoseconds: 100_000_000)
            value.step = 1
            try await Task.sleep(nanoseconds: 100_000_000)
            value.step = 2
            try await Task.sleep(nanoseconds: 100_000_000)
            value.step = 3
        }

        let result = try await Waiter.wait(
            on: value,
            for: \.step,
            duration: 3,
            interval: 0.05,
            expecting: 3
        )

        XCTAssertEqual(result, 3)
    }

    // MARK: - Boolean Value Tests

    func testWaitForBooleanToggle() async throws {
        class Value: @unchecked Sendable {
            var isComplete = false
        }
        let value = Value()

        Task {
            try await Task.sleep(nanoseconds: 200_000_000)
            value.isComplete = true
        }

        let result = try await Waiter.wait(
            on: value,
            for: \.isComplete,
            duration: 2,
            interval: 0.1,
            expecting: true
        )

        XCTAssertTrue(result)
    }

    // MARK: - Optional Value Tests

    func testWaitForOptionalValueToBeSet() async throws {
        class Value: @unchecked Sendable {
            var name: String? = nil
        }
        let value = Value()

        Task {
            try await Task.sleep(nanoseconds: 200_000_000)
            value.name = "test"
        }

        let result = try await Waiter.wait(
            on: value,
            for: \.name,
            duration: 2,
            interval: 0.1,
            expecting: { $0 != nil }
        )

        XCTAssertEqual(result, "test")
    }

    func testWaitForOptionalValueEquatable() async throws {
        class Value: @unchecked Sendable {
            var name: String? = nil
        }
        let value = Value()

        Task {
            try await Task.sleep(nanoseconds: 200_000_000)
            value.name = "expected"
        }

        let result: String? = try await Waiter.wait(
            on: value,
            for: \.name,
            duration: 2,
            interval: 0.1,
            expecting: "expected"
        )

        XCTAssertEqual(result, "expected")
    }

    // MARK: - Task Cancellation Test

    func testWaitRespectsTaskCancellation() async {
        class Value: @unchecked Sendable {
            var count = 0
        }
        let value = Value()

        let task = Task {
            try await Waiter.wait(
                on: value,
                for: \.count,
                duration: 10,
                interval: 0.1,
                expecting: 999
            )
        }

        // Cancel the task after a short delay
        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation error")
        } catch {
            // Task.sleep throws CancellationError when cancelled
            XCTAssertTrue(error is CancellationError)
        }
    }

    // MARK: - Discardable Result Test

    func testDiscardableResult() async throws {
        class Value: @unchecked Sendable {
            var count = 0
        }
        let value = Value()

        // Verify that the result can be discarded (no warning)
        try await Waiter.wait(
            on: value,
            for: \.count,
            duration: 1,
            interval: 0.1,
            expecting: 0
        )

        // If we reach here, the wait succeeded without needing the result
        XCTAssertEqual(value.count, 0)
    }
}
