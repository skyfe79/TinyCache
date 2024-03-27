# test for macOS
swift test

# test for iOS
xcodebuild -scheme TinyCache  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone 14 Pro' test