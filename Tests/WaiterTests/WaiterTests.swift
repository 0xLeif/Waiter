import XCTest
@testable import Waiter

final class WaiterTests: XCTestCase, Waitable {
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
        class Value {
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
        class Value: Waitable {
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
}
