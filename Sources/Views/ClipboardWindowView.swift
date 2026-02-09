import SwiftUI

struct ClipboardWindowView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var hotkeyManager: HotkeyManager
    var onClose: (() -> Void)?
    var onPasteRequested: ((ClipboardItem) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            
            if clipboardManager.items.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(clipboardManager.items) { item in
                            ClipboardCardView(item: item) {
                                pasteItemDirectly(item)
                            }
                            .contextMenu {
                                Button(action: { pasteItemDirectly(item) }) {
                                    Label("填入输入框", systemImage: "arrow.right.doc.on.clipboard")
                                }
                                Button(role: .destructive, action: { deleteItem(item) }) {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(width: 320, height: CGFloat(min(50 + clipboardManager.items.count * 52, 400)))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 15, y: 5)
        )
    }
    
    private var headerBar: some View {
        HStack {
            Text("剪贴板历史")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                onClose?()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .help("关闭")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(height: 40)
        )
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            
            Text("暂无剪贴板记录")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Text("复制文本后自动记录")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
    
    private func pasteItemDirectly(_ item: ClipboardItem) {
        fputs("[ClipboardWindowView] pasteItemDirectly called with item: \(item.content.prefix(50))\n", stderr)
        fflush(stderr)
        onPasteRequested?(item)
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        clipboardManager.deleteItem(item)
    }
}
