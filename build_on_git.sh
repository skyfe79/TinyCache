# build for macOS
swift build

# show destinations
xcodebuild -showdestinations -scheme TinyCache

# build for iOS
xcodebuild -scheme TinyCache  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone 14 Pro'
