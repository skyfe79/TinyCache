import Foundation

/// A wrapper class for cache values to be used with `NSCache`.
///
/// This class wraps a generic `Value` type. It is used to store the value in `NSCache` alongside `CacheKey`.
internal final class CacheValue<Key: Hashable, Value> {
  /// The key associated with the value.
  /// NSCache has no built-in way to access the key, so we need to store it separately.
  let key: Key
  /// The actual value being cached.
  let value: Value

  /// Initializes a new `CacheValue` with the provided value and key.
  ///
  /// - Parameters:
  ///   - value: The value to cache.
  ///   - key: The key associated with the value.
  init(_ value: Value, forKey key: Key) {
    self.key = key
    self.value = value
  }
}