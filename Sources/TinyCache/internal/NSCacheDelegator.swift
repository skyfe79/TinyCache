import Foundation

/// A delegate handler for `NSCache` that allows for the execution of a closure when an object is evicted from the cache.
///
/// This class is designed to be used internally within the TinyCache framework to provide a hook for cache eviction events.
/// It conforms to `NSCacheDelegate` to intercept eviction notifications and executes a provided closure if available.
internal final class NSCacheDelegator: NSObject, NSCacheDelegate {
  
  /// A closure that is executed when an object is about to be evicted from the cache.
  /// - Parameter obj: The object that is being evicted from the cache.
  var willEvictObject: ((_ obj: Any) -> Void)?
  
  /// Notifies the delegate that an object is about to be evicted or removed from the cache.
  /// - Parameters:
  ///   - cache: The cache object that is evicting the object.
  ///   - obj: The object that is being evicted from the cache.
  func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
    willEvictObject?(obj)
  }
  
  /// Initializes a new `NSCacheDelegator` with an optional closure to be executed upon object eviction.
  /// - Parameter willEvictObject: An optional closure that is executed when an object is evicted from the cache.
  init(willEvictObject: ((_ obj: Any) -> Void)? = nil) {
    self.willEvictObject = willEvictObject
  }
}