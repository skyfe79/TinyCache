import XCTest
@testable import TinyCache

#if os(macOS)
import Cocoa
func createImage(size: NSSize) -> NSImage? {
    return NSImage(size: NSSize(width: 100, height: 100))
}
#else
import UIKit
func createImage(size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
#endif


final class TinyImageCacheTests: XCTestCase {
    var imageCache: TinyImageCache!
    let testKey = "testKey"
    let testURL = URL(string: "https://avatars.githubusercontent.com/u/309935?v=4")!
    var testImage: PlatformImage!

    override func setUp() {
        super.setUp()
        let policy = TinyImageCachePolicy.default
        imageCache = TinyImageCache(policy: policy)
        #if os(macOS)
        testImage = createImage(size: NSSize(width: 100, height: 100))
        #else
        testImage = createImage(size: CGSize(width: 100, height: 100))
        #endif
    }

    override func tearDown() async throws {
        await imageCache.deleteAll()
        imageCache = nil
    }

    func testSaveAndLoadImageForKey() async {
        imageCache.set(image: testImage, forKey: testKey)
        let loadedImage = await imageCache.image(forKey: testKey)
        XCTAssertNotNil(loadedImage, "Loaded image should not be nil")
    }

    func testSaveAndLoadImageForURL() async {
        imageCache.set(image: testImage, forKey: testURL)
        let loadedImage = await imageCache.image(forKey: testURL)
        XCTAssertNotNil(loadedImage, "Loaded image should not be nil")
    }

    func testImageEviction() async {
        imageCache.set(image: testImage, forKey: testKey)
        await imageCache.delete(forKey: testKey)
        let loadedImage = await imageCache.image(forKey: testKey)
        XCTAssertNil(loadedImage, "Image should be nil after eviction")
    }

    func testClearCache() async {
        imageCache.set(image: testImage, forKey: testKey)
        await imageCache.deleteAll()
        let loadedImage = await imageCache.image(forKey: testKey)
        XCTAssertNil(loadedImage, "Image should be nil after clearing cache")
    }

    func testDownloadAndCacheImage() async {
        do {
            let imageData = try await downloadData(from: testURL)
            guard let image = PlatformImage(data: imageData) else {
                XCTFail("Failed to create image from downloaded data")
                return
            }
            imageCache.set(image: image, forKey: testURL)
            let loadedImage = await imageCache.image(forKey: testURL)
            XCTAssertNotNil(loadedImage, "Loaded image should not be nil after downloading and caching")
        } catch {
            XCTFail("Downloading or caching image failed with error: \(error)")
        }
    }
}
