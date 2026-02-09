import Foundation
import AppKit

final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    @Published var settings: HotkeySettings = .defaultSettings
    @Published var isWindowVisible = false
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isListening = false
    
    private init() {
        fputs("[HotkeyManager] Initializing...\n", stderr)
        fflush(stderr)
        loadSettings()
        startListening()
        
        let msg = String(format: "[HotkeyManager] Initialized with hotkey: keyCode=%d, modifiers=%d, enabled=%d\n",
                         settings.hotkey1.keyCode, settings.hotkey1.modifierFlags, settings.hotkey1.isEnabled ? 1 : 0)
        fputs(msg, stderr)
        fflush(stderr)
    }
    
    deinit {
        stopListening()
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: "hotkey_settings"),
              let loadedSettings = try? JSONDecoder().decode(HotkeySettings.self, from: data) else {
            settings = .defaultSettings
            fputs("[HotkeyManager] Using default hotkey settings\n", stderr)
            fflush(stderr)
            return
        }
        settings = loadedSettings
        fputs("[HotkeyManager] Loaded settings from UserDefaults\n", stderr)
        fflush(stderr)
    }
    
    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: "hotkey_settings")
    }
    
    func updateHotkey(_ config: HotkeySettings.HotkeyConfig, isFirst: Bool) {
        settings.hotkey1 = config
        saveSettings()
        let msg = String(format: "[HotkeyManager] Updated hotkey: keyCode=%d, modifiers=%d\n", config.keyCode, config.modifierFlags)
        fputs(msg, stderr)
        fflush(stderr)
        
        restartListening()
    }
    
    private func startListening() {
        guard !isListening else { return }
        
        fputs("[HotkeyManager] Starting event monitoring...\n", stderr)
        fflush(stderr)
        
        stopListening()
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let msg = String(format: "[HotkeyManager] Global key detected: keyCode=%d, flags=%d\n", event.keyCode, event.modifierFlags.rawValue)
            fputs(msg, stderr)
            fflush(stderr)
            self.handleKeyEvent(event)
        }
        fputs("[HotkeyManager] Global monitor created\n", stderr)
        fflush(stderr)
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let msg = String(format: "[HotkeyManager] Local key detected: keyCode=%d, flags=%d\n", event.keyCode, event.modifierFlags.rawValue)
            fputs(msg, stderr)
            fflush(stderr)
            self.handleKeyEvent(event)
            return event
        }
        fputs("[HotkeyManager] Local monitor created\n", stderr)
        fflush(stderr)
        
        isListening = true
        fputs("[HotkeyManager] Event monitoring started successfully\n", stderr)
        fflush(stderr)
    }
    
    private func stopListening() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isListening = false
        fputs("[HotkeyManager] Event monitoring stopped\n", stderr)
        fflush(stderr)
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = Int(event.keyCode)
        var flags = 0
        if event.modifierFlags.contains(.command) { flags += 65536 }
        if event.modifierFlags.contains(.option) { flags += 262144 }
        if event.modifierFlags.contains(.shift) { flags += 1048576 }
        if event.modifierFlags.contains(.control) { flags += 524288 }
        
        guard settings.hotkey1.isEnabled else {
            fputs("[HotkeyManager] Hotkey is disabled\n", stderr)
            fflush(stderr)
            return
        }
        
        let hotkeyConfig = settings.hotkey1
        let matches = keyCode == hotkeyConfig.keyCode && flags == hotkeyConfig.modifierFlags
        
        let msg = String(format: "[HotkeyManager] Key check: input(keyCode=%d, flags=%d) vs hotkey(keyCode=%d, flags=%d), match=%@\n",
                         keyCode, flags, hotkeyConfig.keyCode, hotkeyConfig.modifierFlags, matches ? "YES" : "NO")
        fputs(msg, stderr)
        fflush(stderr)
        
        if matches {
            fputs("[HotkeyManager] Hotkey matched! Toggling window...\n", stderr)
            fflush(stderr)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isWindowVisible.toggle()
                if self.isWindowVisible {
                    NotificationCenter.default.post(name: .showClipboardWindow, object: nil)
                } else {
                    NotificationCenter.default.post(name: .hideClipboardWindow, object: nil)
                }
            }
        }
    }
    
    private func restartListening() {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startListening()
        }
    }
    
    func toggleWindow() {
        isWindowVisible.toggle()
        if isWindowVisible {
            NotificationCenter.default.post(name: .showClipboardWindow, object: nil)
        } else {
            NotificationCenter.default.post(name: .hideClipboardWindow, object: nil)
        }
    }
    
    func hideWindow() {
        isWindowVisible = false
        NotificationCenter.default.post(name: .hideClipboardWindow, object: nil)
    }
}

extension Notification.Name {
    static let showClipboardWindow = Notification.Name("showClipboardWindow")
    static let hideClipboardWindow = Notification.Name("hideClipboardWindow")
}
