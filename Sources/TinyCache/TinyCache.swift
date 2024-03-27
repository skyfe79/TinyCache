import Foundation
import Dispatch

/// A policy for configuring the behavior of a `TinyCache` instance.
///
/// This structure defines limits for the number of objects and the total cost of objects that can be stored in a cache.
/// It also includes a name for identifying the cache instance.
public struct TinyCachePolicy {
  /// A name for the cache, useful for debugging.
  public let name: String
  /// The maximum number of objects the cache should hold.
  public let countLimit: Int
  /// The maximum total cost that the cache can hold before it starts evicting objects.
  public let totalCostLimit: Int
  

  /// A default cache policy.
  public static let `default` = TinyCachePolicy(name: "default_tiny_cache", countLimit: 100, totalCostLimit: 0)
}

/// A generic cache class that stores objects of any type, with eviction based on `TinyCachePolicy`.
///
/// This class provides a simple caching mechanism that can store any type of object. It uses `NSCache` internally for storage.
public class TinyCache<Key, Value> where Key: Hashable {
  /// An instance of `NSCache` used for storing cached objects. The cache keys and values are wrapped in `CacheKey` and `CacheValue` types to ensure type safety.
  // NSCache is thread-safe, so we don't need to use locks to protect against concurrent access.
  private var cache: NSCache<CacheKey<Key>, CacheValue<Key, Value>>
  /// An instance of `NSCacheDelegator` used to handle cache eviction notifications. This allows for custom actions to be performed when an object is evicted from the cache.
  private var nsCacheDelegator: NSCacheDelegator

  /// A closure that is executed when a value is about to be evicted from the cache.
  /// - Parameters:
  ///   - key: The key associated with the value being evicted.
  ///   - value: The value that is being evicted.
  public var cacheWillEvictValue: ((_ key: Key, _ value: Value) -> Void)?

  /// A semaphore used to synchronize access to the `shouldEvictValueWhenDiscarded` property.
  private var lock = DispatchSemaphore(value: 1)

  /// A property that determines whether the cache should automatically evict values when their content is discarded.
  ///
  /// Accessing this property returns a Boolean value indicating whether automatic eviction is enabled. Setting this property allows you to enable or disable automatic eviction.
  private var _shouldEvictValueWhenDiscarded: Bool = true
  public var shouldEvictValueWhenDiscarded: Bool {
    get {
      _shouldEvictValueWhenDiscarded
    }
    set {
      lock.wait()
      _shouldEvictValueWhenDiscarded = newValue
      lock.signal()
    }
  }

  /// Initializes a new cache with the specified policy.
  ///
  /// - Parameter policy: The policy to use for the cache. Defaults to `.default`.
  public init(policy: TinyCachePolicy = .default) {
    nsCacheDelegator = NSCacheDelegator()
    cache = NSCache()
    cache.name = policy.name
    cache.countLimit = policy.countLimit
    cache.totalCostLimit = policy.totalCostLimit
    cache.delegate = nsCacheDelegator
    nsCacheDelegator.willEvictObject = nsCacheWillEvictObject
  }

  /// Sets the value for the specified key in the cache.
  ///
  /// - Parameters:
  ///   - value: The value to store in the cache.
  ///   - key: The key with which to associate the value.
  public func set(value: Value, forKey key: Key) {
    let (cacheKey, cacheValue) = cacheKeyValue(key, value)
    cache.setObject(cacheValue, forKey: cacheKey)
  }

  /// Sets the value for the specified key in the cache, with an associated cost.
  ///
  /// - Parameters:
  ///   - value: The value to store in the cache.
  ///   - key: The key with which to associate the value.
  ///   - cost: The cost with which to associate the value.
  public func set(value: Value, forKey key: Key, cost: Int) {
    let (cacheKey, cacheValue) = cacheKeyValue(key, value)
    cache.setObject(cacheValue, forKey: cacheKey, cost: cost)
  }

  /// Returns the value associated with a given key.
  ///
  /// - Parameter key: The key for which to return the corresponding value.
  /// - Returns: The value associated with `key`, or `nil` if no value is associated with `key`.
  public func value(forKey key: Key) -> Value? {
    let cacheKey = CacheKey(key)
    let cacheValue = cache.object(forKey: cacheKey)
    return cacheValue?.value
  }

  /// Creates a `CacheKey` and `CacheValue` pair from the provided key and value.
  ///
  /// This method takes a key and value, wraps them in their respective `CacheKey` and `CacheValue` types, and returns the pair. This is used internally to prepare items for storage in the `NSCache`.
  ///
  /// - Parameters:
  ///   - key: The key to be wrapped in a `CacheKey`.
  ///   - value: The value to be wrapped in a `CacheValue`.
  /// - Returns: A tuple containing the `CacheKey` and `CacheValue` created from the provided key and value.
  private func cacheKeyValue(_ key: Key, _ value: Value) -> (CacheKey<Key>, CacheValue<Key, Value>) {
    let cacheKey = CacheKey(key)
    let cacheValue = CacheValue(value, forKey: key)
    return (cacheKey, cacheValue)
  }

  /// Called when an object is about to be evicted from the cache.
  ///
  /// This method checks if the object being evicted is of type `CacheValue` and, if so, notifies the delegate.
  ///
  /// - Parameter obj: The object that is about to be evicted from the cache.
  private func nsCacheWillEvictObject(_ obj: Any) {
    if shouldEvictValueWhenDiscarded, let value = obj as? CacheValue<Key, Value> {
      cacheWillEvictValue?(value.key, value.value)
    }
  }

  /// Removes the value associated with the specified key from the cache.
  ///
  /// This method attempts to remove the value for the provided key from the cache. If the key is found and the value is successfully removed, the `nsCacheWillEvictObject` delegate method is called, allowing for custom handling of the eviction process. If no value is found for the key, no action is taken and the method completes without effect.
  ///
  /// - Parameter key: The key for which to remove the associated value.
  public func removeValue(forKey key: Key) {
    let cacheKey = CacheKey(key)
    cache.removeObject(forKey: cacheKey)
  }

  /// Removes all values from the cache.
  ///
  /// This method clears the cache of all stored objects. For each object being removed, the `nsCacheWillEvictObject` delegate method will be called, allowing for custom handling of the eviction process.
  public func clear() {
    cache.removeAllObjects()
  }

  /// Accesses the value associated with the given key for reading and writing.
  ///
  /// - Parameter key: The key to associate the value with.
  public subscript(key: Key) -> Value? {
    get { 
      value(forKey: key) 
    }
    set(newValue) {
      if let newValue = newValue {
        set(value: newValue, forKey: key)
      } else {
        removeValue(forKey: key)
      }
    }
  }
}
