import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(DeviceTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: viewModel.selectedTab) {
                viewModel.filterDevices()
            }
            
            List(selection: $viewModel.selectedDeviceIds) {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.devices.isEmpty {
                     Text("No devices found")
                        .foregroundColor(.secondary)
                } else {
                     // Grouping logic if needed. For now flat list or grouped by source?
                     // Spec says: "All tab shows both, grouped by section headers"
                     // Since List selection with multiple sections can be tricky in SwiftUI in some versions,
                     // let's try strict sectioning if "All" is selected.
                     
                     if viewModel.selectedTab == .all {
                         Section("Simulators") {
                             ForEach(viewModel.devices.filter { $0.source == .simulator }) { device in
                                 DeviceRow(device: device)
                             }
                         }
                         Section("Devices") {
                             ForEach(viewModel.devices.filter { $0.source == .physicalDevice }) { device in
                                 DeviceRow(device: device)
                             }
                         }
                     } else {
                         ForEach(viewModel.devices) { device in
                             DeviceRow(device: device)
                         }
                     }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 250)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task { await viewModel.refreshDevices() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct DeviceRow: View {
    let device: DeviceItem
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text("\(device.osVersion) • \(device.state.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if device.state == .booted || device.state == .connected {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .tag(device.id) // Important for selection
    }
    
    var iconName: String {
        switch device.source {
        case .simulator: return "iphone.gen3" // generic
        case .physicalDevice: return "iphone"
        }
    }
}
