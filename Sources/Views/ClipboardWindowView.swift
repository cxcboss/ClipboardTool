import SwiftUI

struct ClipboardWindowView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var hotkeyManager: HotkeyManager
    var onClose: (() -> Void)?
    var onPasteRequested: ((ClipboardItem) -> Void)?
    
    @State private var selectedItems: Set<UUID> = []
    @State private var isShiftPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            
            if clipboardManager.items.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(clipboardManager.items.enumerated()), id: \.element.id) { index, item in
                            ClipboardCardView(
                                item: item,
                                onSelect: { handleItemClick(item, isShiftPressed: NSEvent.modifierFlags.contains(.shift)) },
                                index: index + 1,
                                isSelected: selectedItems.contains(item.id)
                            )
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
            
            if !selectedItems.isEmpty {
                selectionToolbar
            }
        }
        .frame(width: 320, height: CGFloat(min(50 + clipboardManager.items.count * 52, 400) + (selectedItems.isEmpty ? 0 : 50)))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 15, y: 5)
        )
    }
    
    private var headerBar: some View {
        HStack {
            if selectedItems.isEmpty {
                Text("剪贴板历史")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            } else {
                Text("已选择 \(selectedItems.count) 项")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
                
                Button(action: { selectedItems.removeAll() }) {
                    Text("取消")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
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
    
    private var selectionToolbar: some View {
        HStack(spacing: 12) {
            Button(action: { pasteSelectedItems() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.doc.on.clipboard")
                        .font(.system(size: 12))
                    Text("一起输入")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: { deleteSelectedItems() }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                    Text("删除")
                        .font(.system(size: 12))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color(NSColor.controlBackgroundColor)
        )
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
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
    
    private func handleItemClick(_ item: ClipboardItem, isShiftPressed: Bool) {
        if isShiftPressed {
            if selectedItems.contains(item.id) {
                selectedItems.remove(item.id)
            } else {
                selectedItems.insert(item.id)
            }
        } else {
            if selectedItems.isEmpty {
                pasteItemDirectly(item)
            } else {
                if selectedItems.contains(item.id) && selectedItems.count == 1 {
                    selectedItems.removeAll()
                    pasteItemDirectly(item)
                } else {
                    selectedItems.removeAll()
                    selectedItems.insert(item.id)
                }
            }
        }
    }
    
    private func pasteItemDirectly(_ item: ClipboardItem) {
        fputs("[ClipboardWindowView] pasteItemDirectly called with item: \(item.content.prefix(50))\n", stderr)
        fflush(stderr)
        onPasteRequested?(item)
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        clipboardManager.deleteItem(item)
    }
    
    private func pasteSelectedItems() {
        let selectedClipboardItems = clipboardManager.items.filter { selectedItems.contains($0.id) }
        
        for item in selectedClipboardItems {
            pasteItemDirectly(item)
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        selectedItems.removeAll()
    }
    
    private func deleteSelectedItems() {
        let selectedClipboardItems = clipboardManager.items.filter { selectedItems.contains($0.id) }
        
        for item in selectedClipboardItems {
            clipboardManager.deleteItem(item)
        }
        
        selectedItems.removeAll()
    }
}
