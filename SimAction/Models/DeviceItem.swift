import Foundation

enum DeviceSource: String, Codable {
    case simulator
    case physicalDevice
}

enum DeviceState: String, Codable {
    case booted = "Booted"
    case shutdown = "Shutdown"
    case connected = "Connected"
    case unavailable = "Unavailable"
    
    // Helper to map simctl state string to enum
    static func from(simctlState: String) -> DeviceState {
        switch simctlState.lowercased() {
        case "booted": return .booted
        case "shutdown": return .shutdown
        default: return .unavailable
        }
    }
}

struct DeviceItem: Identifiable, Hashable, Codable {
    let id: String // UDID
    let name: String
    let osVersion: String
    let state: DeviceState
    let source: DeviceSource
    
    var isBooted: Bool {
        return state == .booted
    }
}
