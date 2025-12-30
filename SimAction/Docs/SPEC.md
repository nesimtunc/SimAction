# SimAction — Project Spec (MVP)

> This document is the **single source of truth** for the SimAction MVP.
> It is meant for humans *and* AI agents working on the codebase.

---

## Purpose

SimAction is a macOS SwiftUI app that provides a **control panel for iOS Simulators**, built on top of Apple’s official tooling (`xcrun simctl`).

The app exists to solve common developer pain points such as unreliable clipboard sync, slow repetitive simulator actions, and lack of a unified UI for simulator automation.

---

## Scope (MVP)

### Included

* iOS **Simulators**
* iOS **Physical Devices** (via Xcode tooling)
* GUI-first macOS app (SwiftUI)
* Uses Apple official tooling (`xcrun simctl`, `xcrun xctrace`, `xcodebuild` where applicable)

### Excluded (for now)

* Android
* CI / Fastlane integration
* App Store / Play Store upload

---

## Core Features

### 1. Device Discovery

* Fetch simulator list via:

  ```
  xcrun simctl list devices -j
  ```
* Parse JSON into models
* Sort order:

  1. Booted simulators first
  2. Then alphabetically by name

Displayed fields:

* Name
* iOS runtime (e.g. iOS 17.5)
* State (Booted / Shutdown)
* UDID

---

## Device Segmentation (IMPORTANT)

### Left Panel — Top Tabs

Left panel contains a **top segmented tab control** with three tabs:

1. **All**
2. **Simulators**
3. **Devices**

### Tab Behavior

#### All

* Shows **Simulators + Physical Devices**
* Grouped by section headers:

  * Simulators
  * Devices

#### Simulators

* Shows **only simulators**
* Backed by `xcrun simctl`

#### Devices

* Shows **physical iOS devices connected to the Mac**
* Discovery via Xcode tooling (initially read-only + safe actions)

### Physical Device Capabilities (MVP-safe)

Supported initially:

* List connected devices (name, iOS version, UDID)
* Device state (connected / unavailable)
* Open URL / deep link (Safari)
* Take screenshot

Not supported yet:

* Clipboard control (restricted by iOS)
* App install / uninstall

### Data Model

```swift
enum DeviceSource {
    case simulator
    case physicalDevice
}

struct DeviceItem {
    let id: String
    let name: String
    let osVersion: String
    let state: DeviceState
    let source: DeviceSource
}
```

Filtering logic is driven by the selected tab.

---

## Core Actions

### Open URL / Deep Link

Simulators:

```
xcrun simctl openurl <udid> <url>
```

Physical devices:

* Use Xcode device services / `xcrun xctrace` openurl where available

* Fallback: open via Safari using device pairing

* Input field for URL

* Button: **Open on Selected**

* Supports multi-selection (simulators + devices)

---

### Clipboard Control

Commands:

```
xcrun simctl pbcopy <udid> <text>
xcrun simctl pbpaste <udid>
```

* Multiline text editor
* Buttons:

  * Set clipboard on selected
  * Get clipboard from first selected

---

### Screenshot

Command:

```
xcrun simctl io <udid> screenshot <path>
```

* Default folder: `~/Pictures/SimAction/`
* Filename format:

  ```
  SimAction_<DeviceName>_<iOS>_<yyyyMMdd_HHmmss>.png
  ```

---

## Architecture

### App Structure

* SwiftUI
* MVVM

```
SimActionApp
 ├─ Views
 ├─ ViewModels
 ├─ Services
 │   └─ SimctlClient
 ├─ Models
```

### Command Execution

* Use `Process` to run shell commands
* Capture stdout / stderr
* Surface errors in UI log panel

---

## UX Notes

* Left panel: device list + top tabs
* Right panel: actions (URL, Clipboard, Screenshot)
* Bottom panel: execution log (last 20 actions)

---

## Persistence

Use `UserDefaults` for:

* recent URLs
* last clipboard text
* screenshot output folder

---

## Roadmap (Non-MVP)

* Physical devices (Xcode integration)
* Android (adb)
* Batch automation presets
* AI-driven flows
* Pro / paid tier

---

## License

MIT License
