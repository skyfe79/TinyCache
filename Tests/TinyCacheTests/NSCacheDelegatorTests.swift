@testable import TinyCache
import XCTest

final class NSCacheDelegatorTests: XCTestCase {
  func testWillEvictObjectClosureIsCalled() {
    let expectation = self.expectation(description: "willEvictObject closure is called")
    var evictedObject: Any?

    let delegator = NSCacheDelegator { obj in
      evictedObject = obj
      expectation.fulfill()
    }

    let cache = NSCache<AnyObject, AnyObject>()
    cache.delegate = delegator

    let key = "TestKey" as AnyObject
    let object = "TestObject" as AnyObject
    cache.setObject(object, forKey: key)
    cache.removeObject(forKey: key)

    waitForExpectations(timeout: 1) { _ in
      XCTAssertNotNil(evictedObject, "Evicted object should not be nil")
    }
  }
}
