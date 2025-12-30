import SwiftUI

struct ActionPanelView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    @State private var urlText: String = ""
    @AppStorage("screenshotPath") private var screenshotPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section: URL
                GroupBox(label: Label("Open URL", systemImage: "safari")) {
                    VStack {
                        TextField("https://...", text: $urlText)
                            .textFieldStyle(.roundedBorder)
                        
                        if !viewModel.recentURLs.isEmpty {
                            Menu("Recent URLs") {
                                ForEach(viewModel.recentURLs, id: \.self) { url in
                                    Button(url) {
                                        urlText = url
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            Spacer()
                            Button("Open on Selected") {
                                Task { await viewModel.openUrl(url: urlText) }
                            }
                            .disabled(viewModel.selectedDeviceIds.isEmpty)
                        }
                    }
                    .padding(8)
                }
                
                // Section: Clipboard
                GroupBox(label: Label("Clipboard", systemImage: "doc.on.clipboard")) {
                    VStack {
                        TextEditor(text: $viewModel.lastClipboardText)
                            .frame(height: 80)
                            .border(Color.gray.opacity(0.2))
                        
                        HStack {
                            Button("Get from Device") {
                                Task {
                                    if let content = await viewModel.getClipboard() {
                                        viewModel.lastClipboardText = content
                                    }
                                }
                            }
                            .disabled(viewModel.selectedDeviceIds.isEmpty) // Logic inside VM handles filtering for valid sim
                            
                            Spacer()
                            
                            Button("Set to Device") {
                                Task { await viewModel.setClipboard(text: viewModel.lastClipboardText) }
                            }
                            .disabled(viewModel.selectedDeviceIds.isEmpty)
                        }
                    }
                    .padding(8)
                }
                
                // Section: Screenshot
                GroupBox(label: Label("Screenshot", systemImage: "camera.viewfinder")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Save to:")
                            Text(screenshotPath)
                                .truncationMode(.middle)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Change...") {
                                selectFolder()
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Button("Take Screenshot") {
                                Task {
                                    await viewModel.takeScreenshot(outputFolder: URL(fileURLWithPath: screenshotPath))
                                }
                            }
                            .disabled(viewModel.selectedDeviceIds.isEmpty)
                        }
                    }
                    .padding(8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            screenshotPath = panel.url?.path ?? screenshotPath
        }
    }
}
