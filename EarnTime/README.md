# EarnTime

EarnTime is a privacy-first, open-source alternative to Unrot’s “Earn Your Screen Time” concept. Complete meaningful habits, log the time you spend on distracting apps, and keep a running balance of earned minutes — all stored locally on-device.

## Highlights

- 100 % offline: no accounts, ads, or analytics.
- SwiftUI + SwiftData architecture targeting iOS 17+.
- Tasks (“Unrots”) with built-in timers for Focus, Exercise, Chores, Reading, and custom categories.
- Credit wallet that tracks earned versus spent minutes and gently nudges you when timers end.
- Statistics dashboard powered by Swift Charts with CSV/JSON export for automation.
- Open-source under the MIT license.

## Project Structure

```
EarnTime/
 ┣ EarnTime.xcodeproj
 ┣ EarnTime/
 ┃ ┣ App.swift
 ┃ ┣ Info.plist
 ┃ ┣ Assets.xcassets/
 ┃ ┣ Preview.xcassets/
 ┃ ┣ Models/
 ┃ ┣ ViewModels/
 ┃ ┣ Services/
 ┃ ┗ Views/
 ┣ README.md
 ┗ LICENSE
```

- **Models**: SwiftData entities (`TaskSession`, `ScreenTimeLog`) and helpers like `TaskCategory` and `CreditManager`.
- **ViewModels**: Business logic for timers, credit spending, statistics, and settings.
- **Views**: SwiftUI screens for Home (earn/spend), Stats, Settings, and reusable components.
- **Services**: Local notifications and export tooling.

## Building in Xcode

1. Ensure you have Xcode 15.0 or newer (iOS 17 SDK required).
2. Clone this repository and open `EarnTime/EarnTime.xcodeproj` in Xcode.
3. Select the `EarnTime` scheme and choose an iOS 17 simulator or connected device.
4. Press **Run** (`⌘R`). The app uses SwiftData; the first launch will request notification permissions if you start timers.

### Code Signing

The bundle identifier defaults to `com.opensource.EarnTime`. Update it and supply a development team in the project’s Signing settings if you plan to run on physical hardware.

## How EarnTime Works

- **Earn Credits**: Start a task timer from the Home tab. When the timer completes (or you finish early), credits equal to the focused minutes are added to your wallet.
- **Spend Credits**: Before opening distracting apps, start a “spend” countdown. EarnTime logs the duration and deducts minutes automatically.
- **Wallet**: The balance is computed from your SwiftData history of earned sessions minus screen-time logs. Weekly archiving marks older entries as hidden without deleting them.
- **Statistics**: Visualize daily earned versus spent minutes, highlight your strongest habit, and export data for personal review or automation.
- **Settings**: Manage custom categories, theme (light/dark/system), notification permissions, weekly archiving, and privacy guidance.

## Shortcuts & Focus Mode Integration

Apple prevents third-party apps from unlocking other apps directly. EarnTime focuses on local tracking and gives you the tools to connect with Apple’s Shortcuts and Focus modes manually.

1. In EarnTime, export your stats (JSON or CSV) from the **Stats** tab.
2. Open the Shortcuts app and create a new automation.
3. Add actions similar to:
   - **Get File** → choose the exported stats file from Files/iCloud.
   - **Get Dictionary from** (JSON) or **Filter Files** (CSV) to read your current balance.
   - **If** balance is above your target threshold → **Set Focus** (turn on your “Deep Work” or “Allowed Apps” mode). Otherwise, show an alert reminding you to earn more credits.
   - Optionally end with **Open App** (the distracting app) so it launches only after the Focus mode is active.
4. Because Apple requires user involvement, choose **Ask to Run** or **Run Immediately** for personal automations as permitted.

Documented instructions also live inside the app under Settings → “Shortcuts & Screen Time.”

## Privacy Promise

- All data is stored locally using SwiftData.
- No network calls, analytics SDKs, or remote services.
- Delete the app to wipe your history instantly.

## License

This project is released under the [MIT License](./LICENSE). Contributions are welcome via pull requests.
