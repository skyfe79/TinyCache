import XCTest
@testable import TinyCache

final class TinyCacheTests: XCTestCase {
    var tinyCache: TinyCache<String, String>!

    override func setUp() {
        super.setUp()
        tinyCache = TinyCache(policy: TinyCachePolicy.default)
    }

    override func tearDown() {
        tinyCache = nil
        super.tearDown()
    }

    func testSetAndGet() {
        tinyCache.set(value: "TestValue", forKey: "TestKey")
        let value = tinyCache.value(forKey: "TestKey")
        XCTAssertEqual(value, "TestValue", "Value set and retrieved should be equal")
    }

    func testRemoveValue() {
        tinyCache.set(value: "TestValue", forKey: "TestKey")
        tinyCache.removeValue(forKey: "TestKey")
        let value = tinyCache.value(forKey: "TestKey")
        XCTAssertNil(value, "Value should be nil after removal")
    }

    func testClearCache() {
        tinyCache.set(value: "TestValue1", forKey: "TestKey1")
        tinyCache.set(value: "TestValue2", forKey: "TestKey2")
        tinyCache.clear()
        XCTAssertNil(tinyCache.value(forKey: "TestKey1"), "Cache should be empty after clear")
        XCTAssertNil(tinyCache.value(forKey: "TestKey2"), "Cache should be empty after clear")
    }

    func testEvictHandlerIsCalled() {
        let expectation = self.expectation(description: "Evict handler is called upon eviction")
        tinyCache.cacheWillEvictValue = { key, value in
            XCTAssertEqual(key, "TestKey", "Evicted key should match the set key")
            XCTAssertEqual(value, "TestValue", "Evicted value should match the set value")
            expectation.fulfill()
        }

        tinyCache.set(value: "TestValue", forKey: "TestKey", cost: 1)
        tinyCache.removeValue(forKey: "TestKey")

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error, "Evict handler should be called upon eviction")
        }
    }

    func testSubscript() {
        tinyCache["TestKey"] = "TestValue"
        XCTAssertEqual(tinyCache["TestKey"], "TestValue", "Subscript set and get should work")
        tinyCache["TestKey"] = nil
        XCTAssertNil(tinyCache["TestKey"], "Value should be nil after setting nil via subscript")
    }

    func testSetAndGetWithSpecialCharactersKey() {
        let specialKey = "!@#$%^&*()"
        tinyCache.set(value: "SpecialValue", forKey: specialKey)
        let value = tinyCache.value(forKey: specialKey)
        XCTAssertEqual(value, "SpecialValue", "Value set and retrieved with special characters key should be equal")
    }

    func testSetAndGetWithEmptyKey() {
        let emptyKey = ""
        tinyCache.set(value: "EmptyKeyValue", forKey: emptyKey)
        let value = tinyCache.value(forKey: emptyKey)
        XCTAssertEqual(value, "EmptyKeyValue", "Value set and retrieved with empty key should be equal")
    }

    func testSetAndGetWithLargeData() {
        let largeKey = "LargeDataKey"
        let largeValue = String(repeating: "a", count: 10000) // 10KB of data
        tinyCache.set(value: largeValue, forKey: largeKey)
        let value = tinyCache.value(forKey: largeKey)
        XCTAssertEqual(value, largeValue, "Value set and retrieved with large data should be equal")
    }

    func testPerformanceOfSetAndGet() {
        measure {
            for i in 0..<10000 {
                let key = "PerfKey\(i)"
                let value = "PerfValue\(i)"
                tinyCache.set(value: value, forKey: key)
                _ = tinyCache.value(forKey: key)
            }
        }
    }
}