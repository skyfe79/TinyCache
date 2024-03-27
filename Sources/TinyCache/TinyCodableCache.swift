import Foundation

/// A policy struct for configuring both memory and disk caching strategies for codable objects.
///
/// This struct combines separate policies for memory and disk caching into a single policy applicable to codable objects.
public struct TinyCodableCachePolicy {
  /// The policy for caching objects in memory.
  public let memoryCachePolicy: TinyCachePolicy
  /// The policy for caching objects on disk.
  public let diskCachePolicy: TinyDiskCachePolicy
  /// The default caching policy, utilizing default policies for both memory and disk caching.
  public static let `default` = TinyCodableCachePolicy(
    memoryCachePolicy: TinyCachePolicy(
      name: "tiny_codable_cache",
      countLimit: TinyCachePolicy.default.countLimit,
      totalCostLimit: TinyCachePolicy.default.totalCostLimit
    ),
    diskCachePolicy: TinyDiskCachePolicy(
      cacheFolderName: "tiny_codable_cache",
      countLimit: TinyDiskCachePolicy.default.countLimit
    )
  )
}

/// A cache class for storing and retrieving codable objects, supporting both memory and disk caching.
///
/// This class provides functionality to cache codable objects in both memory and on disk, with policies defined for each caching mechanism.
public final class TinyCodableCache {
  /// A shared instance of `TinyCodableCache` for global use.
  public static let shared = TinyCodableCache()

  /// The disk cache component of the codable cache.
  private let diskCache: TinyDiskCache
  /// The memory cache component of the codable cache, specialized for caching `Data` objects.
  private let memoryCache: TinyCache<String, Data>

  /// Initializes a new codable cache with the specified caching policy.
  ///
  /// - Parameter policy: The caching policy to use. Defaults to `.default`.
  public init(policy: TinyCodableCachePolicy = .default) {
    diskCache = TinyDiskCache(policy: policy.diskCachePolicy)
    memoryCache = TinyCache(policy: policy.memoryCachePolicy)
    memoryCache.shouldEvictValueWhenDiscarded = true
    memoryCache.cacheWillEvictValue = handleCacheWillEvictValue
  }

  /// Handles the cache eviction process for codable objects.
  private func handleCacheWillEvictValue(_ key: String, _ value: Data) {
    Task { [weak self] in
      await self?.diskCache.save(data: value, forKey: key)
    }
  }

  /// Saves a codable object to the cache for the specified key.
  ///
  /// - Parameters:
  ///   - value: The codable object to cache.
  ///   - key: The key to associate with the object.
  public func save(value: any Codable, forKey key: String) {
    if let data = encode(value) {
      memoryCache.set(value: data, forKey: key)
    }
  }

  /// Retrieves a codable object from the cache for the specified key, executing a completion handler upon retrieval.
  ///
  /// - Parameters:
  ///   - key: The key for the object to retrieve.
  ///   - completion: A completion handler that is executed with the retrieved object, or `nil` if not found.
  public func load<T: Codable>(forKey key: String, completion: @escaping (T?) -> Void) {
    if let data = memoryCache.value(forKey: key) {
      completion(decode(data))
      return 
    }

    Task { [weak self] in
      if let data = await self?.diskCache.load(forKey: key), let thing: T = self?.decode(data) {
        self?.memoryCache.set(value: data, forKey: key)
        completion(thing)
      } else {
        completion(nil)
      }
    }
  }

  /// Asynchronously retrieves a codable object from the cache for the specified key.
  ///
  /// - Parameter key: The key for the object to retrieve.
  /// - Returns: An optional codable object retrieved from the cache.
  public func load<T: Codable>(forKey key: String) async -> T? {
    return await withCheckedContinuation { continuation in
      load(forKey: key) { thing in 
        continuation.resume(returning: thing)
      }
    }
  }

  /// Asynchronously deletes the object associated with the specified key from both the memory and disk caches.
  /// The eviction handler is not used when the user explicitly deletes.
  ///
  /// - Parameter key: The key for the object to delete.
  public func delete(forKey key: String) async {
    memoryCache.shouldEvictValueWhenDiscarded = false
    memoryCache.removeValue(forKey: key)
    memoryCache.shouldEvictValueWhenDiscarded = true
    await diskCache.delete(forKey: key)
  }

  /// Asynchronously clears all objects from both the memory and disk caches.
  /// The eviction handler is not used when the user explicitly deletes.
  public func deleteAll() async {
    memoryCache.shouldEvictValueWhenDiscarded = false
    memoryCache.clear()
    memoryCache.shouldEvictValueWhenDiscarded = true
    await diskCache.deleteAll()
  }

  /// Encodes a codable object into `Data`.
  ///
  /// - Parameter value: The codable object to encode.
  /// - Returns: The data representation of the object, or `nil` if encoding fails.
  internal func encode(_ value: any Codable) -> Data? {
    let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(value)
      return data
    } catch {
      return nil
    }
  }

  /// Decodes a codable object from `Data`.
  ///
  /// - Parameter data: The data to decode.
  /// - Returns: The decoded codable object, or `nil` if decoding fails.
  internal func decode<T: Codable>(_ data: Data) -> T? {
    let decoder = JSONDecoder()
    do {
      let value = try decoder.decode(T.self, from: data)
      return value
    } catch {
      return nil
    }
  }
}
