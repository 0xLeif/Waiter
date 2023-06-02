import XCTest
@testable import Waiter

final class WaiterTests: XCTestCase, Waitable {
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
            duration: 2,
            interval: 0.5,
            expecting: 1
        )

        XCTAssertEqual(value.count, 1)
    }
}
