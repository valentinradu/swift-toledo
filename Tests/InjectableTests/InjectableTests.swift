import XCTest
@testable import Injectable

final class InjectableTests: XCTestCase {
    func testBasic() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let container = SharedContainer()
        
        let b1 = B(with: container)
        let b2 = B(with: container)
        
//        XCTAssertEqual(b1.a.id, b2.a.id)
    }
}
