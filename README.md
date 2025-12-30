# SimAction

SimAction is a macOS SwiftUI app that provides a unified control panel for:
- **iOS Simulators** (via `xcrun simctl`)
- **Physical iOS Devices** (via Xcode device services)

It aims to solve common developer pain points by providing specific actions like "Open URL", "Clipboard Control" (Simulators), and "Screenshot" in a native Mac app.

## Features

- **Device Discovery**: Lists all booted and shutdown simulators, plus connected physical devices.
- **Filtering**: View All, Simulators only, or Physical Devices only.
- **Actions**:
  - **Open URL**: Open deep links or websites on multiple devices simultaneously.
  - **Clipboard**: Read/Write clipboard for Simulators (Device ↔ Mac).
  - **Screenshot**: One-click screenshot saved to your disk.
- **Persistence**: Remembers up to 10 recent URLs and your last clipboard text.

## Requirements

- macOS 14.0+
- Xcode installed (Command Line Tools required for `xcrun`)

## macOS App Sandbox

SimAction executes Apple developer tools such as `xcrun simctl` to interact with simulators. These tools cannot be executed from within a sandboxed macOS application. For SimAction to function correctly, the App Sandbox must be disabled.

### Steps to Disable App Sandbox
1. Open the project in Xcode.
2. Select the `SimAction.entitlements` file in the project navigator.
3. Change the **App Sandbox** property to **NO**.

### Rationale
SimAction is a developer utility that relies on official Apple tooling to provide its core functionality. Requiring the App Sandbox to be disabled is a common and expected setup for developer tools that interact with system-level services or other developer utilities. The application does not require elevated privileges beyond the ability to execute these standard developer commands.

## Build & Run

1. Open `SimAction.xcodeproj` in Xcode.
2. Select the `SimAction` scheme.
3. Build and Run (Cmd+R).
4. The app will ask for permission to control "System Events" or access disk if needed (though mostly it runs `xcrun` subprocesses).

## Architecture

- **MVVM**:
  - `DeviceListViewModel`: Central state manager.
  - `SimctlClient`: Wrapper for `simctl` commands.
  - `DeviceDiscoveryClient`: Wrapper for physical device discovery.
- **SwiftUI**: Pure SwiftUI views split into Sidebar, ActionPanel, and LogPanel.
