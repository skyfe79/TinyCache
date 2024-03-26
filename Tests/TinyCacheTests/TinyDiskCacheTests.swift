import XCTest
@testable import TinyCache

final class TinyDiskCacheTests: XCTestCase {
    var diskCache: TinyDiskCache!
    let testKey = "testKey"
    let testData = "TestData".data(using: .utf8)!

    override func setUp() {
        super.setUp()
        let policy = TinyDiskCachePolicy(cacheFolderName: "TestCache", countLimit: 10)
        diskCache = TinyDiskCache(policy: policy)
    }

    override func tearDown() async throws {
        await diskCache.deleteAll()
        diskCache = nil
    }

    func testSaveAndLoadData() async {
        await diskCache.save(data: testData, forKey: testKey)
        let loadedData = await diskCache.load(forKey: testKey)
        XCTAssertNotNil(loadedData, "Loaded data should not be nil")
        XCTAssertEqual(loadedData, testData, "Loaded data should match saved data")
        let loadedTestData = String(data: loadedData!, encoding: .utf8)
        XCTAssertEqual(loadedTestData, "TestData", "Loaded data should match saved data")
    }

    func testDeleteData() async {
        await diskCache.save(data: testData, forKey: testKey)
        await diskCache.delete(forKey: testKey)
        let loadedData = await diskCache.load(forKey: testKey)
        XCTAssertNil(loadedData, "Data should be nil after deletion")
    }

    func testDeleteAllData() async {
        await diskCache.save(data: testData, forKey: testKey)
        await diskCache.deleteAll()
        let loadedData = await diskCache.load(forKey: testKey)
        XCTAssertNil(loadedData, "All data should be deleted")
    }

    func testEnforceCountLimit() async {
        for i in 0..<20 { // Double the limit count to test enforcement
            let key = "Key\(i)"
            let data = "Data\(i)".data(using: .utf8)!
            await diskCache.save(data: data, forKey: key)
        }
        await diskCache.checkAndEnforceCountLimit()
        let files = (try? await diskCache.getFilesSortedByCreationDate(in: diskCache.getCacheDirectoryUrl()!)) ?? []
        XCTAssertEqual(files.count, 10, "Files count should be enforced to limit count")
    }

    func testSaveDataWithEmptyKey() async {
        let emptyKey = ""
        await diskCache.save(data: testData, forKey: emptyKey)
        let loadedData = await diskCache.load(forKey: emptyKey)
        XCTAssertNil(loadedData, "Data should be nil for empty key")
    }

    func testSaveDataWithSpecialCharactersKey() async {
        let specialKey = "!@#$%^&*()"
        await diskCache.save(data: testData, forKey: specialKey)
        let loadedData = await diskCache.load(forKey: specialKey)
        XCTAssertNotNil(loadedData, "Data should not be nil for special characters key")
        XCTAssertEqual(loadedData, testData, "Loaded data should match saved data for special characters key")
    }

    func testLoadDataForNonexistentKey() async {
        let nonexistentKey = "nonexistentKey"
        let loadedData = await diskCache.load(forKey: nonexistentKey)
        XCTAssertNil(loadedData, "Data should be nil for nonexistent key")
    }

    func testDeleteNonexistentKey() async {
        let nonexistentKey = "nonexistentKey"
        let deletionError = await diskCache.delete(forKey: nonexistentKey)
        XCTAssertNotNil(deletionError, "Deletion should fail for nonexistent key")
    }
}
