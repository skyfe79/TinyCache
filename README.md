# TinyCache

TinyCache is a simple and lightweight caching solution for Swift apps.

## Installation

### Swift Package Manager

To integrate TinyCache into your project using Swift Package Manager, add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/skyfe79/TinyCache.git", .upToNextMajor(from: "0.0.1"))
]
```

## Usage

### Memory Caching

```swift
let tinyCache = TinyCache<String, String>(policy: .default)
tinyCache.set(value: "Hello, World!", forKey: "greeting")
let greeting = tinyCache.value(forKey: "greeting")
```

### Codable Caching

```swift
struct MyModel: Codable {
    let id: Int
    let name: String
}

let codableCache = TinyCodableCache.shared
let model = MyModel(id: 1, name: "TinyCache")
codableCache.set(codable: model, forKey: "modelKey")
```

### Image Caching

```swift
let imageCache = TinyImageCache.shared
imageCache.set(image: myImage, forKey: "imageKey")
```

## License

TinyCache is released under the MIT License. See LICENSE for details.
