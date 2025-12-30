import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = DeviceListViewModel()
    
    var body: some View {
        HSplitView {
            SidebarView(viewModel: viewModel)
                .frame(minWidth: 250, maxWidth: 400)
            
            VSplitView {
                ActionPanelView(viewModel: viewModel)
                    .frame(minWidth: 300, minHeight: 300)
                
                LogPanelView(viewModel: viewModel)
                    .frame(minHeight: 100)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await viewModel.refreshDevices()
        }
    }
}

#Preview {
    ContentView()
}
