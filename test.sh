# test for macOS
swift test

# test for iOS
xcodebuild -scheme TinyCache  -destination 'platform=iOS Simulator,OS=17.0.1,name=iPhone 15 Pro' test