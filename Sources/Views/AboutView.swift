import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png"),
               let image = NSImage(contentsOfFile: iconPath) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
            } else {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
            }
            
            Text("剪贴板工具")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("版本 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("简单、高效的剪贴板历史管理工具")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Text("© 2024 ClipboardTool")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 350, height: 280)
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
