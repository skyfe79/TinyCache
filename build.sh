# build for macOS
swift build

# show destinations
xcodebuild -showdestinations -scheme TinyCache

# build for iOS
xcodebuild -scheme TinyCache  -destination 'platform=iOS Simulator,OS=17.0.1,name=iPhone 15 Pro'
