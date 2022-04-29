@testable import Toledo
import XCTest

@MainActor
final class ToledoTests: XCTestCase {
    func testBasic() async throws {
        let container = SharedContainer()

        let b1 = B(with: container)
        let b2 = B(with: container)
        let c1 = try await C(with: container)

        XCTAssertEqual(b1.a.id, b2.a.id)
        XCTAssertEqual(b2.a.id, c1.a.id)
    }

    func testExternalEntity() async throws {
        let container = SharedContainer()
        // test passes if there is a musicDeviceGroupID
        // property on the container
        _ = container.musicDeviceGroupID()
    }

    func testConcurrency() async throws {
        let container = SharedContainer()

        let result = try await withThrowingTaskGroup(of: UUID.self, returning: [UUID].self) { group in
            for _ in 0 ..< 5 {
                group.addTask {
                    let instance1 = try await container.longLastingInit()
                    return instance1.id
                }
            }

            var uuids: [UUID] = []

            while let next = try await group.next() {
                uuids.append(next)
            }

            return uuids
        }

        let first = result[0]
        XCTAssertTrue(result.allSatisfy { $0 == first })
    }
}
