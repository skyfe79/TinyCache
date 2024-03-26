import Foundation

/// A wrapper class for cache keys that conforms to `NSObject` to be used with `NSCache`.
///
/// This class wraps a generic `Key` type that must conform to `Hashable`. It overrides `hash` and `isEqual(_:)`
/// to ensure that `CacheKey` instances can be effectively used as keys in `NSCache`.
internal final class CacheKey<Key: Hashable>: NSObject {
  /// The underlying key value.
  let key: Key

  /// Initializes a new `CacheKey` with the provided key.
  ///
  /// - Parameter key: The key to wrap.
  init(_ key: Key) {
    self.key = key
  }

  /// The hash value of the `CacheKey`, derived from its `key`.
  override var hash: Int {
    return key.hashValue
  }

  /// Determines if two `CacheKey` instances are equal based on their underlying `key` values.
  ///
  /// - Parameter object: The object to compare for equality.
  /// - Returns: `true` if the objects are equal, `false` otherwise.
  override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? CacheKey<Key> else { return false }
    return key == other.key
  }
}
