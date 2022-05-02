@testable import Toledo
import XCTest

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

    func testReplaceProvider() async throws {
        let container = SharedContainer()
        let uuid = UUID(uuidString: "93c92553-df0b-473a-80fa-5892675cd27b")!
        
        container.replaceProvider(ADependencyProviderKey.self) { _ in
            A(id: uuid)
        }
        
        let b = B(with: container)
        
        XCTAssertEqual(b.a.id, uuid)
    }

    func testConcurrency() async throws {
        let container = SharedContainer()

        let result = try await withThrowingTaskGroup(of: UUID.self, returning: [UUID].self) { group in
            for _ in 0 ..< 5 {
                group.addTask {
                    let instance1 = try await container.longLastingAsyncInit()
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

    func testMultithreadedAccess() async throws {
        let container = SharedContainer()

        let group = DispatchGroup()
        let sem = DispatchSemaphore(value: 1)
        let concurrentQueue = DispatchQueue(label: "test.queue",
                                            attributes: .concurrent)

        let uuids: Ref<[UUID]> = Ref([])

        concurrentQueue.async(group: group) {
            let uuid = container.longLastingSyncInit()
            sem.wait()
            defer { sem.signal() }
            uuids.ref.append(uuid.id)
        }

        concurrentQueue.async(group: group) {
            let uuid = container.longLastingSyncInit()
            sem.wait()
            defer { sem.signal() }
            uuids.ref.append(uuid.id)
        }

        group.wait()

        let first = uuids.ref[0]
        XCTAssertTrue(uuids.ref.allSatisfy { $0 == first })
    }
}
