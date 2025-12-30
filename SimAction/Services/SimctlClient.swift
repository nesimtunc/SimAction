import Foundation

struct SimctlListResult: Codable {
    let devices: [String: [SimctlDevice]]
}

struct SimctlDevice: Codable {
    let state: String
    let isAvailable: Bool
    let name: String
    let udid: String
    let deviceTypeIdentifier: String? // Optional
}

class SimctlClient {
    static let shared = SimctlClient()
    
    // Command execution helper
    private func runCommand(_ arguments: [String]) async throws -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = ["simctl"] + arguments
        task.standardOutput = pipe
        task.standardError = pipe // Capture stderr as well for debugging
        
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SimctlClient", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func listDevices() async throws -> [DeviceItem] {
        let jsonString = try await runCommand(["list", "devices", "-j"])
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "SimctlClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert output to data"])
        }
        
        let result = try JSONDecoder().decode(SimctlListResult.self, from: data)
        
        var items: [DeviceItem] = []
        
        for (runtimeKey, devices) in result.devices {
            // runtimeKey example: "com.apple.CoreSimulator.SimRuntime.iOS-17-5"
            // We want to extract "iOS 17.5"
            let osVersion = parseRuntimeName(runtimeKey)
            
            for device in devices {
                // Determine source: We are in SimctlClient, so it's simulator.
                // Spec say: "Included: iOS Simulators".
                // We might filter out unavailable devices or other platforms (tvOS/watchOS) if needed,
                // but spec simply says "Fetch simulator list".
                // It is good practice to filter for iOS if possible, but let's stick to what simctl returns for now.
                // The runtime key usually indicates the OS.
                
                let item = DeviceItem(
                    id: device.udid,
                    name: device.name,
                    osVersion: osVersion,
                    state: DeviceState.from(simctlState: device.state),
                    source: .simulator
                )
                items.append(item)
            }
        }
        
        return items
    }
    
    private func parseRuntimeName(_ raw: String) -> String {
        // "com.apple.CoreSimulator.SimRuntime.iOS-17-0" -> "iOS 17.0"
        let components = raw.components(separatedBy: ".")
        guard let last = components.last else { return raw }
        
        // "iOS-17-0" -> "iOS 17.0"
        return last.replacingOccurrences(of: "-", with: " ")
    }
    
    func openUrl(udid: String, url: String) async throws {
        _ = try await runCommand(["openurl", udid, url])
    }
    
    func setClipboard(udid: String, text: String) async throws {
        // simctl pbcopy <udid> <text>
        // Use stdin for text to avoid shell escaping issues
        let task = Process()
        let pipeOut = Pipe()
         let pipeIn = Pipe()
        
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = ["simctl", "pbcopy", udid]
        task.standardOutput = pipeOut
        task.standardError = pipeOut
        task.standardInput = pipeIn
        
        try task.run()
        
        if let data = text.data(using: .utf8) {
            try pipeIn.fileHandleForWriting.write(contentsOf: data)
            try pipeIn.fileHandleForWriting.close()
        }
        
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
             let data = pipeOut.fileHandleForReading.readDataToEndOfFile()
             let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
             throw NSError(domain: "SimctlClient", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    func getClipboard(udid: String) async throws -> String {
        return try await runCommand(["pbpaste", udid])
    }
    
    func takeScreenshot(udid: String, path: String) async throws {
        _ = try await runCommand(["io", udid, "screenshot", path])
    }
}
