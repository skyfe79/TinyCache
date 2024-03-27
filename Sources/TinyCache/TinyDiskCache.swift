import Foundation

/// An enumeration that defines the errors that `TinyDiskCache` can throw.
public enum TinyDiskCacheError: Error {
  /// An error indicating that the specified cache folder name is invalid.
  case invalidCacheFolderName
}

/// A structure that defines the policy for managing the disk cache.
///
/// This policy includes the name of the cache folder and a limit on the number of items that can be stored.
public struct TinyDiskCachePolicy {
  /// The name of the folder to use for the disk cache.
  public let cacheFolderName: String
  /// The maximum number of items that the disk cache can hold. if 0, there is no limit.
  public let countLimit: Int

  /// The default policy for the disk cache.
  public static let `default` = TinyDiskCachePolicy(cacheFolderName: "tiny_disk_cache", countLimit: 100)
}

/// An actor responsible for managing disk-based caching of data.
///
/// This actor provides functionality to save and load data to and from the disk, using a specified folder within the cache directory.
public actor TinyDiskCache {
  /// The default file manager used to interact with the file system.
  private let fileManager = FileManager.default
  /// The policy for managing the disk cache.
  private let policy: TinyDiskCachePolicy

  /// Initializes a new disk cache with the specified folder name.
  ///
  /// - Parameter cacheFolderName: The name of the folder to use for storing cached data.
  public init(policy: TinyDiskCachePolicy = .default) {
    self.policy = policy
  }

  /// Saves the provided data to the disk cache, associated with the specified key.
  ///
  /// - Parameters:
  ///   - data: The data to save to the cache.
  ///   - key: The key to associate with the data.
  public func set(data: Data, forKey key: String) {
    guard let url = cacheFilePathUrl(forKey: key) else { return }
    try? data.write(to: url)
  }

  /// Loads and returns the data associated with the specified key from the disk cache.
  ///
  /// - Parameter key: The key for which to load the data.
  /// - Returns: The data associated with the key, or `nil` if no data is found.
  public func load(forKey key: String) -> Data? {
    guard let url = cacheFilePathUrl(forKey: key) else { return nil }
    return try? Data(contentsOf: url)
  }

  /// Deletes the data associated with the specified key from the disk cache.
  ///
  /// If the specified key does not exist within the cache, this method returns an error indicating that the cache folder name is invalid.
  ///
  /// - Parameter key: The key for which to delete the associated data.
  /// - Returns: An optional `Error` if the deletion fails, otherwise `nil`.
  @discardableResult
  public func delete(forKey key: String) -> Error? {
    guard let url = cacheFilePathUrl(forKey: key) else { return TinyDiskCacheError.invalidCacheFolderName }
    do {
      try fileManager.removeItem(at: url)
      return nil
    } catch {
      return error
    }
  }

  /// Deletes all files within the cache folder.
  @discardableResult
  public func deleteAll() -> Error? {
    guard
      let cacheDirUrl = getCacheDirectoryUrl()
    else {
      return TinyDiskCacheError.invalidCacheFolderName
    }

    do {
      let filePaths = try fileManager.contentsOfDirectory(at: cacheDirUrl, includingPropertiesForKeys: nil, options: [])
      for filePath in filePaths {
        try fileManager.removeItem(at: filePath)
      }
      return nil
    } catch {
      return error
    }
  }

  /// Generates the file URL for the specified key within the cache directory.
  ///
  /// - Parameter key: The key for which to generate the file URL.
  /// - Returns: The file URL for the specified key, or `nil` if the URL could not be generated.
  internal func cacheFilePathUrl(forKey key: String) -> URL? {
    guard
      let cacheDirUrl = getCacheDirectoryUrl()
    else {
      return nil
    }

    do {
      if !fileManager.fileExists(atPath: cacheDirUrl.path) {
        try fileManager.createDirectory(at: cacheDirUrl, withIntermediateDirectories: true, attributes: nil)
      }
      return cacheDirUrl.appendingPathComponent(key)
    } catch {
      return nil
    }
  }

  /// Checks if the limit count is greater than zero and enforces the limit count by removing excess files.
  public func checkAndEnforceCountLimit() {
    guard policy.countLimit > 0 else { return }
    try? enforceCountLimit(policy.countLimit)
  }

  /// Enforces the limit count by removing files that exceed the limit count, based on their creation date.
  ///
  /// - Parameter countLimit: The maximum number of files to keep in the cache directory.
  internal func enforceCountLimit(_ countLimit: Int) throws {
    guard let cacheDirUrl = getCacheDirectoryUrl() else {
      throw TinyDiskCacheError.invalidCacheFolderName
    }

    let files = try getFilesSortedByCreationDate(in: cacheDirUrl)

    let excessFiles = files.dropFirst(countLimit)

    try removeFiles(excessFiles)
  }

  /// Retrieves the URL of the cache directory.
  ///
  /// - Returns: The URL of the cache directory, or `nil` if it cannot be found.
  internal func getCacheDirectoryUrl() -> URL? {
    return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(policy.cacheFolderName)
  }

  /// Retrieves files sorted by their creation date within a specified directory.
  ///
  /// - Parameter directoryUrl: The URL of the directory to sort files in.
  /// - Returns: An array of tuples containing the file URL and its creation date.
  internal func getFilesSortedByCreationDate(in directoryUrl: URL) throws -> [(URL, Date)] {
    let directoryContents = try fileManager.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)

    return try directoryContents.compactMap { fileUrl -> (URL, Date)? in
      let fileAttributes = try fileManager.attributesOfItem(atPath: fileUrl.path)
      guard let creationDate = fileAttributes[.creationDate] as? Date else {
        return nil
      }
      return (fileUrl, creationDate)
    }.sorted { $0.1 < $1.1 }
  }

  /// Removes a list of files from the file system.
  ///
  /// - Parameter files: An array slice of tuples containing the file URL and its creation date.
  internal func removeFiles(_ files: ArraySlice<(URL, Date)>) throws {
    for (file, _) in files {
      try fileManager.removeItem(at: file)
    }
  }
}
