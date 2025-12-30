import SwiftUI

struct LogPanelView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            HStack {
                Text("Execution Log")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            List {
                ForEach(viewModel.logs, id: \.self) { log in
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .listStyle(.plain)
        }
        .frame(height: 150)
        .background(Color(NSColor.textBackgroundColor))
    }
}
