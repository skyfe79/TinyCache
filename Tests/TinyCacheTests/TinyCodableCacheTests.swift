@testable import TinyCache
import XCTest

final class TinyCodableCacheTests: XCTestCase {
  var codableCache: TinyCodableCache!
  let testKey = "testKey"
  struct TestObject: Codable, Equatable {
    let id: Int
    let name: String
  }

  let testObject = TestObject(id: 1, name: "Test Object")

  override func setUp() {
    super.setUp()
    let policy = TinyCodableCachePolicy.default
    codableCache = TinyCodableCache(policy: policy)
  }

  override func tearDown() async throws {
    await codableCache.deleteAll()
    codableCache = nil
  }

  func testSaveAndLoadCodableObjectForKey() async {
    codableCache.set(codable: testObject, forKey: testKey)
    if let loadedObject: TestObject? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedObject, testObject, "Loaded object should match the saved object")
    } else {
      XCTFail("Failed to load object")
    }
  }

  func testDeleteCodableObjectForKey() async {
    codableCache.set(codable: testObject, forKey: testKey)
    await codableCache.delete(forKey: testKey)
    let loadedObject: TestObject? = await codableCache.load(forKey: testKey)
    XCTAssertNil(loadedObject, "Object should be nil after deletion")
  }

  func testClearCache() async {
    codableCache.set(codable: testObject, forKey: testKey)
    await codableCache.deleteAll()
    let loadedObject: TestObject? = await codableCache.load(forKey: testKey)
    XCTAssertNil(loadedObject, "Object should be nil after clearing cache")
  }

  func testSaveNilCodableObjectForKey() async {
    let nilObject: TestObject? = nil
    codableCache.set(codable: nilObject, forKey: testKey)
    let loadedObject: TestObject? = await codableCache.load(forKey: testKey)
    XCTAssertNil(loadedObject, "Nil object should not be saved or loaded from cache")
  }

  func testLoadNonExistentKey() async {
    let loadedObject: TestObject? = await codableCache.load(forKey: "nonExistentKey")
    XCTAssertNil(loadedObject, "Loading a non-existent key should return nil")
  }

  func testSaveAndLoadEmptyStringForKey() async {
    let emptyString = ""
    codableCache.set(codable: emptyString, forKey: testKey)
    if let loadedString: String? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedString, emptyString, "Loaded string should match the saved empty string")
    } else {
      XCTFail("Failed to load string")
    }
  }

  func testSaveAndOverrideExistingObjectForKey() async {
    let newObject = TestObject(id: 2, name: "New Test Object")
    codableCache.set(codable: testObject, forKey: testKey)
    codableCache.set(codable: newObject, forKey: testKey)
    if let loadedObject: TestObject? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedObject, newObject, "Loaded object should match the last saved object")
    } else {
      XCTFail("Failed to load object")
    }
  }

  func testSaveAndLoadIntForKey() async {
    let testInt = 42
    codableCache.set(codable: testInt, forKey: testKey)
    if let loadedInt: Int? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedInt, testInt, "Loaded Int should match the saved Int")
    } else {
      XCTFail("Failed to load Int")
    }
  }

  func testSaveAndLoadBoolForKey() async {
    let testBool = true
    codableCache.set(codable: testBool, forKey: testKey)
    if let loadedBool: Bool? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedBool, testBool, "Loaded Bool should match the saved Bool")
    } else {
      XCTFail("Failed to load Bool")
    }
  }

  func testSaveAndLoadDoubleForKey() async {
    let testDouble = 3.14
    codableCache.set(codable: testDouble, forKey: testKey)
    if let loadedDouble: Double? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedDouble, testDouble, "Loaded Double should match the saved Double")
    } else {
      XCTFail("Failed to load Double")
    }
  }

  func testSaveAndLoadStringArrayForKey() async {
    let testStringArray = ["apple", "banana", "cherry"]
    codableCache.set(codable: testStringArray, forKey: testKey)
    if let loadedStringArray: [String]? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedStringArray, testStringArray, "Loaded String array should match the saved String array")
    } else {
      XCTFail("Failed to load String array")
    }
  }

  func testSaveAndLoadDictionaryForKey() async {
    let testDictionary = ["key1": "value1", "key2": "value2"]
    codableCache.set(codable: testDictionary, forKey: testKey)
    if let loadedDictionary: [String: String]? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedDictionary, testDictionary, "Loaded Dictionary should match the saved Dictionary")
    } else {
      XCTFail("Failed to load Dictionary")
    }
  }

  func testSaveAndLoadEnumForKey() async {
    enum TestEnum: String, Codable {
      case case1
      case case2
    }

    let testEnum = TestEnum.case1
    codableCache.set(codable: testEnum, forKey: testKey)
    if let loadedEnum: TestEnum? = await codableCache.load(forKey: testKey) {
      XCTAssertEqual(loadedEnum, testEnum, "Loaded Enum should match the saved Enum")
    } else {
      XCTFail("Failed to load Enum")
    }
  }
}
