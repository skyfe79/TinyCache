@testable import TinyCache
import XCTest

final class CacheKeyTests: XCTestCase {
  func testCacheKeyHashValue() {
    let key1 = "TestKey1"
    let key2 = "TestKey2"
    let cacheKey1 = CacheKey(key1)
    let cacheKey2 = CacheKey(key2)
    let cacheKey1Duplicate = CacheKey(key1)

    XCTAssertNotEqual(cacheKey1.hash, cacheKey2.hash, "Different keys should have different hash values.")
    XCTAssertEqual(cacheKey1.hash, cacheKey1Duplicate.hash, "Identical keys should have the same hash value.")
  }

  func testCacheKeyEquality() {
    let key1 = "TestKey1"
    let key2 = "TestKey2"
    let cacheKey1 = CacheKey(key1)
    let cacheKey2 = CacheKey(key2)
    let cacheKey1Duplicate = CacheKey(key1)

    XCTAssertFalse(cacheKey1.isEqual(cacheKey2), "Different keys should not be equal.")
    XCTAssertTrue(cacheKey1.isEqual(cacheKey1Duplicate), "Identical keys should be equal.")
  }

  func testCacheKeyWithEmptyString() {
    let key = ""
    let cacheKey = CacheKey(key)

    XCTAssertEqual(cacheKey.hash, key.hashValue, "CacheKey with an empty string should have a hash value equal to the hash value of an empty string.")
    XCTAssertTrue(cacheKey.isEqual(CacheKey("")), "CacheKey instances with identical (empty) keys should be equal.")
  }

  func testCacheKeyWithSpecialCharacters() {
    let key = "!@#$%^&*()"
    let cacheKey = CacheKey(key)

    XCTAssertEqual(cacheKey.hash, key.hashValue, "CacheKey with special characters should have a hash value equal to the hash value of the key with special characters.")
    XCTAssertTrue(cacheKey.isEqual(CacheKey("!@#$%^&*()")), "CacheKey instances with identical keys containing special characters should be equal.")
  }

  func testCacheKeyUniqueness() {
    let key1 = "uniqueKey1"
    let key2 = "uniqueKey2"
    let cacheKey1 = CacheKey(key1)
    let cacheKey2 = CacheKey(key2)

    XCTAssertNotEqual(cacheKey1.hash, cacheKey2.hash, "CacheKeys with different keys should have different hash values.")
    XCTAssertFalse(cacheKey1.isEqual(cacheKey2), "CacheKeys with different keys should not be equal.")
  }
}
