import Foundation
import SwiftUI
import Combine

enum DeviceTab: String, CaseIterable, Identifiable {
    case all = "All"
    case simulators = "Simulators"
    case devices = "Devices"
    
    var id: String { self.rawValue }
}

@MainActor
class DeviceListViewModel: ObservableObject {
    @Published var devices: [DeviceItem] = []
    @Published var selectedTab: DeviceTab = .all
    @Published var selectedDeviceIds: Set<String> = []
    @Published var logs: [String] = []
    
    // Persistence
    @Published var recentURLs: [String] = []
    @Published var lastClipboardText: String = "" {
        didSet {
            UserDefaults.standard.set(lastClipboardText, forKey: "lastClipboardText")
        }
    }
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let simctl = SimctlClient.shared
    private let discovery = DeviceDiscoveryClient.shared
    
    // Cache
    private var allFetchedDevices: [DeviceItem] = []
    
    init() {
        // Load persistence
        self.recentURLs = UserDefaults.standard.stringArray(forKey: "recentURLs") ?? []
        self.lastClipboardText = UserDefaults.standard.string(forKey: "lastClipboardText") ?? ""
        
        Task {
            await refreshDevices()
        }
    }
    
    func refreshDevices() async {
        isLoading = true
        errorMessage = nil
        allFetchedDevices = []
        
        do {
            async let sims = simctl.listDevices()
            async let phys = discovery.listPhysicalDevices()
            
            let (simulators, physicalDevices) = try await (sims, phys)
            
            allFetchedDevices = physicalDevices + simulators // Physical first or arbitrary, sorting handles it
            
            filterDevices()
            appendLog("Refreshed devices. Found \(allFetchedDevices.count) total.")
        } catch {
            errorMessage = "Failed to load devices: \(error.localizedDescription)"
            appendLog("Error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func filterDevices() {
        let sorted = allFetchedDevices.sorted { (lhs, rhs) -> Bool in
            // Booted first
            if lhs.isBooted && !rhs.isBooted { return true }
            if !lhs.isBooted && rhs.isBooted { return false }
            // Then Name
            return lhs.name < rhs.name
        }
        
        switch selectedTab {
        case .all:
            devices = sorted
        case .simulators:
            devices = sorted.filter { $0.source == .simulator }
        case .devices:
            devices = sorted.filter { $0.source == .physicalDevice }
        }
    }
    
    func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(timestamp)] \(message)")
        if logs.count > 20 {
            logs.removeFirst()
        }
    }
    
    // MARK: - Actions
    
    func openUrl(url: String) async {
        guard let validUrl = URL(string: url), validUrl.scheme != nil else {
             appendLog("Invalid URL: \(url)")
             return
        }
        
        // Add to recent
        addToRecentURLs(url)
        
        for device in getSelectedDevices() {
            appendLog("Opening URL on \(device.name)...")
            do {
                if device.source == .simulator {
                    try await simctl.openUrl(udid: device.id, url: url)
                } else {
                    // Physical fallback or implementation
                     appendLog("URL opening on physical device not fully implemented in MVP (Requires Xcode services).")
                }
                appendLog("Success: Opened URL on \(device.name)")
            } catch {
                appendLog("Failed to open URL on \(device.name): \(error.localizedDescription)")
            }
        }
    }
    
    func setClipboard(text: String) async {
         for device in getSelectedDevices() {
             guard device.source == .simulator else {
                 appendLog("Clipboard not supported on physical device: \(device.name)")
                 continue
             }
             
             do {
                 try await simctl.setClipboard(udid: device.id, text: text)
                 appendLog("Set clipboard on \(device.name)")
             } catch {
                 appendLog("Failed clipboard on \(device.name): \(error.localizedDescription)")
             }
         }
    }
    
    func getClipboard() async -> String? {
        guard let device = getSelectedDevices().firstItem(where: { $0.source == .simulator }) else {
            appendLog("No simulator selected for Get Clipboard")
            return nil
        }
        
        do {
            let content = try await simctl.getClipboard(udid: device.id)
            appendLog("Got clipboard from \(device.name)")
            return content
        } catch {
            appendLog("Failed get clipboard: \(error.localizedDescription)")
            return nil
        }
    }
    
    func takeScreenshot(outputFolder: URL) async {
        for device in getSelectedDevices() {
             let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
                .replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: " ", with: "_")
            
            let filename = "SimAction_\(device.name)_\(device.osVersion)_\(timestamp).png"
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: ",", with: "")
            
            let path = outputFolder.appendingPathComponent(filename).path
            
            do {
                if device.source == .simulator {
                    try await simctl.takeScreenshot(udid: device.id, path: path)
                    appendLog("Screenshot saved: \(filename)")
                } else {
                     appendLog("Screenshot on physical not impl in MVP")
                }
            } catch {
                 appendLog("Failed screenshot \(device.name): \(error.localizedDescription)")
            }
        }
    }
    
    private func getSelectedDevices() -> [DeviceItem] {
        return devices.filter { selectedDeviceIds.contains($0.id) }
    }
    
    private func addToRecentURLs(_ url: String) {
        var recents = recentURLs
        if let index = recents.firstIndex(of: url) {
            recents.remove(at: index)
        }
        recents.insert(url, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        recentURLs = recents
        UserDefaults.standard.set(recentURLs, forKey: "recentURLs")
    }
}

extension Array {
    func firstItem(where predicate: (Element) -> Bool) -> Element? {
        return self.first(where: predicate)
    }
}
