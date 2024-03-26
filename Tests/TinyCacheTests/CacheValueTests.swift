import XCTest
@testable import TinyCache

final class CacheValueTests: XCTestCase {
    func testCacheValueInitialization() {
        let key = "TestKey"
        let value = "TestValue"
        let cacheValue = CacheValue(value, forKey: key)
        
        XCTAssertEqual(cacheValue.key, key, "CacheValue key should match the initialization key.")
        XCTAssertEqual(cacheValue.value, value, "CacheValue value should match the initialization value.")
    }

    func testCacheValueWithEmptyKey() {
        let key = ""
        let value = "TestValue"
        let cacheValue = CacheValue(value, forKey: key)
        
        XCTAssertEqual(cacheValue.key, key, "CacheValue key should be able to be empty.")
        XCTAssertEqual(cacheValue.value, value, "CacheValue value should match the initialization value.")
    }
    
    func testCacheValueWithNilValue() {
        let key = "TestKey"
        let value: String? = nil
        let cacheValue = CacheValue(value, forKey: key)
        
        XCTAssertEqual(cacheValue.key, key, "CacheValue key should match the initialization key.")
        XCTAssertNil(cacheValue.value, "CacheValue value should be able to be nil.")
    }
    
    func testCacheValueWithEmptyValue() {
        let key = "TestKey"
        let value = ""
        let cacheValue = CacheValue(value, forKey: key)
        
        XCTAssertEqual(cacheValue.key, key, "CacheValue key should match the initialization key.")
        XCTAssertEqual(cacheValue.value, value, "CacheValue value should be able to be empty.")
    }
}
