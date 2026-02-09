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
        loadSettings()
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: "hotkey_settings"),
              let loadedSettings = try? JSONDecoder().decode(HotkeySettings.self, from: data) else {
            settings = .defaultSettings
            return
        }
        settings = loadedSettings
    }
    
    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: "hotkey_settings")
    }
    
    func updateHotkey(_ config: HotkeySettings.HotkeyConfig, isFirst: Bool) {
        settings.hotkey1 = config
        saveSettings()
        restartListening()
    }
    
    private func startListening() {
        guard !isListening else { return }
        
        stopListening()
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            self.handleKeyEvent(event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            self.handleKeyEvent(event)
            return event
        }
        
        isListening = true
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
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard settings.hotkey1.isEnabled else { return }
        
        let keyCode = Int(event.keyCode)
        let hotkeyConfig = settings.hotkey1
        
        let hasControl = event.modifierFlags.contains(.control)
        let hasCommand = event.modifierFlags.contains(.command)
        let hasOption = event.modifierFlags.contains(.option)
        let hasShift = event.modifierFlags.contains(.shift)
        
        let targetControl = (hotkeyConfig.modifierFlags & 524288) != 0
        let targetCommand = (hotkeyConfig.modifierFlags & 65536) != 0
        let targetOption = (hotkeyConfig.modifierFlags & 262144) != 0
        let targetShift = (hotkeyConfig.modifierFlags & 1048576) != 0
        
        let modifiersMatch = hasControl == targetControl && 
                           hasCommand == targetCommand && 
                           hasOption == targetOption && 
                           hasShift == targetShift
        
        let keyCodeMatch = keyCode == hotkeyConfig.keyCode
        
        let matches = modifiersMatch && keyCodeMatch
        
        if matches {
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
