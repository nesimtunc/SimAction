import Foundation

class DeviceDiscoveryClient {
    static let shared = DeviceDiscoveryClient()
    
    // MVP: Implement read-only + safe actions: Discover connected devices
    // Since we cannot easily use standard `xcrun simctl` for physical devices generally,
    // and `xcrun xctrace list devices` is standard for listing connected devices.
    
    func listPhysicalDevices() async throws -> [DeviceItem] {
        // We will try running `xcrun xctrace list devices`
        // Output format is usually:
        // == Devices ==
        // iPhone 15 (17.5) (00008120-001234567890)
        // ...
        
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = ["xctrace", "list", "devices"]
        task.standardOutput = pipe
        
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            // Soft fail for MVP, return empty if tools missing or error
            return []
        }
        
        let output = String(data: data, encoding: .utf8) ?? ""
        return parseXctraceOutput(output)
    }
    
    func parseXctraceOutput(_ output: String) -> [DeviceItem] {
        var items: [DeviceItem] = []
        let lines = output.components(separatedBy: .newlines)
        
        // Simple parser
        // Look for lines like: "iPhone 15 (17.5) (00008120-001234567890)"
        // Regex: (.*) \((.*)\) \(([A-F0-9-]{10,})\)
        
        // Note: xctrace output also contains Simulators usually.
        // We need to distinguish them or trust the user to filter?
        // Actually, xctrace lists ALL devices.
        // But `simctl` gives us simulators with rich info.
        // We might need to coordinate or dedup, OR we just assume `xctrace` is for physical devices
        // and filter out simulators by checking if UDID exists in simctl list?
        // OR: Simulators usually have UUIDs (36 chars), Physical have 40 chars or 24 chars (with dash).
        // Let's rely on UDID length or format.
        // Simulator UUID: 8-4-4-4-12 (standard UUID)
        
        let regex = try? NSRegularExpression(pattern: "^(.*) \\((.*)\\) \\(([A-F0-9-]{10,})\\)$")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if trimmed.hasPrefix("==") { continue }
            
            if let match = regex?.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
                let nameRange = Range(match.range(at: 1), in: trimmed)!
                let osRange = Range(match.range(at: 2), in: trimmed)!
                let udidRange = Range(match.range(at: 3), in: trimmed)!
                
                let name = String(trimmed[nameRange])
                let osVersion = String(trimmed[osRange])
                let udid = String(trimmed[udidRange])
                
                // Heuristic: Simulator UUIDs are 36 chars. Physical usually different or we can assume if it's not a standard UUID structure.
                // Standard UUID: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX (8-4-4-4-12) = 36 chars
                // Physical UDID (new): 0000XXXX-XXXXXXXXXXXXXXXX (8-16) = 25 chars with dash?
                // Old UDID: 40 chars hex.
                
                let isSimulator = (udid.count == 36 && udid.split(separator: "-").count == 5)
                
                if !isSimulator {
                     let item = DeviceItem(
                        id: udid,
                        name: name,
                        osVersion: osVersion,
                        state: .connected, // Assume connected if listed by xctrace
                        source: .physicalDevice
                    )
                    items.append(item)
                }
            }
        }
        
        return items
    }
}
