import Foundation

#if os(macOS)
  import Cocoa

  /// A typealias for `NSImage` to abstract platform-specific image types.
  public typealias PlatformImage = NSImage
#else
  import UIKit

  /// A typealias for `UIImage` to abstract platform-specific image types.
  public typealias PlatformImage = UIImage
#endif

/// A structure defining caching policies for images, including both memory and disk caching strategies.
public struct TinyImageCachePolicy {
  /// The policy for caching images in memory.
  public let memoryCachePolicy: TinyCachePolicy
  /// The policy for caching images on disk.
  public let diskCachePolicy: TinyDiskCachePolicy
  /// The default policy for the image cache, utilizing default memory and disk cache policies.
  public static let `default` = TinyImageCachePolicy(
    memoryCachePolicy: TinyCachePolicy(
      name: "tiny_image_cache",
      countLimit: TinyCachePolicy.default.countLimit,
      totalCostLimit: TinyCachePolicy.default.totalCostLimit
    ),
    diskCachePolicy: TinyDiskCachePolicy(
      cacheFolderName: "tiny_image_cache",
      countLimit: TinyDiskCachePolicy.default.countLimit
    )
  )
}

/// A class responsible for caching images, supporting both memory and disk caching mechanisms.
public final class TinyImageCache {
  /// A shared instance of `TinyImageCache` for global use.
  public static let shared = TinyImageCache()
  /// The disk cache component of the image cache.
  private let diskCache: TinyDiskCache
  /// The memory cache component of the image cache, specialized for caching `PlatformImage` objects.
  private let memoryCache: TinyCache<String, PlatformImage>

  /// Initializes a new image cache with the specified caching policy.
  ///
  /// - Parameter policy: The caching policy to use. Defaults to `.default`.
  public init(policy: TinyImageCachePolicy = .default) {
    diskCache = TinyDiskCache(policy: policy.diskCachePolicy)
    memoryCache = TinyCache(policy: policy.memoryCachePolicy)
    memoryCache.shouldEvictValueWhenDiscarded = true
    memoryCache.cacheWillEvictValue = handleCacheWillEvictValue
  }

  /// Handles the cache eviction process for images.
  private func handleCacheWillEvictValue(_ key: String, _ value: PlatformImage) {
    if let data = imageToData(image: value) {
      Task { [weak self] in
        await self?.diskCache.save(data: data, forKey: key)
      }
    }
  }

  /// Saves an image to the cache for the specified key.
  ///
  /// - Parameters:
  ///   - image: The image to cache.
  ///   - key: The key to associate with the image.
  public func save(image: PlatformImage, forKey key: String) {
    memoryCache.set(value: image, forKey: key)
  }

  /// Saves an image to the cache for the specified URL.
  ///
  /// - Parameters:
  ///   - image: The image to cache.
  ///   - url: The URL to associate with the image.
  public func save(image: PlatformImage, forKey url: URL) {
    let urlString = url.absoluteString
    save(image: image, forKey: urlString)
  }

  /// Retrieves an image from the cache for the specified key, executing a completion handler upon retrieval.
  ///
  /// - Parameters:
  ///   - key: The key for the image to retrieve.
  ///   - completion: A completion handler that is executed with the retrieved image, or `nil` if not found.
  public func image(forKey key: String, completion: @escaping (PlatformImage?) -> Void) {
    if let image = memoryCache.value(forKey: key) {
      completion(image)
      return
    }

    Task { [weak self] in
      if let data = await self?.diskCache.load(forKey: key), let image = PlatformImage(data: data) {
        self?.memoryCache.set(value: image, forKey: key)
        completion(image)
      } else {
        completion(nil)
      }
    }
  }

  /// Retrieves an image from the cache for the specified URL, executing a completion handler upon retrieval.
  ///
  /// - Parameters:
  ///   - url: The URL for the image to retrieve.
  ///   - completion: A completion handler that is executed with the retrieved image, or `nil` if not found.
  public func image(forKey url: URL, completion: @escaping (PlatformImage?) -> Void) {
    let urlString = url.absoluteString
    image(forKey: urlString, completion: completion)
  }

  /// Asynchronously retrieves an image from the cache for the specified key.
  ///
  /// - Parameter key: The key for the image to retrieve.
  /// - Returns: An optional `PlatformImage` retrieved from the cache.
  public func image(forKey key: String) async -> PlatformImage? {
    return await withCheckedContinuation { continuation in
      self.image(forKey: key) { image in
        continuation.resume(returning: image)
      }
    }
  }

  /// Asynchronously retrieves an image from the cache for the specified URL.
  ///
  /// - Parameter url: The URL for the image to retrieve.
  /// - Returns: An optional `PlatformImage` retrieved from the cache.
  public func image(forKey url: URL) async -> PlatformImage? {
    let urlString = url.absoluteString
    return await image(forKey: urlString)
  }

  /// Asynchronously deletes the image associated with the specified key from both the memory and disk caches. 
  /// The eviction handler is not used when the user explicitly deletes.
  ///
  /// - Parameter key: The key for the image to delete.
  public func delete(forKey key: String) async {
    memoryCache.shouldEvictValueWhenDiscarded = false
    memoryCache.removeValue(forKey: key)
    memoryCache.shouldEvictValueWhenDiscarded = true
    await diskCache.delete(forKey: key)
  }

  /// Asynchronously clears all images from both the memory and disk caches.
  /// The eviction handler is not used when the user explicitly deletes.
  public func deleteAll() async {
    memoryCache.shouldEvictValueWhenDiscarded = false
    memoryCache.clear()
    memoryCache.shouldEvictValueWhenDiscarded = true
    await diskCache.deleteAll()
  }

  /// Converts a `PlatformImage` to `Data` representation, suitable for disk caching.
  ///
  /// - Parameter image: The image to convert.
  /// - Returns: The data representation of the image, or `nil` if conversion fails.
  func imageToData(image: PlatformImage) -> Data? {
    #if os(macOS)
      guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
      let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
      return bitmapRep.representation(using: .png, properties: [:])
    #else
      return image.pngData()
    #endif
  }
}
