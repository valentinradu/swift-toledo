@testable import Injectable
import XCTest

final class InjectableTests: XCTestCase {
    func testBasic() async throws {
        let container = SharedContainer()

        let b1 = B(with: container)
        let b2 = B(with: container)

        XCTAssertEqual(b1.a.id, b2.a.id)
    }
}
