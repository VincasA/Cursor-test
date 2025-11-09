# Deploying EarnTime to Your iPhone from Command Line

This guide shows you how to build and deploy the EarnTime app to your iPhone directly from the terminal, without opening Xcode.

## Prerequisites

1. **Xcode Command Line Tools** (usually installed with Xcode)
   ```bash
   xcode-select --install
   ```

2. **Apple ID configured** in Xcode (for code signing)
   - Open Xcode once and go to Settings → Accounts
   - Add your Apple ID if not already added

3. **iPhone connected via USB**
   - Unlock your iPhone
   - Trust this computer if prompted

## Quick Start

### Option 1: Using the Deployment Script (Easiest)

```bash
cd /Users/vincas/Documents/Programming/ios-apps/Cursor-test/EarnTime
chmod +x deploy-to-device.sh
./deploy-to-device.sh
```

The script will:
- ✅ Detect your connected iPhone
- ✅ Build the app for your device
- ✅ Install it automatically

### Option 2: Manual Command Line Deployment

#### Step 1: List Connected Devices
```bash
xcrun xctrace list devices
```

Or for iOS 17+:
```bash
xcrun devicectl list devices
```

#### Step 2: Build for Device
```bash
xcodebuild clean build \
  -project EarnTime.xcodeproj \
  -scheme EarnTime \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  CODE_SIGN_IDENTITY="Apple Development" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  -allowProvisioningUpdates
```

#### Step 3: Install on Device

**Method A: Using ios-deploy** (Recommended - install via Homebrew)
```bash
brew install ios-deploy
ios-deploy --bundle build/Debug-iphoneos/EarnTime.app
```

**Method B: Using xcodebuild** (Built-in)
```bash
xcodebuild -project EarnTime.xcodeproj \
  -scheme EarnTime \
  -destination "id=YOUR_DEVICE_ID" \
  -configuration Debug \
  install
```

**Method C: Using xcrun devicectl** (iOS 17+)
```bash
xcrun devicectl device install app \
  --device YOUR_DEVICE_ID \
  build/Debug-iphoneos/EarnTime.app
```

## Finding Your Team ID

If you need your Team ID for signing:

```bash
# List available teams
security find-identity -v -p codesigning
```

Or check in Xcode:
- Xcode → Settings → Accounts
- Select your Apple ID → View Details
- Copy the Team ID

## Troubleshooting

### "No devices found"
- Make sure iPhone is unlocked
- Check USB connection
- Try unplugging and replugging the cable
- Trust the computer on your iPhone if prompted

### "Code signing failed"
- Open Xcode once and configure signing:
  - Select project → Target → Signing & Capabilities
  - Enable "Automatically manage signing"
  - Select your Apple ID team
- Then try the command again

### "Provisioning profile not found"
- The `-allowProvisioningUpdates` flag should handle this automatically
- Or configure signing in Xcode first (see above)

### "App installed but won't launch"
- Go to iPhone Settings → General → VPN & Device Management
- Tap your Apple ID
- Tap "Trust [Your Apple ID]"

## Alternative: Using Fastlane (Advanced)

For more advanced deployment, consider using [Fastlane](https://fastlane.tools):

```bash
gem install fastlane
cd EarnTime
fastlane init
```

Then create a `Fastfile`:
```ruby
lane :deploy do
  build_app(
    scheme: "EarnTime",
    export_method: "development"
  )
  install_on_device
end
```

Run with: `fastlane deploy`

## Building for Simulator (Alternative)

If you want to test on a simulator instead:

```bash
# List available simulators
xcrun simctl list devices

# Build for simulator
xcodebuild -project EarnTime.xcodeproj \
  -scheme EarnTime \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Install and run
xcrun simctl install booted build/Debug-iphonesimulator/EarnTime.app
xcrun simctl launch booted com.opensource.EarnTime
```

## Notes

- The first build may take several minutes
- Subsequent builds are faster due to caching
- Debug builds are larger but allow debugging
- Release builds are optimized but require App Store distribution setup
