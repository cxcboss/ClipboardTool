import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var hotkeyManager: HotkeyManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isRecording = false
    @State private var recordedKeys: [String] = []
    @State private var recordedFlags: Int = 0
    @State private var isAccessibilityEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Text("⚙️ 剪贴板工具设置")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                permissionSection
                
                Divider()
                    .padding(.horizontal, 30)
                
                VStack(spacing: 16) {
                    Text("⌨️ 快捷键设置")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    hotkeyRow(
                        title: "打开剪贴板",
                        config: hotkeyManager.settings.hotkey1,
                        isRecording: isRecording,
                        currentKeys: isRecording ? recordedKeys : nil,
                        onEdit: startRecording,
                        onCancel: cancelRecording
                    )
                }
                .padding(.horizontal, 30)
                
                if isRecording {
                    VStack(spacing: 8) {
                        Text("请按下快捷键 (例如: Control + V)")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        if !recordedKeys.isEmpty {
                            Text("已按下: \(recordedKeys.joined(separator: " + "))")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        Text("再按一个键完成设置，按 Esc 取消")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                }
                
                Divider()
                    .padding(.horizontal, 30)
                
                VStack(spacing: 12) {
                    Text("💡 使用提示")
                        .font(.headline)
                    
                    Text("• 点击菜单栏图标打开剪贴板窗口")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 点击卡片直接粘贴到当前输入位置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 右键卡片可删除")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: { restoreDefaults() }) {
                    Label("恢复默认 (Control + V)", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                
                Button(action: { dismiss() }) {
                    Label("关闭", systemImage: "xmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 30)
        }
        .frame(width: 450, height: 460)
        .onAppear {
            setupKeyEvents()
            checkAccessibilityPermission()
        }
        .onDisappear {
            cancelRecording()
        }
    }
    
    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        isAccessibilityEnabled = trusted
        fputs("[SettingsView] Accessibility permission: \(trusted ? "enabled" : "disabled")\n", stderr)
        fflush(stderr)
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Security_Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private var permissionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isAccessibilityEnabled ? "checkmark.shield.fill" : "shield.slash")
                    .font(.title2)
                    .foregroundColor(isAccessibilityEnabled ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("辅助功能权限")
                        .font(.headline)
                    
                    Text(isAccessibilityEnabled ? "已授权，所有功能可用" : "需要辅助功能权限才能检测快捷键和模拟键盘输入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(isAccessibilityEnabled ? "已授权" : "未授权")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isAccessibilityEnabled ? Color.green : Color.orange)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            if !isAccessibilityEnabled {
                Button(action: {
                    openAccessibilitySettings()
                }) {
                    Label("打开系统设置授权", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func hotkeyRow(
        title: String,
        config: HotkeySettings.HotkeyConfig,
        isRecording: Bool,
        currentKeys: [String]?,
        onEdit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .frame(width: 100, alignment: .leading)
                .font(.body)
            
            Spacer()
            
            if isRecording, let keys = currentKeys, !keys.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(keys.joined(separator: " + "))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.15))
                )
                
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if isRecording {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text(config.displayName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                
                Button("修改") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func setupKeyEvents() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isRecording else { return event }
            
            let keyCode = Int(event.keyCode)
            let flags = self.modifierFlagsValue(from: event.modifierFlags)
            
            if keyCode == 53 {
                self.cancelRecording()
                return nil
            }
            
            let keyName = self.keyName(for: keyCode)
            
            if self.recordedKeys.count < 2 {
                if self.recordedKeys.isEmpty {
                    self.recordedKeys.append(keyName)
                    self.recordedFlags = flags
                } else {
                    self.recordedKeys.append(keyName)
                    self.recordedFlags = self.recordedFlags | flags
                }
            }
            
            if self.recordedKeys.count == 2 {
                let newConfig = HotkeySettings.HotkeyConfig(
                    keyCode: keyCode,
                    modifierFlags: self.recordedFlags,
                    isEnabled: true
                )
                
                self.hotkeyManager.updateHotkey(newConfig, isFirst: true)
                
                self.isRecording = false
                self.recordedKeys = []
            }
            
            return nil
        }
    }
    
    private func modifierFlagsValue(from flags: NSEvent.ModifierFlags) -> Int {
        var value = 0
        if flags.contains(.command) { value += 65536 }
        if flags.contains(.option) { value += 262144 }
        if flags.contains(.shift) { value += 1048576 }
        if flags.contains(.control) { value += 524288 }
        if flags.contains(.capsLock) { value += 4194304 }
        return value
    }
    
    private func keyName(for keyCode: Int) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "Enter"
        case 29: return "8"
        case 30: return "0"
        case 31: return "]"
        case 33: return ";"
        case 34: return "K"
        case 35: return "L"
        case 37: return ","
        case 38: return "/"
        case 39: return "N"
        case 40: return "M"
        case 41: return "."
        case 42: return "Tab"
        case 43: return "Space"
        case 44: return "\\"
        case 45: return "="
        case 46: return "-"
        case 47: return "["
        case 48: return "'"
        case 49: return "`"
        case 50: return ","
        case 51: return "."
        case 53: return "Esc"
        case 55: return "Cmd"
        case 56: return "Shift"
        case 57: return "Caps"
        case 58: return "Opt"
        case 59: return "Ctrl"
        case 60: return "RShift"
        case 61: return "ROpt"
        case 62: return "RCtrl"
        case 64: return "F4"
        case 65: return "F5"
        case 66: return "F6"
        case 67: return "F7"
        case 71: return "F8"
        case 72: return "F9"
        case 73: return "F10"
        case 75: return "F11"
        case 76: return "F12"
        default: return "Key\(keyCode)"
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordedKeys = []
        recordedFlags = 0
    }
    
    private func cancelRecording() {
        isRecording = false
        recordedKeys = []
    }
    
    private func restoreDefaults() {
        hotkeyManager.updateHotkey(.default1, isFirst: true)
    }
}
