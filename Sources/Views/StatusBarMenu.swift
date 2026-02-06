import SwiftUI

struct StatusBarMenu: View {
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var clipboardManager: ClipboardManager
    
    @State private var showingSettings = false
    @State private var showingWindow = false
    
    var body: some View {
        VStack(spacing: 0) {
            if hotkeyManager.isWindowVisible {
                ClipboardWindowView(
                    clipboardManager: clipboardManager,
                    hotkeyManager: hotkeyManager
                )
                .frame(height: CGFloat(min(40 + clipboardManager.items.count * 80, 500)))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                )
                .padding(10)
            }
            
            Divider()
                .opacity(showingWindow ? 1 : 0)
        }
    }
}
